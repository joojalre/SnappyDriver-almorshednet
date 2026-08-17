[CmdletBinding()]
param(
    [string] $SdioDir    = '',
    [string] $ScriptFile = 'scripts\update-no-hid.txt',
    [switch] $QuarantineMisc,
    [switch] $DryRun,
    [int]    $TimeoutSec = 900
)

$SdioDir = if ([string]::IsNullOrWhiteSpace($SdioDir)) { $env:SDIO_DIR } else { $SdioDir }
if ([string]::IsNullOrWhiteSpace($SdioDir)) {
    throw 'SdioDir is required. Set $env:SDIO_DIR or pass -SdioDir path.'
}

$ErrorActionPreference = 'Stop'
function Say([string]$m, [string]$c = 'Gray') { Write-Host $m -ForegroundColor $c }

# ---------- 0) Environment ----------
if (-not (Test-Path -LiteralPath $SdioDir)) { throw "SDIO folder not found: $SdioDir" }
$exe = Get-ChildItem -LiteralPath $SdioDir -Filter 'SDIO_x64_R*.exe' |
       Sort-Object Name -Descending | Select-Object -First 1
if (-not $exe) { throw "SDIO_x64_R*.exe not found in $SdioDir" }

$logsDir    = Join-Path $SdioDir 'logs'
$driversDir = Join-Path $SdioDir 'drivers'
$quarantine = Join-Path $SdioDir 'drivers_disabled'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Say "SDIO   : $($exe.Name)" 'Cyan'
Say "Admin  : $isAdmin" $(if($isAdmin){'Cyan'} else {'Yellow'})
if (-not $isAdmin -and -not $DryRun) {
    Say 'WARNING: not elevated. Install steps may fail. Re-run as Administrator.' 'Yellow'
}

# ---------- 1) baseline state ----------
$before = @(Get-CimInstance Win32_PnPEntity -EA SilentlyContinue |
            Where-Object { $_.ConfigManagerErrorCode -ne 0 })
Say "Problem devices BEFORE: $($before.Count)" 'Cyan'

# ---------- 2) DryRun mode ----------
$runScript = $ScriptFile
if ($DryRun) {
    $probe = Join-Path $SdioDir 'scripts\_dryrun.txt'
    $scriptText = @(
        'verbose 384',
        'logging on',
        'enableinstall off',
        'keeptempfiles off',
        'init',
        'select missing better',
        'logging off',
        'end'
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $probe -Encoding ASCII -Value $scriptText
    $runScript = 'scripts\_dryrun.txt'
    Say 'DryRun: install disabled, selection only.' 'Yellow'
}

# ---------- 3) optional quarantine ----------
$moved = @()
if ($QuarantineMisc) {
    New-Item -ItemType Directory -Force -Path $quarantine | Out-Null
    Get-ChildItem -LiteralPath $driversDir -Filter 'DP_Misc_*.7z' -EA SilentlyContinue |
        ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination $quarantine -Force
            $moved += $_.Name
            Say "Quarantined: $($_.Name)" 'Yellow'
        }
}

# ---------- 4) run once ----------
try {
    Say 'Running SDIO (single pass, no retry)...' 'Cyan'
    $p = Start-Process -FilePath $exe.FullName `
                       -ArgumentList '-script', $runScript `
                       -WorkingDirectory $SdioDir `
                       -PassThru
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        Say "TIMEOUT after ${TimeoutSec}s - killing SDIO." 'Red'
        $p | Stop-Process -Force
        throw 'SDIO timed out.'
    }
    Say "Process exit code: $($p.ExitCode)  (informational only)" 'DarkGray'
}
finally {
    foreach ($m in $moved) {
        Move-Item -LiteralPath (Join-Path $quarantine $m) -Destination $driversDir -Force
        Say "Restored: $m" 'DarkGray'
    }
}

# ---------- 5) analyze latest log ----------
$log = Get-ChildItem -LiteralPath $logsDir -Filter '*_log.txt' -EA SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $log) { throw 'No log produced - SDIO never ran. Check working directory.' }
$raw = Get-Content -LiteralPath $log.FullName -Raw
Say "`nLog: $($log.Name)" 'Cyan'

Say "`n--- Relevant lines ---" 'Cyan'
Select-String -LiteralPath $log.FullName `
    -Pattern 'drivers selected|drivers installed|drivers failed|Ret \d+|Install\d\d|FINISH' |
    Select-Object -Last 30 | ForEach-Object { $_.Line }

# ---------- 6) device-based verdict ----------
Say "`n--- Verdict (device-based, not exit-code-based) ---" 'Cyan'
$after = @(Get-CimInstance Win32_PnPEntity -EA SilentlyContinue |
           Where-Object { $_.ConfigManagerErrorCode -ne 0 })
Say "Problem devices AFTER : $($after.Count)" $(if($after.Count -eq 0){'Green'} else {'Red'})
if ($after.Count -gt 0) {
    $after | Select-Object ConfigManagerErrorCode, PNPClass, Name | Format-Table -Auto
}

if ($raw -match 'Ret 1' -or $raw -match 'LOGITECH_RAW_PDO') {
    $store = (pnputil /enum-drivers 2>$null | Out-String)
    $staged = ($store -match 'jfunkraw\.inf')
    Say 'Installer returned Ret 1 - verifying against DriverStore...' 'Yellow'
    Say "  jfunkraw.inf staged in DriverStore: $staged" $(if($staged){'Green'} else {'Yellow'})
    if ($staged) { Say '  => Ret 1 was a false failure. Do NOT retry.' 'Green' }
}

if ($raw -match 'unicode2ansi' -or $raw -match 'sect not found') {
    Say 'NOTE: unicode2ansi / sect not found is usually an encoding warning.' 'DarkYellow'
    Say '      It may not mean a real driver failure. Verify with the device count above.' 'DarkYellow'
}

# ---------- 7) hard stop gate ----------
$nothingToDo = ($raw -match '0 drivers selected') -or ($raw -match '0 drivers installed,\s*0 drivers failed')
Say ''
if ($nothingToDo -and $after.Count -eq 0) {
    Say 'DONE: everything up to date, zero problem devices. STOP - do not re-run.' 'Green'
} elseif ($nothingToDo) {
    Say 'SDIO has nothing to offer, but problem devices remain; SDIO is not the fix.' 'Yellow'
} else {
    Say 'Drivers were selected. Review the lines above, then run ONCE more if needed.' 'Yellow'
}

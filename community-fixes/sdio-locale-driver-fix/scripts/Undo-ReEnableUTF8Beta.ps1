[CmdletBinding()]
param(
    [string] $BackupFile = '',
    [switch] $RestoreDefaults
)

$ErrorActionPreference = 'Stop'
$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage'
$scriptDir = $PSScriptRoot
$log = Join-Path $scriptDir 'undo-locale-result.txt'
$messages = @()

function Write-Result($m) {
    $messages += $m
    Write-Host $m
}

try {
    if (-not $RestoreDefaults -and [string]::IsNullOrWhiteSpace($BackupFile)) {
        $candidate = Join-Path $scriptDir 'CodePage-BACKUP.reg'
        if (Test-Path -LiteralPath $candidate) { $BackupFile = $candidate }
    }

    if (-not [string]::IsNullOrWhiteSpace($BackupFile)) {
        if (-not (Test-Path -LiteralPath $BackupFile)) { throw "Backup not found: $BackupFile" }
        & reg.exe import $BackupFile /y | Out-Null
        Write-Result "RESTORE: Imported backup reg from $BackupFile"
    } else {
        # Safe fallback if no backup exists. Values are common defaults for non-UTF-8 beta mode.
        Set-ItemProperty $regPath -Name ACP -Value '65001'
        Set-ItemProperty $regPath -Name OEMCP -Value '437'
        Set-ItemProperty $regPath -Name MACCP -Value '10000'
        Write-Result "RESTORE: Applied standard fallback code page values (ACP=65001, OEMCP=437, MACCP=10000)"
    }

    $v = Get-ItemProperty $regPath | Select-Object ACP, OEMCP, MACCP
    Write-Result "CURRENT: ACP=$($v.ACP) OEMCP=$($v.OEMCP) MACCP=$($v.MACCP)"
    Write-Result "RESULT: DONE - reboot recommended for full process-wide effect."
}
catch {
    Write-Result "ERROR: $($_.Exception.Message)"
    exit 1
}

$messages | Set-Content -LiteralPath $log -Encoding UTF8

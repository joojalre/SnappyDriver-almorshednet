[CmdletBinding()]
param(
    [string] $SdioDir = $env:SDIO_DIR,
    [string] $SafeScriptFile = 'scripts\update-no-hid.txt',
    [string] $CommunityRepo = 'joojalre/SnappyDriver-almorshednet',
    [switch] $NoGui
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SdioDir)) {
    throw 'SdioDir is required. Set $env:SDIO_DIR or pass -SdioDir path.'
}
if (-not (Test-Path -LiteralPath $SdioDir)) {
    throw "SDIO folder not found: $SdioDir"
}

$scriptRoot = $PSScriptRoot
$runner = Join-Path $scriptRoot 'Run-SDIO-Safe.ps1'
if (-not (Test-Path -LiteralPath $runner)) {
    throw "Required runner not found: $runner"
}

function Append-LogLine {
    param(
        [string]$Line,
        [System.Windows.Forms.RichTextBox]$Box
    )
    if ($Box -eq $null) { return }
    $stamp = Get-Date -Format 'HH:mm:ss'
    $Box.AppendText("[$stamp] $Line`r`n")
    $Box.SelectionStart = $Box.TextLength
    $Box.ScrollToCaret()
}

function Get-SdioReleaseInfo {
    param([string]$Repo)

    $headers = @{ 'User-Agent' = 'SDIO-QuickLauncher' }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $headers -ErrorAction SilentlyContinue
    if (-not $release) { return $null }

    $tag = [string]$release.tag_name
    $assets = @()
    if ($release.assets) {
        $assets = $release.assets | ForEach-Object { $_.name }
    }

    return [PSCustomObject]@{
        Tag    = $tag
        Html   = [string]$release.html_url
        Assets = $assets
    }
}

function Invoke-SdioRun {
    param(
        [string]$Mode,
        [System.Windows.Forms.RichTextBox]$LogBox,
        [System.Windows.Forms.Label]$Status,
        [ref]$CurrentProcess,
        [ref]$CurrentMode,
        [ref]$OutputFile,
        [ref]$ErrorFile
    )

    if ($CurrentProcess.Value -and -not $CurrentProcess.Value.HasExited) {
        $msg = "Already running: $($CurrentMode.Value). Finish or close first."
        Append-LogLine -Line $msg -Box $LogBox
        $Status.Text = $msg
        return
    }

    $psExe = Join-Path $PSHOME 'pwsh.exe'
    if (-not (Test-Path -LiteralPath $psExe)) {
        $psExe = Join-Path $PSHOME 'powershell.exe'
    }

    $tmp = [System.IO.Path]::GetTempFileName()
    $tmpErr = "$tmp.err"
    $tmpOut = "$tmp.out"

    $args = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$runner`"",
        '-SdioDir', "`"$SdioDir`"",
        '-ScriptFile', "`"$SafeScriptFile`""
    )

    $statusMessage = 'done.'

    if ($Mode -eq 'Scan') {
        $args += '-DryRun'
        $statusMessage = 'Scan pass running (dry-run).'
    } elseif ($Mode -eq 'ReScan') {
        $statusMessage = 'Re-Scan pass running.'
    } else {
        throw "Unknown mode: $Mode"
    }

    $Status.Text = $statusMessage
    Append-LogLine -Line $statusMessage -Box $LogBox
    Append-LogLine -Line "Command: $psExe $($args -join ' ')" -Box $LogBox

    $CurrentMode.Value = $Mode
    $OutputFile.Value = $tmpOut
    $ErrorFile.Value = $tmpErr

    if (Test-Path -LiteralPath $tmpOut) { Remove-Item -LiteralPath $tmpOut -Force }
    if (Test-Path -LiteralPath $tmpErr) { Remove-Item -LiteralPath $tmpErr -Force }

    $CurrentProcess.Value = Start-Process -FilePath $psExe `
        -ArgumentList $args `
        -WorkingDirectory $SdioDir `
        -RedirectStandardOutput $tmpOut `
        -RedirectStandardError $tmpErr `
        -PassThru
}

function Invoke-UpdateCheck {
    param(
        [string]$Repo,
        [string]$LocalTag,
        [System.Windows.Forms.RichTextBox]$LogBox,
        [System.Windows.Forms.Label]$Status
    )

    $Status.Text = 'Checking update information...'
    Append-LogLine -Line 'Checking update information...' -Box $LogBox

    $rel = Get-SdioReleaseInfo -Repo $Repo
    if (-not $rel) {
        $msg = 'No update info available. Opening release page for manual check.'
        Append-LogLine -Line $msg -Box $LogBox
        $Status.Text = $msg
        Start-Process "https://github.com/$Repo/releases"
        return
    }

    $releaseLine = "Latest fix pack: $($rel.Tag)"
    Append-LogLine -Line $releaseLine -Box $LogBox

    if ($LocalTag) {
        Append-LogLine -Line "Local pack tag: $LocalTag" -Box $LogBox
    }

    if ($LocalTag -ne $rel.Tag) {
        $Status.Text = 'Update available.'
        Append-LogLine -Line 'Newer release found. Open browser to verify and download manually.' -Box $LogBox
    } else {
        $Status.Text = 'Pack is up to date.'
        Append-LogLine -Line 'No newer release found for this package.' -Box $LogBox
    }

    Start-Process $rel.Html
}

if ($NoGui) {
    Write-Host 'Use CLI mode with parameters is available through Run-SDIO-Safe.ps1.'
    Write-Host "Scanner mode: -SdioDir `"$SdioDir`""
    Write-Host "Re-Scan mode:  -SdioDir `"$SdioDir`""
    Write-Host 'Use GUI mode by running without -NoGui.'
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$exe = Get-ChildItem -LiteralPath $SdioDir -Filter 'SDIO_x64_R*.exe' | Sort-Object Name -Descending | Select-Object -First 1
if (-not $exe) {
    throw 'SDIO_x64_R*.exe not found in SdioDir.'
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'SDIO Quick Launcher'
$form.Size = New-Object System.Drawing.Size(920, 620)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(700, 500)

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Top'
$panel.Height = 70
$panel.Padding = New-Object System.Windows.Forms.Padding(10)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = 'Scan'
$btnScan.Size = New-Object System.Drawing.Size(120, 32)
$btnScan.Location = New-Object System.Drawing.Point(10, 20)
$btnScan.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnRescan = New-Object System.Windows.Forms.Button
$btnRescan.Text = 'Re-Scan'
$btnRescan.Size = New-Object System.Drawing.Size(120, 32)
$btnRescan.Location = New-Object System.Drawing.Point(140, 20)
$btnRescan.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = 'Update'
$btnUpdate.Size = New-Object System.Drawing.Size(120, 32)
$btnUpdate.Location = New-Object System.Drawing.Point(270, 20)
$btnUpdate.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = 'Exit'
$btnExit.Size = New-Object System.Drawing.Size(120, 32)
$btnExit.Location = New-Object System.Drawing.Point(760, 20)
$btnExit.Anchor = 'Top, Right'

$panel.Controls.AddRange(@($btnScan, $btnRescan, $btnUpdate, $btnExit))

$info = New-Object System.Windows.Forms.Label
$info.AutoSize = $false
$info.Height = 44
$info.Dock = 'Top'
$info.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$info.Text = "SDIO: $($exe.Name) | Folder: $SdioDir"
$info.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.AutoSize = $false
$statusLabel.Height = 26
$statusLabel.Dock = 'Top'
$statusLabel.Padding = New-Object System.Windows.Forms.Padding(10, 4, 10, 4)
$statusLabel.Text = 'Ready.'
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$log = New-Object System.Windows.Forms.RichTextBox
$log.Multiline = $true
$log.ReadOnly = $true
$log.WordWrap = $true
$log.Dock = 'Fill'
$log.Font = New-Object System.Drawing.Font('Consolas', 9)

$form.Controls.Add($log)
$form.Controls.Add($statusLabel)
$form.Controls.Add($info)
$form.Controls.Add($panel)

$runnerState = @{
    Process     = $null
    Mode        = ''
    Timer       = $null
    OutputFile  = ''
    ErrorFile   = ''
}

function Set-ButtonsState {
    param([bool]$Enabled)
    $btnScan.Enabled = $Enabled
    $btnRescan.Enabled = $Enabled
    $btnUpdate.Enabled = $Enabled
    $btnExit.Enabled = $true
}

$poll = New-Object System.Windows.Forms.Timer
$poll.Interval = 600

$poll.Add_Tick({
    if (-not $runnerState.Process -or $runnerState.Process.HasExited) {
        if ($runnerState.Process -and $runnerState.Process.HasExited) {
            $out = if (Test-Path -LiteralPath $runnerState.OutputFile) { Get-Content -LiteralPath $runnerState.OutputFile -ErrorAction SilentlyContinue } else { @() }
            $err = if (Test-Path -LiteralPath $runnerState.ErrorFile) { Get-Content -LiteralPath $runnerState.ErrorFile -ErrorAction SilentlyContinue } else { @() }

            if ($out.Count -gt 0) {
                Append-LogLine -Line '--- SDIO output ---' -Box $log
                foreach ($line in $out) { Append-LogLine -Line $line -Box $log }
            }
            if ($err.Count -gt 0) {
                Append-LogLine -Line '--- SDIO error ---' -Box $log
                foreach ($line in $err) { Append-LogLine -Line $line -Box $log }
            }

            $code = $runnerState.Process.ExitCode
            $line = "$($runnerState.Mode) completed with ExitCode=$code"
            Append-LogLine -Line $line -Box $log
            if ($code -eq 0) {
                $statusLabel.Text = 'Done. Review output above.'
            } else {
                $statusLabel.Text = "Done with exit code: $code"
            }

            Set-ButtonsState -Enabled $true
            $runnerState.Process = $null
            $poll.Stop()
        } else {
            if (-not $runnerState.Process) {
                Set-ButtonsState -Enabled $true
                $poll.Stop()
            }
        }
        return
    }

    if (Test-Path -LiteralPath $runnerState.OutputFile) {
        $lines = Get-Content -LiteralPath $runnerState.OutputFile -Tail 40 -ErrorAction SilentlyContinue
        if ($lines -ne $null -and $lines.Count -gt 0) {
            $log.Clear()
            foreach ($line in $lines) { Append-LogLine -Line $line -Box $log }
        }
    }
})

$localTag = $null
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if (Test-Path -LiteralPath $repoRoot) {
    $gitDir = Join-Path $repoRoot '.git'
    if (Test-Path -LiteralPath $gitDir) {
        try {
            $tagOutput = & git -C $repoRoot describe --tags --abbrev=0 2>$null
            if (-not [string]::IsNullOrWhiteSpace($tagOutput)) {
                $localTag = $tagOutput.Trim()
            }
        } catch {
            # ignore - keep fallback path if git describe is unavailable
        }
    }

    if (-not $localTag) {
        $tagFile = Join-Path $repoRoot '.git\packed-refs'
        if (Test-Path -LiteralPath $tagFile) {
            $tagLine = Select-String -Path $tagFile -Pattern 'refs/tags/' -SimpleMatch -ErrorAction SilentlyContinue |
                Sort-Object LineNumber -Descending |
                Select-Object -First 1
            if ($tagLine) {
                $parts = ($tagLine.Line -split ' ')
                if ($parts.Length -ge 2) {
                    $localTag = $parts[1] -replace '^refs/tags/',''
                }
            }
        }
    }
}

$btnScan.Add_Click({
    Set-ButtonsState -Enabled $false
    try {
        Invoke-SdioRun -Mode 'Scan' -LogBox $log -Status $statusLabel -CurrentProcess ([ref]$runnerState.Process) -CurrentMode ([ref]$runnerState.Mode) -OutputFile ([ref]$runnerState.OutputFile) -ErrorFile ([ref]$runnerState.ErrorFile)
        $poll.Start()
    } catch {
        Append-LogLine -Line $_.Exception.Message -Box $log
        $statusLabel.Text = 'Scan failed to start.'
        Set-ButtonsState -Enabled $true
    }
})

$btnRescan.Add_Click({
    Set-ButtonsState -Enabled $false
    try {
        Invoke-SdioRun -Mode 'ReScan' -LogBox $log -Status $statusLabel -CurrentProcess ([ref]$runnerState.Process) -CurrentMode ([ref]$runnerState.Mode) -OutputFile ([ref]$runnerState.OutputFile) -ErrorFile ([ref]$runnerState.ErrorFile)
        $poll.Start()
    } catch {
        Append-LogLine -Line $_.Exception.Message -Box $log
        $statusLabel.Text = 'Re-Scan failed to start.'
        Set-ButtonsState -Enabled $true
    }
})

$btnUpdate.Add_Click({
    Set-ButtonsState -Enabled $false
    try {
        Invoke-UpdateCheck -Repo $CommunityRepo -LocalTag $localTag -LogBox $log -Status $statusLabel
    } catch {
        Append-LogLine -Line $_.Exception.Message -Box $log
        $statusLabel.Text = 'Update check failed.'
    }
    Set-ButtonsState -Enabled $true
})

$btnExit.Add_Click({
    if ($runnerState.Process -and -not $runnerState.Process.HasExited) {
        try { $runnerState.Process.Kill() } catch { }
    }
    $form.Close()
})

$form.Add_FormClosing({
    if ($runnerState.Process -and -not $runnerState.Process.HasExited) {
        try { $runnerState.Process.Kill() } catch { }
    }
})

[void]$form.ShowDialog()

Start-Sleep -Seconds 180
$logPath = Join-Path $PSScriptRoot 'verify_after_boot.log'
Start-Transcript -Path $logPath -Append
try {
    if (-not $env:SDIO_DIR) { throw 'Set $env:SDIO_DIR to your SDIO folder before scheduling this script.' }
    & (Join-Path $PSScriptRoot 'Verify-LocaleFix.ps1') -SdioDir $env:SDIO_DIR
}
finally {
    Stop-Transcript | Out-Null
    schtasks /delete /tn "SDIO-Fix-PostBoot-Verify" /f 2>$null | Out-Null
}

[CmdletBinding()]
param(
    [string] $SdioDir = $env:SDIO_DIR
)

$ErrorActionPreference='SilentlyContinue'
if ([string]::IsNullOrWhiteSpace($SdioDir)) {
    throw 'SdioDir is required. Set $env:SDIO_DIR or pass -SdioDir path.'
}

Write-Host "=== 1) Locale / encoding state ===" -ForegroundColor Cyan
$acp = [System.Text.Encoding]::Default.CodePage
$reg = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage').ACP
Write-Host "  registry ACP : $reg"
Write-Host "  process  ACP : $acp"
if ([int]$reg -ne 1256) {
    Write-Host "  FAIL: registry ACP is not 1256" -ForegroundColor Red
    Write-Host "  Re-run Fix-Locale-DisableUTF8Beta.ps1 as admin, then reboot." -ForegroundColor Yellow
    return
}
Write-Host "  OK - registry codepage is active: ACP=1256" -ForegroundColor Green
if ($acp -ne 1256) {
    Write-Host "  Note: process ACP remains $acp in this session until shell restart." -ForegroundColor Yellow
}

Write-Host "`n=== 2) SDIO dry-run selection check ===" -ForegroundColor Cyan
$runScript = Join-Path $PSScriptRoot 'Run-SDIO-Safe.ps1'
if (-not (Test-Path -LiteralPath $runScript)) {
    $runScript = Join-Path $SdioDir 'scripts\Run-SDIO-Safe.ps1'
}
& $runScript -SdioDir $SdioDir -DryRun | Out-Null

Write-Host "`n=== 3) warning check in latest log ===" -ForegroundColor Cyan
$log = Get-ChildItem "$SdioDir\logs" -Filter '*_log.txt' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
Write-Host "  log: $($log.Name)"
$raw = Get-Content $log.FullName -Raw
$u = $raw -match 'unicode2ansi'
$s = $raw -match 'sect not found'
Write-Host "  unicode2ansi  : $u"
Write-Host "  sect not found: $s"
if (-not $u -and -not $s) { Write-Host "`n  PASS - warning line is gone" -ForegroundColor Green }
else { Write-Host "`n  WARN - warning remains; check encoding/SDIO run context." -ForegroundColor Red }

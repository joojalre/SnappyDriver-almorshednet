[CmdletBinding()]
param(
    [string] $SdioDir = $env:SDIO_DIR
)

$ErrorActionPreference = 'Stop'

function Get-ActiveACP {
    param()
    if (-not ([System.Management.Automation.PSTypeName]'GetACPClass').Type) {
        try {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class GetACPClass
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern int GetACP();
}
'@ -ErrorAction Stop
        } catch {
            return [System.Text.Encoding]::Default.CodePage
        }
    }
    try {
        return [GetACPClass]::GetACP()
    } catch {
        return [System.Text.Encoding]::Default.CodePage
    }
}

if ([string]::IsNullOrWhiteSpace($SdioDir)) {
    throw 'SdioDir is required. Set $env:SDIO_DIR or pass -SdioDir path.'
}

Write-Host "=== 1) Locale / encoding state ===" -ForegroundColor Cyan
$regObj = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage'
$regAcp = [int]$regObj.ACP
$processAcp = [System.Text.Encoding]::Default.CodePage
$activeAcp = Get-ActiveACP
Write-Host "  registry ACP : $regAcp"
Write-Host "  Windows GetACP(): $activeAcp"
Write-Host "  process  ACP : $processAcp"

if ($regAcp -ne 1256) {
    Write-Host "  FAIL: registry ACP is not 1256" -ForegroundColor Red
    Write-Host "  Re-run Fix-Locale-DisableUTF8Beta.ps1 as admin, then reboot." -ForegroundColor Yellow
    return
}
Write-Host "  OK - registry codepage is active: ACP=1256" -ForegroundColor Green
if ($processAcp -ne 1256) {
    Write-Host "  Note: process ACP may still read as $processAcp in current PowerShell session." -ForegroundColor Yellow
}

Write-Host "`n=== 2) SDIO dry-run selection check ===" -ForegroundColor Cyan
$runScript = Join-Path $PSScriptRoot 'Run-SDIO-Safe.ps1'
if (-not (Test-Path -LiteralPath $runScript)) {
    $runScript = Join-Path $SdioDir 'scripts\Run-SDIO-Safe.ps1'
}
if (-not (Test-Path -LiteralPath $runScript)) {
    throw "Run-SDIO-Safe.ps1 not found. Expected: $runScript"
}
& $runScript -SdioDir $SdioDir -DryRun | Out-Null

Write-Host "`n=== 3) warning check in latest log ===" -ForegroundColor Cyan
$log = Get-ChildItem "$SdioDir\logs" -Filter '*_log.txt' -EA SilentlyContinue |
    Sort-Object LastWriteTime -Desc |
    Select-Object -First 1
if (-not $log) {
    throw "No *_log.txt found in $SdioDir\logs"
}
Write-Host "  log: $($log.Name)"
$raw = Get-Content $log.FullName -Raw
$u = $raw -match 'unicode2ansi'
$s = $raw -match 'sect not found'
Write-Host "  unicode2ansi  : $u"
Write-Host "  sect not found: $s"
if (-not $u -and -not $s) { Write-Host "`n  PASS - warning line is gone" -ForegroundColor Green }
else { Write-Host "`n  WARN - warning remains; check encoding/SDIO run context." -ForegroundColor Red }

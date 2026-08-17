$ErrorActionPreference = 'Stop'
$out = Split-Path -Path $PSScriptRoot -Parent
$res = Join-Path $out 'locale-fix-result.txt'
$k   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage'
$log = @()
try {
    $before = Get-ItemProperty $k | Select-Object ACP,OEMCP,MACCP
    $log += "BEFORE: ACP=$($before.ACP) OEMCP=$($before.OEMCP) MACCP=$($before.MACCP)"

    $bak = Join-Path $out 'CodePage-BACKUP.reg'
    & reg.exe export 'HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage' $bak /y | Out-Null
    $log += "BACKUP: $bak"

    Set-ItemProperty $k -Name ACP   -Value '1256'
    Set-ItemProperty $k -Name OEMCP -Value '720'
    Set-ItemProperty $k -Name MACCP -Value '10004'

    $after = Get-ItemProperty $k | Select-Object ACP,OEMCP,MACCP
    $log += "AFTER : ACP=$($after.ACP) OEMCP=$($after.OEMCP) MACCP=$($after.MACCP)"
    $ok = ($after.ACP -eq '1256' -and $after.OEMCP -eq '720' -and $after.MACCP -eq '10004')
    $log += "RESULT: " + $(if($ok){'SUCCESS - reboot required'}else{'MISMATCH'})
}
catch { $log += "ERROR: $($_.Exception.Message)" }
$log | Set-Content -LiteralPath $res -Encoding UTF8

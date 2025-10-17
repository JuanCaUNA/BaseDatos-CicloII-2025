<# Purge archivelogs older than 3 days using RMAN and file cleanup #>

$env:ORACLE_HOME = 'C:\oracle\product\19.0.0\dbhome_1'
$env:ORACLE_SID = 'ORCL'
$rman = Join-Path $env:ORACLE_HOME 'bin\\rman.exe'
$archiveDir = "C:\oracle\oradata\$($env:ORACLE_SID)\archivelog"

$rmanScript = @"
DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-3';
EXIT
"@

$rmanScriptFile = Join-Path $env:TEMP "rman_purge_${env:ORACLE_SID}.cmd"
$rmanScript | Out-File -FilePath $rmanScriptFile -Encoding ASCII

Start-Process -FilePath $rman -ArgumentList "TARGET /","@${rmanScriptFile}" -NoNewWindow -Wait
Remove-Item $rmanScriptFile -ErrorAction SilentlyContinue

Get-ChildItem -Path $archiveDir -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } | ForEach-Object { Remove-Item $_.FullName -Force }

Exit 0

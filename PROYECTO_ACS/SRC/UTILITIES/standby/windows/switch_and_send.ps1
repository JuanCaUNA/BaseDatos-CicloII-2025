<#
  For: Primary server (Windows)
  Purpose: Forzar SWITCH LOGFILE via sqlplus y copiar archivelogs a carpeta de envío
#>

$env:ORACLE_HOME = 'C:\\oracle\\product\\19.0.0\\dbhome_1'
$env:ORACLE_SID = 'ORCL'
$sqlplus = Join-Path $env:ORACLE_HOME 'bin\\sqlplus.exe'
$archiveDir = "C:\\oracle\\oradata\\$($env:ORACLE_SID)\\archivelog"
$sendDir = 'C:\\standby\\send'

If (!(Test-Path $sendDir)) { New-Item -ItemType Directory -Path $sendDir | Out-Null }

# Crear archivo SQL temporal
$tmpSql = [IO.Path]::Combine($env:TEMP, "switch_${env:ORACLE_SID}.sql")
"ALTER SYSTEM SWITCH LOGFILE;" | Out-File -FilePath $tmpSql -Encoding ASCII

# Ejecutar sqlplus
Start-Process -FilePath $sqlplus -ArgumentList "/ as sysdba","@$tmpSql" -NoNewWindow -Wait

Remove-Item $tmpSql -ErrorAction SilentlyContinue

# Copiar archivos modificados en los últimos 10 minutos
Get-ChildItem -Path $archiveDir -File | Where-Object { $_.LastWriteTime -ge (Get-Date).AddMinutes(-10) } | ForEach-Object {
  Copy-Item -Path $_.FullName -Destination $sendDir -Force
}

Exit 0

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('status','switch','transfer','backup','purge','validate','switchover','failover','logs')]
    [string]$Action,
    [switch]$Force,
    [int]$BackupLevel = 1,
    [int]$TailLines = 80
)

$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
$primaryContainer = 'oracle_primary'
$standbyContainer = 'oracle_standby'
$logRoot = '/opt/oracle/shared/logs'
$stateRoot = '/opt/oracle/shared/state'
$backupRoot = '/opt/oracle/shared/backups'

function Write-Heading {
    param([string]$Text)
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host ('  {0}' -f $Text) -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
}

function Run-InContainer {
    param([string]$Container,[string]$Command)
    $output = & docker exec $Container 'bash' '-lc' $Command 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "docker exec $Container '$Command' failed ($exitCode): $output"
    }
    return $output
}

function Invoke-Sql {
    param([string]$Container,[string]$Sql)
    $sqlBlock = @"
sqlplus -s / as sysdba <<'SQL'
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 0
$Sql
EXIT;
SQL
"@
    $output = Run-InContainer -Container $Container -Command $sqlBlock
    if ($null -eq $output) {
        return ''
    }
    return $output.Trim()
}

function Show-Log {
    param([string]$Container,[string]$Path,[int]$Lines,[string]$Label)
    Write-Host "`n[$Label]" -ForegroundColor Cyan
    try {
        $log = Run-InContainer -Container $Container -Command "tail -n $Lines $Path"
        if ([string]::IsNullOrWhiteSpace($log)) {
            Write-Host '  (sin datos)' -ForegroundColor DarkGray
        } else {
            $log -split "`n" | ForEach-Object { Write-Host ('  {0}' -f $_) -ForegroundColor Gray }
        }
    }
    catch {
        Write-Host ('  No se pudo leer {0} ({1})' -f $Path, $_.Exception.Message) -ForegroundColor DarkYellow
    }
}

function Show-Status {
    Write-Heading 'Estado Data Guard'

    $primaryRole = Invoke-Sql -Container $primaryContainer -Sql 'SELECT database_role FROM v$database;'
    $primaryMode = Invoke-Sql -Container $primaryContainer -Sql 'SELECT open_mode FROM v$database;'
    $primarySwitch = Invoke-Sql -Container $primaryContainer -Sql 'SELECT switchover_status FROM v$database;'
    $primarySeq = [int](Invoke-Sql -Container $primaryContainer -Sql 'SELECT NVL(MAX(sequence#),0) FROM v$archived_log WHERE dest_id = 1;')

    $standbyRole = Invoke-Sql -Container $standbyContainer -Sql 'SELECT database_role FROM v$database;'
    $standbyMode = Invoke-Sql -Container $standbyContainer -Sql 'SELECT open_mode FROM v$database;'
    $standbySwitch = Invoke-Sql -Container $standbyContainer -Sql 'SELECT switchover_status FROM v$database;'
    $standbySeq = [int](Invoke-Sql -Container $standbyContainer -Sql 'SELECT NVL(MAX(sequence#),0) FROM v$archived_log WHERE applied = ''YES'';')
    $mrpCount = [int](Invoke-Sql -Container $standbyContainer -Sql 'SELECT COUNT(*) FROM v$managed_standby WHERE process LIKE ''MRP%'';')
    $transportLag = Invoke-Sql -Container $standbyContainer -Sql 'SELECT VALUE FROM v$dataguard_stats WHERE name = ''transport lag'';'
    $applyLag = Invoke-Sql -Container $standbyContainer -Sql 'SELECT VALUE FROM v$dataguard_stats WHERE name = ''apply lag'';'

    $seqLag = [math]::Abs($primarySeq - $standbySeq)

    Write-Host "PRIMARY ($primaryContainer)" -ForegroundColor Green
    Write-Host ('  role={0}' -f $primaryRole) -ForegroundColor Gray
    Write-Host ('  open_mode={0}' -f $primaryMode) -ForegroundColor Gray
    Write-Host ('  switchover_status={0}' -f $primarySwitch) -ForegroundColor Gray
    Write-Host ('  max_sequence={0}' -f $primarySeq) -ForegroundColor Gray

    Write-Host "STANDBY ($standbyContainer)" -ForegroundColor Green
    Write-Host ('  role={0}' -f $standbyRole) -ForegroundColor Gray
    Write-Host ('  open_mode={0}' -f $standbyMode) -ForegroundColor Gray
    Write-Host ('  switchover_status={0}' -f $standbySwitch) -ForegroundColor Gray
    Write-Host ('  max_applied_sequence={0}' -f $standbySeq) -ForegroundColor Gray
    Write-Host ('  mrp_processes={0}' -f $mrpCount) -ForegroundColor Gray
    Write-Host ('  transport_lag={0}' -f $transportLag) -ForegroundColor Gray
    Write-Host ('  apply_lag={0}' -f $applyLag) -ForegroundColor Gray
    Write-Host ('  sequence_diff={0}' -f $seqLag) -ForegroundColor Gray

    try {
        $stateData = Run-InContainer -Container $primaryContainer -Command "cat $stateRoot/archivelog_transfer.state"
        if ($stateData) {
            Write-Host 'archivelog_transfer.state' -ForegroundColor Green
            $stateData -split "`n" | ForEach-Object { Write-Host ('  {0}' -f $_) -ForegroundColor Gray }
        }
    }
    catch {
        Write-Host 'No se encontro archivelog_transfer.state' -ForegroundColor DarkYellow
    }

    try {
        $latestBackup = Run-InContainer -Container $primaryContainer -Command "ls -1t $backupRoot | head -n 1"
        if ($latestBackup) {
            Write-Host ('Ultimo backup: {0}' -f $latestBackup.Trim()) -ForegroundColor Green
        }
    }
    catch {
        Write-Host ('No se detectaron backups en {0}' -f $backupRoot) -ForegroundColor DarkYellow
    }
}

function Execute-LogSwitch {
    Write-Heading 'Switch Logfile'
    $result = Invoke-Sql -Container $primaryContainer -Sql 'ALTER SYSTEM SWITCH LOGFILE;'
    Write-Host ('Resultado: {0}' -f $result) -ForegroundColor Green
}

function Execute-Transfer {
    Write-Heading 'Transferencia de Archivelogs'
    $result = Run-InContainer -Container $primaryContainer -Command '/opt/oracle/scripts/automation/archivelog_transfer.sh --once'
    Write-Host $result -ForegroundColor Gray
    Show-Log -Container $primaryContainer -Path "$logRoot/archivelog_transfer.log" -Lines 10 -Label 'archivelog_transfer.log'
}

function Execute-Backup {
    Write-Heading 'Backup RMAN'
    $command = "BACKUP_LEVEL=$BackupLevel /opt/oracle/scripts/automation/backup_transfer.sh --once"
    $result = Run-InContainer -Container $primaryContainer -Command $command
    Write-Host $result -ForegroundColor Gray
    Show-Log -Container $primaryContainer -Path "$logRoot/backup_transfer.log" -Lines 15 -Label 'backup_transfer.log'
}

function Execute-Purge {
    Write-Heading 'Purga de Archivelogs'
    $result = Run-InContainer -Container $standbyContainer -Command '/opt/oracle/scripts/automation/archivelog_purge.sh --once'
    Write-Host $result -ForegroundColor Gray
    Show-Log -Container $standbyContainer -Path "$logRoot/archivelog_purge.log" -Lines 10 -Label 'archivelog_purge.log'
}

function Execute-Validate {
    Write-Heading 'Validacion Data Guard'
    Run-InContainer -Container $primaryContainer -Command '/opt/oracle/scripts/automation/validate_dataguard.sh' | Out-Null
    Show-Log -Container $primaryContainer -Path "$logRoot/validate_dataguard.log" -Lines 30 -Label 'validate_dataguard.log'
}

function Execute-Switchover {
    Write-Heading 'Switchover'
    if (-not $Force) {
        $confirm = Read-Host 'Confirma switchover (yes/no)'
        if ($confirm -ne 'yes') {
            Write-Host 'Switchover cancelado.' -ForegroundColor Yellow
            return
        }
    }
    $result = Run-InContainer -Container $primaryContainer -Command '/opt/oracle/scripts/automation/switchover.sh --auto-confirm'
    Write-Host $result -ForegroundColor Gray
    Show-Log -Container $primaryContainer -Path "$logRoot/switchover.log" -Lines 20 -Label 'switchover.log'
}

function Execute-Failover {
    Write-Heading 'Failover'
    if (-not $Force) {
        Write-Host 'Debe especificar -Force para ejecutar failover.' -ForegroundColor Yellow
        return
    }
    $failoverScript = Join-Path $scriptRoot 'failover_dataguard.ps1'
    if (-not (Test-Path $failoverScript)) {
        throw 'No se encontro failover_dataguard.ps1'
    }
    & $failoverScript -Force
}

function Show-Logs {
    Write-Heading 'Logs de Automatizacion'
    Show-Log -Container $primaryContainer -Path "$logRoot/archivelog_transfer.log" -Lines $TailLines -Label 'archivelog_transfer.log'
    Show-Log -Container $standbyContainer -Path "$logRoot/archivelog_purge.log" -Lines $TailLines -Label 'archivelog_purge.log'
    Show-Log -Container $primaryContainer -Path "$logRoot/backup_transfer.log" -Lines $TailLines -Label 'backup_transfer.log'
    Show-Log -Container $primaryContainer -Path "$logRoot/switchover.log" -Lines $TailLines -Label 'switchover.log'
    Show-Log -Container $standbyContainer -Path "$logRoot/rman_duplicate.log" -Lines $TailLines -Label 'rman_duplicate.log'
}

switch ($Action) {
    'status'     { Show-Status }
    'switch'     { Execute-LogSwitch }
    'transfer'   { Execute-Transfer }
    'backup'     { Execute-Backup }
    'purge'      { Execute-Purge }
    'validate'   { Execute-Validate }
    'switchover' { Execute-Switchover }
    'failover'   { Execute-Failover }
    'logs'       { Show-Logs }
}

# ========================================
# DOCKER DATA GUARD - AUTOMATIZACIÓN COMPLETA
# Adaptado para contenedores Docker Oracle 19c
# ========================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("switch", "transfer", "backup", "purge", "status", "full-cycle", "demo")]
    [string]$Action
)

# Configuración Docker
$DOCKER_PRIMARY = "oracle_primary"
$DOCKER_STANDBY = "oracle_standby" 
$ORACLE_PWD = "admin123"
$SHARED_DIR = "/opt/oracle/shared"
$ARCHIVELOG_DIR = "$SHARED_DIR/archivelogs"
$BACKUP_DIR = "$SHARED_DIR/backups"
$LOG_DIR = "C:\temp\dataguard_logs"

# Crear directorios si no existen
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force
}

function Write-LogMessage {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage -ForegroundColor Green
    Add-Content -Path "$LOG_DIR\dataguard_complete.log" -Value $logMessage
}

function Invoke-SqlInContainer {
    param(
        [string]$Container,
        [string]$SqlCommand,
        [string]$DbService = "localhost:1521/ORCL"
    )
    
    try {
        $result = docker exec $Container bash -c "echo '$SqlCommand' | sqlplus -s sys/$ORACLE_PWD@//$DbService as sysdba"
        return $result
    }
    catch {
        Write-LogMessage "Error ejecutando SQL en $Container`: $_"
        return $null
    }
}

# ========================================
# FUNCIÓN: SWITCH LOGFILE (Cada 5 minutos)
# ========================================
function Switch-LogFile {
    Write-LogMessage "Ejecutando SWITCH LOGFILE en primaria..."
    
    $switchCmd = "ALTER SYSTEM SWITCH LOGFILE;"
    $result = Invoke-SqlInContainer -Container $DOCKER_PRIMARY -SqlCommand $switchCmd
    
    if ($result -match "System altered") {
        Write-LogMessage "✅ SWITCH LOGFILE ejecutado exitosamente"
        
        # Verificar que se generó archivelog
        $archiveCheck = "SELECT COUNT(*) FROM v`$archived_log WHERE completion_time > SYSDATE - 1/288;"
        $count = Invoke-SqlInContainer -Container $DOCKER_PRIMARY -SqlCommand $archiveCheck
        Write-LogMessage "Archivelogs generados en últimos 5 min: $count"
    } else {
        Write-LogMessage "❌ Error en SWITCH LOGFILE: $result"
    }
}

# ========================================
# FUNCIÓN: TRANSFERIR ARCHIVELOGS (Cada 10 minutos)
# ========================================
function Transfer-ArchiveLogs {
    Write-LogMessage "Transfiriendo archivelogs al standby..."
    
    # En Docker, los archivos ya están compartidos via volumen
    # Verificamos que el standby pueda ver los archivos
    $transferCheck = docker exec $DOCKER_STANDBY bash -c "ls -la $ARCHIVELOG_DIR | wc -l"
    
    if ($transferCheck -gt 1) {
        Write-LogMessage "✅ Archivos disponibles en standby: $transferCheck archivos"
        
        # Aplicar archivelogs en standby (si está montado)
        $applyCmd = "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;"
        $result = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand $applyCmd -DbService "localhost:1521/STBY"
        
        if ($result -notmatch "ORA-") {
            Write-LogMessage "✅ Aplicación de archivelogs iniciada"
        } else {
            Write-LogMessage "⚠️ Standby no listo para aplicar logs: $result"
        }
    } else {
        Write-LogMessage "❌ No se encontraron archivos para transferir"
    }
}

# ========================================
# FUNCIÓN: BACKUP DIARIO
# ========================================
function Perform-Backup {
    Write-LogMessage "Iniciando backup diario de la base de datos..."
    
    $backupDate = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupScript = @"
RUN {
    ALLOCATE CHANNEL ch1 TYPE DISK;
    BACKUP DATABASE FORMAT '$BACKUP_DIR/backup_${backupDate}_%U.bkp';
    BACKUP CURRENT CONTROLFILE FORMAT '$BACKUP_DIR/controlfile_${backupDate}.ctl';
    BACKUP ARCHIVELOG ALL FORMAT '$BACKUP_DIR/archivelog_${backupDate}_%U.arc';
    RELEASE CHANNEL ch1;
}
"@
    
    # Ejecutar RMAN backup
    $rmanResult = docker exec $DOCKER_PRIMARY bash -c "echo '$backupScript' | rman target sys/$ORACLE_PWD@//localhost:1521/ORCL"
    
    if ($rmanResult -match "completed successfully") {
        Write-LogMessage "✅ Backup completado exitosamente: backup_${backupDate}"
        
        # Verificar que el backup está disponible en standby
        $backupCheck = docker exec $DOCKER_STANDBY bash -c "ls -la $BACKUP_DIR/*${backupDate}* | wc -l"
        Write-LogMessage "Archivos de backup en standby: $backupCheck"
    } else {
        Write-LogMessage "❌ Error en backup: $rmanResult"
    }
}

# ========================================
# FUNCIÓN: PURGAR ARCHIVOS >3 DÍAS
# ========================================
function Purge-OldFiles {
    Write-LogMessage "Purgando archivos antiguos (>3 días)..."
    
    # Purgar archivelogs usando RMAN
    $purgeScript = @"
DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-3';
DELETE NOPROMPT BACKUP COMPLETED BEFORE 'SYSDATE-3';
"@
    
    $purgeResult = docker exec $DOCKER_PRIMARY bash -c "echo '$purgeScript' | rman target sys/$ORACLE_PWD@//localhost:1521/ORCL"
    
    # Purgar archivos físicos en directorio compartido
    $purgeFiles = docker exec $DOCKER_PRIMARY bash -c "find $ARCHIVELOG_DIR -name '*.arc' -mtime +3 -delete 2>/dev/null; find $BACKUP_DIR -name '*.bkp' -mtime +3 -delete 2>/dev/null"
    
    Write-LogMessage "✅ Purga completada - RMAN y archivos físicos"
}

# ========================================
# FUNCIÓN: VERIFICAR ESTADO
# ========================================
function Check-Status {
    Write-LogMessage "Verificando estado del Data Guard..."
    
    # Estado primaria
    $primaryStatus = Invoke-SqlInContainer -Container $DOCKER_PRIMARY -SqlCommand "SELECT database_role, log_mode FROM v`$database;"
    Write-LogMessage "Estado Primaria: $primaryStatus"
    
    # Estado standby
    $standbyStatus = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand "SELECT database_role FROM v`$database;" -DbService "localhost:1521/STBY"
    Write-LogMessage "Estado Standby: $standbyStatus"
    
    # Último archivelog aplicado
    $lastApplied = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand "SELECT MAX(sequence#) FROM v`$archived_log WHERE applied=`'YES`';" -DbService "localhost:1521/STBY"
    Write-LogMessage "Último archivelog aplicado en standby: $lastApplied"
    
    return $true
}

# ========================================
# FUNCIÓN: CICLO COMPLETO (Para demostración)
# ========================================
function Run-FullCycle {
    Write-LogMessage "=== INICIANDO CICLO COMPLETO DATA GUARD ==="
    
    Check-Status
    Switch-LogFile
    Start-Sleep -Seconds 30
    Transfer-ArchiveLogs
    Start-Sleep -Seconds 30
    Perform-Backup
    Start-Sleep -Seconds 30
    Purge-OldFiles
    Check-Status
    
    Write-LogMessage "=== CICLO COMPLETO FINALIZADO ==="
}

# ========================================
# FUNCIÓN: DEMO PARA PROFESOR
# ========================================
function Run-Demo {
    Write-LogMessage "=== DEMO PARA PROFESOR - DATA GUARD AUTOMATIZADO ==="
    
    Write-Host "`n🎯 DEMOSTRACIÓN EN TIEMPO REAL" -ForegroundColor Cyan
    Write-Host "1. Verificando estado inicial..." -ForegroundColor Yellow
    Check-Status
    
    Write-Host "`n2. Forzando generación de archivelog..." -ForegroundColor Yellow
    Switch-LogFile
    
    Write-Host "`n3. Transfiriendo al standby..." -ForegroundColor Yellow
    Transfer-ArchiveLogs
    
    Write-Host "`n4. Realizando backup..." -ForegroundColor Yellow
    Perform-Backup
    
    Write-Host "`n5. Verificando estado final..." -ForegroundColor Yellow
    Check-Status
    
    Write-Host "`n✅ DEMOSTRACIÓN COMPLETADA" -ForegroundColor Green
    Write-LogMessage "=== DEMO COMPLETADA EXITOSAMENTE ==="
}

# ========================================
# MAIN EXECUTION
# ========================================
Write-LogMessage "Iniciando automatización Data Guard - Acción: $Action"

switch ($Action) {
    "switch" { Switch-LogFile }
    "transfer" { Transfer-ArchiveLogs }
    "backup" { Perform-Backup }
    "purge" { Purge-OldFiles }
    "status" { Check-Status }
    "full-cycle" { Run-FullCycle }
    "demo" { Run-Demo }
    default { Write-LogMessage "Acción no válida: $Action" }
}

Write-LogMessage "Automatización completada - Acción: $Action"
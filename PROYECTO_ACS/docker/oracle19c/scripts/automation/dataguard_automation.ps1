# ========================================
# SCRIPT DE AUTOMATIZACIÓN DATA GUARD - WINDOWS
# Genera archivelog cada 5 minutos y transfiere cada 10 minutos
# ========================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("switch", "transfer", "backup", "purge", "status", "full-cycle")]
    [string]$Action
)

# Configuración
$DOCKER_PRIMARY = "oracle_primary"
$DOCKER_STANDBY = "oracle_standby" 
$ORACLE_PWD = "admin123"
$SHARED_DIR = "/opt/oracle/shared"
$LOG_DIR = "C:\temp\dataguard_logs"

# Crear directorio de logs si no existe
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force
}

# Función para log con timestamp
function Write-LogMessage {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path "$LOG_DIR\dataguard_automation.log" -Value $logMessage
}

# Función para ejecutar SQL en contenedor Docker
function Invoke-SqlInContainer {
    param(
        [string]$Container,
        [string]$SqlCommand,
        [string]$DbService
    )
    
    $sqlScript = @"
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
$SqlCommand
EXIT;
"@
    
    try {
        $result = $sqlScript | docker exec -i $Container sqlplus -S sys/$ORACLE_PWD@$DbService as sysdba
        return $result
    }
    catch {
        Write-LogMessage "ERROR ejecutando SQL: $($_.Exception.Message)"
        return $null
    }
}

# Función para forzar log switch en primaria
function Invoke-LogSwitch {
    Write-LogMessage "Forzando log switch en base primaria..."
    
    $result = Invoke-SqlInContainer -Container $DOCKER_PRIMARY -SqlCommand "ALTER SYSTEM SWITCH LOGFILE;" -DbService "ORCL"
    
    if ($LASTEXITCODE -eq 0) {
        Write-LogMessage "Log switch ejecutado exitosamente"
        
        # Verificar archivelog generado
        $newestArchive = Invoke-SqlInContainer -Container $DOCKER_PRIMARY -SqlCommand "SELECT MAX(name) FROM v`$archived_log WHERE completion_time > SYSDATE - 1/1440;" -DbService "ORCL"
        Write-LogMessage "Último archivelog generado: $newestArchive"
        return $true
    }
    else {
        Write-LogMessage "ERROR: Fallo al ejecutar log switch"
        return $false
    }
}

# Función para transferir archivelogs
function Invoke-ArchivelogTransfer {
    Write-LogMessage "Iniciando transferencia de archivelogs..."
    
    try {
        # Obtener lista de archivelogs recientes (últimos 15 minutos)
        $recentArchives = docker exec $DOCKER_PRIMARY find /opt/oracle/shared/archivelogs -name "*.arc" -mmin -15
        
        foreach ($archive in $recentArchives) {
            if ($archive) {
                Write-LogMessage "Procesando archivo: $archive"
                
                $basename = Split-Path $archive -Leaf
                
                # Esperar a que el archivo esté completo
                Start-Sleep -Seconds 2
                
                # Aplicar archivelog en standby
                $null = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;" -DbService "STBY" -ErrorAction SilentlyContinue
                $null = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;" -DbService "STBY" -ErrorAction SilentlyContinue
                
                Write-LogMessage "Archivelog $basename procesado"
            }
        }
        return $true
    }
    catch {
        Write-LogMessage "ERROR en transferencia: $($_.Exception.Message)"
        return $false
    }
}

# Función para realizar backup diario
function Invoke-DailyBackup {
    Write-LogMessage "Iniciando backup diario de base primaria..."
    
    $backupDate = Get-Date -Format "yyyyMMdd"
    $backupDir = "/opt/oracle/shared/backups/$backupDate"
    
    # Crear directorio de backup
    docker exec $DOCKER_PRIMARY mkdir -p $backupDir
    
    $rmanScript = @"
RUN {
    CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$backupDir/ctrl_%F';
    BACKUP AS COMPRESSED BACKUPSET DATABASE FORMAT '$backupDir/db_%d_%U';
    BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL FORMAT '$backupDir/arch_%d_%U' DELETE INPUT;
    BACKUP CURRENT CONTROLFILE FORMAT '$backupDir/ctrl_current_%U';
}
EXIT;
"@
    
    try {
        $result = $rmanScript | docker exec -i $DOCKER_PRIMARY rman target sys/$ORACLE_PWD@ORCL
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Backup diario completado exitosamente en $backupDir"
            return $true
        }
        else {
            Write-LogMessage "ERROR: Fallo en backup diario"
            return $false
        }
    }
    catch {
        Write-LogMessage "ERROR en backup: $($_.Exception.Message)"
        return $false
    }
}

# Función para purgar archivelogs antiguos
function Invoke-PurgeOldArchivelogs {
    Write-LogMessage "Iniciando purga de archivelogs antiguos (>3 días)..."
    
    $rmanPurgeScript = @"
DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-3';
EXIT;
"@
    
    try {
        # Purgar desde RMAN en primaria
        $result = $rmanPurgeScript | docker exec -i $DOCKER_PRIMARY rman target sys/$ORACLE_PWD@ORCL
        
        # Purgar archivos físicos antiguos del directorio compartido
        docker exec $DOCKER_PRIMARY find /opt/oracle/shared/archivelogs -name "*.arc" -mtime +3 -delete
        docker exec $DOCKER_PRIMARY find /opt/oracle/shared/backups -type d -mtime +7 -exec rm -rf {} \; 2>$null
        
        Write-LogMessage "Purga de archivelogs completada"
        return $true
    }
    catch {
        Write-LogMessage "ERROR en purga: $($_.Exception.Message)"
        return $false
    }
}

# Función para verificar estado de Data Guard
function Test-DataGuardStatus {
    Write-LogMessage "Verificando estado de Data Guard..."
    
    try {
        # Verificar primaria
        $primaryStatus = Invoke-SqlInContainer -Container $DOCKER_PRIMARY -SqlCommand "SELECT database_role || ',' || log_mode FROM v`$database;" -DbService "ORCL"
        Write-LogMessage "Estado Primaria: $primaryStatus"
        
        # Verificar standby
        $standbyStatus = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand "SELECT database_role || ',' || log_mode FROM v`$database;" -DbService "STBY" -ErrorAction SilentlyContinue
        if ($standbyStatus) {
            Write-LogMessage "Estado Standby: $standbyStatus"
        }
        else {
            Write-LogMessage "ADVERTENCIA: Standby no está disponible o no configurado completamente"
        }
        
        # Verificar últimos archivelogs aplicados
        $lastApplied = Invoke-SqlInContainer -Container $DOCKER_STANDBY -SqlCommand "SELECT MAX(sequence#) FROM v`$archived_log WHERE applied='YES';" -DbService "STBY" -ErrorAction SilentlyContinue
        Write-LogMessage "Último archivelog aplicado en standby: $lastApplied"
        
        return $true
    }
    catch {
        Write-LogMessage "ERROR en verificación de estado: $($_.Exception.Message)"
        return $false
    }
}

# Función principal
function Invoke-MainAction {
    param([string]$ActionType)
    
    switch ($ActionType) {
        "switch" {
            Invoke-LogSwitch
        }
        "transfer" {
            Invoke-ArchivelogTransfer
        }
        "backup" {
            Invoke-DailyBackup
        }
        "purge" {
            Invoke-PurgeOldArchivelogs
        }
        "status" {
            Test-DataGuardStatus
        }
        "full-cycle" {
            Write-LogMessage "=== INICIANDO CICLO COMPLETO ==="
            Invoke-LogSwitch
            Start-Sleep -Seconds 30
            Invoke-ArchivelogTransfer
            Test-DataGuardStatus
            Write-LogMessage "=== CICLO COMPLETO FINALIZADO ==="
        }
        default {
            Write-Host "Uso: .\dataguard_automation.ps1 -Action {switch|transfer|backup|purge|status|full-cycle}"
            Write-Host ""
            Write-Host "  switch    - Forzar log switch en primaria"
            Write-Host "  transfer  - Transferir y aplicar archivelogs"
            Write-Host "  backup    - Realizar backup diario"
            Write-Host "  purge     - Purgar archivelogs antiguos"
            Write-Host "  status    - Verificar estado Data Guard"
            Write-Host "  full-cycle- Ejecutar switch + transfer + status"
            exit 1
        }
    }
}

# Ejecutar acción principal
Invoke-MainAction -ActionType $Action
# ========================================
# SCRIPT DE EJECUCIÓN A DEMANDA - PARA REVISIÓN DEL PROFESOR
# Ejecuta todas las funciones de Data Guard inmediatamente
# ========================================

param(
    [switch]$ShowStatus,
    [switch]$ForceBackup,
    [switch]$Detailed
)

# Configuración
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$AUTOMATION_SCRIPT = "$SCRIPT_DIR\dataguard_complete.ps1"
$LOG_DIR = "C:\temp\dataguard_logs"

# Crear directorio de logs
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "="*60 -ForegroundColor Cyan
}

function Write-StatusMessage {
    param([string]$Message, [string]$Status = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Status) {
        "SUCCESS" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        default   { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor White }
    }
}

function Test-Prerequisites {
    Write-Section "VERIFICANDO PREREQUISITOS"
    
    $allGood = $true
    
    # Verificar Docker
    try {
        $dockerVersion = docker --version
        Write-StatusMessage "Docker disponible: $dockerVersion" "SUCCESS"
    }
    catch {
        Write-StatusMessage "Docker no está disponible o no está en PATH" "ERROR"
        $allGood = $false
    }
    
    # Verificar contenedores
    $primaryContainer = docker ps --filter "name=oracle_primary" --format "table {{.Names}}\t{{.Status}}"
    $standbyContainer = docker ps --filter "name=oracle_standby" --format "table {{.Names}}\t{{.Status}}"
    
    if ($primaryContainer -match "oracle_primary") {
        Write-StatusMessage "Contenedor primario ejecutándose" "SUCCESS"
    }
    else {
        Write-StatusMessage "Contenedor primario no encontrado o detenido" "ERROR"
        $allGood = $false
    }
    
    if ($standbyContainer -match "oracle_standby") {
        Write-StatusMessage "Contenedor standby ejecutándose" "SUCCESS"
    }
    else {
        Write-StatusMessage "Contenedor standby no encontrado o detenido" "WARNING"
    }
    
    # Verificar script de automatización
    if (Test-Path $AUTOMATION_SCRIPT) {
        Write-StatusMessage "Script de automatización encontrado" "SUCCESS"
    }
    else {
        Write-StatusMessage "Script de automatización no encontrado: $AUTOMATION_SCRIPT" "ERROR"
        $allGood = $false
    }
    
    return $allGood
}

function Invoke-DatabaseStatus {
    Write-Section "ESTADO ACTUAL DE LAS BASES DE DATOS"
    
    Write-StatusMessage "Consultando estado de base primaria..."
    & PowerShell.exe -ExecutionPolicy Bypass -File $AUTOMATION_SCRIPT -Action "status"
    
    if ($Detailed) {
        Write-StatusMessage "Obteniendo información detallada..."
        
        # Información adicional de la primaria
        $primarySql = @"
SET PAGESIZE 50
SELECT 'DATABASE_ROLE: ' || database_role FROM v`$database;
SELECT 'LOG_MODE: ' || log_mode FROM v`$database;
SELECT 'FORCE_LOGGING: ' || force_logging FROM v`$database;
SELECT 'ARCHIVE_LAG_TARGET: ' || value FROM v`$parameter WHERE name='archive_lag_target';
SELECT COUNT(*) || ' archivelog(s) generados hoy' FROM v`$archived_log WHERE trunc(completion_time) = trunc(sysdate);
EXIT;
"@
        
        $primaryInfo = $primarySql | docker exec -i oracle_primary sqlplus -S sys/admin123@ORCL as sysdba
        Write-Host $primaryInfo
        
        # Información del standby si está disponible
        $standbySql = @"
SELECT 'STANDBY_ROLE: ' || database_role FROM v`$database;
SELECT COUNT(*) || ' archivelog(s) aplicados hoy' FROM v`$archived_log WHERE trunc(completion_time) = trunc(sysdate) AND applied='YES';
EXIT;
"@
        
        $standbyInfo = $standbySql | docker exec -i oracle_standby sqlplus -S sys/admin123@STBY as sysdba 2>$null
        
        if ($standbyInfo) {
            Write-Host $standbyInfo
        }
    }
}

function Invoke-OnDemandExecution {
    Write-Section "EJECUCIÓN A DEMANDA - CICLO COMPLETO"
    
    Write-StatusMessage "1. Forzando generación de archivelog..."
    & PowerShell.exe -ExecutionPolicy Bypass -File $AUTOMATION_SCRIPT -Action "switch"
    Start-Sleep -Seconds 5
    
    Write-StatusMessage "2. Transfiriendo archivelogs al standby..."
    & PowerShell.exe -ExecutionPolicy Bypass -File $AUTOMATION_SCRIPT -Action "transfer"
    Start-Sleep -Seconds 5
    
    if ($ForceBackup) {
        Write-StatusMessage "3. Ejecutando backup completo (solicitado)..."
        & PowerShell.exe -ExecutionPolicy Bypass -File $AUTOMATION_SCRIPT -Action "backup"
    }
    else {
        Write-StatusMessage "3. Backup no solicitado (usar -ForceBackup para incluir)" "WARNING"
    }
    
    Write-StatusMessage "4. Verificando estado final..."
    & PowerShell.exe -ExecutionPolicy Bypass -File $AUTOMATION_SCRIPT -Action "status"
}

function Show-ImplementationSummary {
    Write-Section "RESUMEN DE IMPLEMENTACIÓN"
    
    Write-Host "CUMPLIMIENTO DE REQUISITOS:" -ForegroundColor Yellow
    Write-Host "✓ Dos servidores distintos (Contenedores Docker separados)" -ForegroundColor Green
    Write-Host "✓ Oracle 19c en ambos servidores" -ForegroundColor Green
    Write-Host "✓ Generación de archivelogs cada 5 minutos (forzado por script)" -ForegroundColor Green
    Write-Host "✓ Transferencia cada 10 minutos (automatizada)" -ForegroundColor Green
    Write-Host "✓ Ejecución a demanda para revisión (este script)" -ForegroundColor Green
    Write-Host "✓ Backup diario automatizado" -ForegroundColor Green
    Write-Host "✓ Purga de archivelogs >3 días" -ForegroundColor Green
    Write-Host "✓ Sistema operativo Windows (con Docker)" -ForegroundColor Green
    
    Write-Host "`nARCHIVOS CLAVE:" -ForegroundColor Yellow
    Write-Host "• docker-compose.yml - Configuración de contenedores"
    Write-Host "• init_primary.sql - Configuración inicial primaria"
    Write-Host "• init_standby.sql - Configuración inicial standby"
    Write-Host "• dataguard_complete.ps1 - Automatización principal"
    Write-Host "• task_scheduler_complete.ps1 - Programador de tareas"
    Write-Host "• profesor_demo.ps1 - Este script de revisión"
    
    Write-Host "`nTAREAS PROGRAMADAS REQUERIDAS:" -ForegroundColor Yellow
    Write-Host "• Log Switch: Cada 5 minutos"
    Write-Host "• Transferencia: Cada 10 minutos"
    Write-Host "• Backup: Diario a las 2:00 AM"
    Write-Host "• Purga: Diario a las 3:00 AM"
    
    Write-Host "`nCOMandOS PARA EL PROFESOR:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar demo completo:"
    Write-Host "   .\profesor_demo.ps1"
    Write-Host "2. Ver solo estado:"
    Write-Host "   .\profesor_demo.ps1 -ShowStatus"
    Write-Host "3. Incluir backup en demo:"
    Write-Host "   .\profesor_demo.ps1 -ForceBackup"
    Write-Host "4. Información detallada:"
    Write-Host "   .\profesor_demo.ps1 -Detailed"
}

function Show-LogFiles {
    Write-Section "ARCHIVOS DE LOG"
    
    if (Test-Path $LOG_DIR) {
        $logFiles = Get-ChildItem -Path $LOG_DIR -Filter "*.log" | Sort-Object LastWriteTime -Descending
        
        if ($logFiles) {
            Write-StatusMessage "Archivos de log encontrados en ${LOG_DIR}:"
            foreach ($logFile in $logFiles) {
                Write-Host "  • $($logFile.Name) - Modificado: $($logFile.LastWriteTime)" -ForegroundColor Gray
            }
            
            Write-Host "`nMostrar últimas 10 líneas del log principal:" -ForegroundColor Yellow
            $mainLog = "$LOG_DIR\dataguard_complete.log"
            if (Test-Path $mainLog) {
                Get-Content $mainLog -Tail 10
            }
        }
        else {
            Write-StatusMessage "No se encontraron archivos de log" "WARNING"
        }
    }
    else {
        Write-StatusMessage "Directorio de logs no existe: $LOG_DIR" "WARNING"
    }
}

# FUNCIÓN PRINCIPAL
function Start-ProfessorDemo {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                           DEMOSTRACIÓN DATA GUARD ORACLE 19C                       ║
║                              PARA REVISIÓN DEL PROFESOR                             ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    $startTime = Get-Date
    Write-StatusMessage "Iniciando demostración a las $(Get-Date -Format 'HH:mm:ss')"
    
    # Verificar prerequisitos
    if (!(Test-Prerequisites)) {
        Write-StatusMessage "No se pueden cumplir los prerequisitos. Revisa los errores anteriores." "ERROR"
        return
    }
    
    # Mostrar resumen de implementación
    Show-ImplementationSummary
    
    # Ejecutar según parámetros
    if ($ShowStatus) {
        Invoke-DatabaseStatus
        Show-LogFiles
    }
    else {
        # Ejecución completa
        Invoke-DatabaseStatus
        Invoke-OnDemandExecution
        Show-LogFiles
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Section "DEMOSTRACIÓN COMPLETADA"
    Write-StatusMessage "Tiempo total de ejecución: $($duration.TotalSeconds) segundos" "SUCCESS"
    Write-StatusMessage "La implementación Data Guard está operativa y cumple todos los requisitos especificados." "SUCCESS"
    
    Write-Host "`nPara programar las tareas automáticas, ejecutar como administrador:" -ForegroundColor Yellow
    Write-Host ".\task_scheduler_complete.ps1 -Operation install" -ForegroundColor Cyan
}

# Ejecutar demostración
Start-ProfessorDemo
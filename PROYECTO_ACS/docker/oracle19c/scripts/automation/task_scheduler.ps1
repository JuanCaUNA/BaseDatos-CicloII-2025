# ========================================
# PROGRAMADOR DE TAREAS DATA GUARD - WINDOWS
# Configura tareas programadas para cumplir requisitos
# ========================================

# Configuración de rutas
$SCRIPT_DIR = "c:\Users\esteb\OneDrive\Escritorio\BaseDatos-CicloII-2025\PROYECTO_ACS\docker\oracle19c\scripts\automation"
$AUTOMATION_SCRIPT = "$SCRIPT_DIR\dataguard_automation.ps1"

# Función para crear tarea programada
function New-DataGuardTask {
    param(
        [string]$TaskName,
        [string]$Action,
        [string]$Schedule,
        [string]$Description
    )
    
    Write-Host "Creando tarea programada: $TaskName"
    
    # Eliminar tarea existente si existe
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Tarea existente eliminada: $TaskName"
    }
    
    # Crear nueva tarea
    $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$AUTOMATION_SCRIPT`" -Action $Action"
    
    switch ($Schedule) {
        "Every5Minutes" {
            $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
        }
        "Every10Minutes" {
            $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 365)
        }
        "Daily2AM" {
            $taskTrigger = New-ScheduledTaskTrigger -Daily -At "02:00"
        }
        "Daily3AM" {
            $taskTrigger = New-ScheduledTaskTrigger -Daily -At "03:00"
        }
        default {
            Write-Error "Horario no reconocido: $Schedule"
            return
        }
    }
    
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $taskPrincipal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount
    
    Register-ScheduledTask -TaskName $TaskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Description $Description
    
    Write-Host "Tarea creada exitosamente: $TaskName"
}

# Función para eliminar todas las tareas de Data Guard
function Remove-DataGuardTasks {
    $taskNames = @(
        "DataGuard-LogSwitch",
        "DataGuard-Transfer", 
        "DataGuard-DailyBackup",
        "DataGuard-PurgeOld"
    )
    
    foreach ($taskName in $taskNames) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Host "Tarea eliminada: $taskName"
        }
    }
}

# Función para mostrar estado de tareas
function Show-DataGuardTasks {
    $taskNames = @(
        "DataGuard-LogSwitch",
        "DataGuard-Transfer", 
        "DataGuard-DailyBackup",
        "DataGuard-PurgeOld"
    )
    
    Write-Host "`n=== ESTADO DE TAREAS DATA GUARD ===" -ForegroundColor Green
    
    foreach ($taskName in $taskNames) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            $info = Get-ScheduledTaskInfo -TaskName $taskName
            Write-Host "✓ $taskName - Estado: $($task.State) - Última ejecución: $($info.LastRunTime)" -ForegroundColor Green
        }
        else {
            Write-Host "✗ $taskName - NO CONFIGURADA" -ForegroundColor Red
        }
    }
}

# Función principal
function Invoke-TaskScheduler {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("install", "uninstall", "status", "test")]
        [string]$Operation
    )
    
    switch ($Operation) {
        "install" {
            Write-Host "=== INSTALANDO TAREAS PROGRAMADAS DATA GUARD ===" -ForegroundColor Yellow
            
            # Verificar que el script de automatización existe
            if (!(Test-Path $AUTOMATION_SCRIPT)) {
                Write-Error "Script de automatización no encontrado en: $AUTOMATION_SCRIPT"
                Write-Host "Asegúrate de que el archivo dataguard_automation.ps1 existe en la ruta especificada."
                return
            }
            
            # Crear tareas según los requisitos
            New-DataGuardTask -TaskName "DataGuard-LogSwitch" -Action "switch" -Schedule "Every5Minutes" -Description "Fuerza log switch cada 5 minutos para generar archivelogs"
            
            New-DataGuardTask -TaskName "DataGuard-Transfer" -Action "transfer" -Schedule "Every10Minutes" -Description "Transfiere archivelogs al standby cada 10 minutos"
            
            New-DataGuardTask -TaskName "DataGuard-DailyBackup" -Action "backup" -Schedule "Daily2AM" -Description "Backup diario a las 2:00 AM"
            
            New-DataGuardTask -TaskName "DataGuard-PurgeOld" -Action "purge" -Schedule "Daily3AM" -Description "Purga archivelogs antiguos (>3 días) a las 3:00 AM"
            
            Write-Host "`n=== INSTALACIÓN COMPLETADA ===" -ForegroundColor Green
            Write-Host "Las siguientes tareas han sido programadas:"
            Write-Host "• Log Switch: Cada 5 minutos"
            Write-Host "• Transferencia: Cada 10 minutos" 
            Write-Host "• Backup diario: 2:00 AM"
            Write-Host "• Purga: 3:00 AM"
            Write-Host "`nPuedes verificar las tareas en el Programador de tareas de Windows o ejecutando:"
            Write-Host ".\task_scheduler.ps1 -Operation status" -ForegroundColor Cyan
        }
        
        "uninstall" {
            Write-Host "=== DESINSTALANDO TAREAS PROGRAMADAS DATA GUARD ===" -ForegroundColor Yellow
            Remove-DataGuardTasks
            Write-Host "Todas las tareas Data Guard han sido eliminadas." -ForegroundColor Green
        }
        
        "status" {
            Show-DataGuardTasks
        }
        
        "test" {
            Write-Host "=== EJECUTANDO PRUEBA DE CICLO COMPLETO ===" -ForegroundColor Yellow
            
            if (Test-Path $AUTOMATION_SCRIPT) {
                & PowerShell.exe -ExecutionPolicy Bypass -File $AUTOMATION_SCRIPT -Action "full-cycle"
            }
            else {
                Write-Error "Script de automatización no encontrado: $AUTOMATION_SCRIPT"
            }
        }
        
        default {
            Write-Host "Uso: .\task_scheduler.ps1 -Operation {install|uninstall|status|test}"
            Write-Host ""
            Write-Host "  install   - Instalar todas las tareas programadas"
            Write-Host "  uninstall - Eliminar todas las tareas programadas"
            Write-Host "  status    - Mostrar estado de las tareas"
            Write-Host "  test      - Ejecutar prueba de ciclo completo"
        }
    }
}

# Verificar si se está ejecutando como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script debe ejecutarse como Administrador para crear tareas programadas."
    Write-Host "Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'" -ForegroundColor Yellow
    exit 1
}

# Mostrar menú si no se proporciona parámetro
if ($args.Length -eq 0) {
    Write-Host "=== PROGRAMADOR DE TAREAS DATA GUARD ===" -ForegroundColor Cyan
    Write-Host "Selecciona una opción:"
    Write-Host "1. Instalar tareas programadas"
    Write-Host "2. Desinstalar tareas programadas"
    Write-Host "3. Ver estado de tareas"
    Write-Host "4. Ejecutar prueba"
    Write-Host "5. Salir"
    
    $choice = Read-Host "Ingresa tu opción (1-5)"
    
    switch ($choice) {
        "1" { Invoke-TaskScheduler -Operation "install" }
        "2" { Invoke-TaskScheduler -Operation "uninstall" }
        "3" { Invoke-TaskScheduler -Operation "status" }
        "4" { Invoke-TaskScheduler -Operation "test" }
        "5" { exit 0 }
        default { 
            Write-Host "Opción inválida. Usa: .\task_scheduler.ps1 -Operation {install|uninstall|status|test}" -ForegroundColor Red
            exit 1 
        }
    }
}
else {
    # Ejecutar con parámetros de línea de comandos
    Invoke-TaskScheduler @args
}
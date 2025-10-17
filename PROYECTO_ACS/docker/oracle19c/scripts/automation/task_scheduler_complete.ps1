# ========================================
# SCRIPT DE CONFIGURACIÓN TAREAS PROGRAMADAS
# Automatización Data Guard según requisitos
# ========================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "remove", "status")]
    [string]$Operation
)

$SCRIPT_PATH = $PSScriptRoot
$AUTOMATION_SCRIPT = Join-Path $SCRIPT_PATH "dataguard_complete.ps1"

function Install-ScheduledTasks {
    Write-Host "🔧 Instalando tareas programadas Data Guard..." -ForegroundColor Cyan
    
    # ========================================
    # TAREA 1: SWITCH LOGFILE cada 5 minutos
    # ========================================
    $switch_action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$AUTOMATION_SCRIPT`" -Action switch"
    $switch_trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
    $switch_settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "DataGuard_SwitchLogFile" -Action $switch_action -Trigger $switch_trigger -Settings $switch_settings -Description "Genera archivelog cada 5 minutos" -Force
    Write-Host "✅ Tarea Switch LogFile configurada (cada 5 minutos)" -ForegroundColor Green
    
    # ========================================
    # TAREA 2: TRANSFER LOGS cada 10 minutos
    # ========================================
    $transfer_action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$AUTOMATION_SCRIPT`" -Action transfer"
    $transfer_trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 365)
    $transfer_settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "DataGuard_TransferLogs" -Action $transfer_action -Trigger $transfer_trigger -Settings $transfer_settings -Description "Transfiere logs cada 10 minutos" -Force
    Write-Host "✅ Tarea Transfer Logs configurada (cada 10 minutos)" -ForegroundColor Green
    
    # ========================================
    # TAREA 3: BACKUP DIARIO a las 2:00 AM
    # ========================================
    $backup_action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$AUTOMATION_SCRIPT`" -Action backup"
    $backup_trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
    $backup_settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "DataGuard_DailyBackup" -Action $backup_action -Trigger $backup_trigger -Settings $backup_settings -Description "Backup diario de la base de datos" -Force
    Write-Host "✅ Tarea Backup Diario configurada (2:00 AM)" -ForegroundColor Green
    
    # ========================================
    # TAREA 4: PURGA cada día a las 3:00 AM
    # ========================================
    $purge_action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$AUTOMATION_SCRIPT`" -Action purge"
    $purge_trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
    $purge_settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "DataGuard_PurgeOldFiles" -Action $purge_action -Trigger $purge_trigger -Settings $purge_settings -Description "Purga archivos antiguos (>3 días)" -Force
    Write-Host "✅ Tarea Purga Archivos configurada (3:00 AM)" -ForegroundColor Green
    
    Write-Host "`n🎯 TODAS LAS TAREAS INSTALADAS EXITOSAMENTE" -ForegroundColor Green
}

function Remove-ScheduledTasks {
    Write-Host "🗑️ Removiendo tareas programadas Data Guard..." -ForegroundColor Yellow
    
    $tasks = @("DataGuard_SwitchLogFile", "DataGuard_TransferLogs", "DataGuard_DailyBackup", "DataGuard_PurgeOldFiles")
    
    foreach ($task in $tasks) {
        try {
            Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction Stop
            Write-Host "✅ Tarea removida: $task" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️ Tarea no encontrada: $task" -ForegroundColor Yellow
        }
    }
}

function Show-TaskStatus {
    Write-Host "📊 ESTADO DE TAREAS DATA GUARD" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    $tasks = @("DataGuard_SwitchLogFile", "DataGuard_TransferLogs", "DataGuard_DailyBackup", "DataGuard_PurgeOldFiles")
    
    foreach ($task in $tasks) {
        try {
            $taskInfo = Get-ScheduledTask -TaskName $task -ErrorAction Stop
            $lastRun = (Get-ScheduledTaskInfo -TaskName $task).LastRunTime
            $nextRun = (Get-ScheduledTaskInfo -TaskName $task).NextRunTime
            
            Write-Host "`n📋 $task" -ForegroundColor Yellow
            Write-Host "   Estado: $($taskInfo.State)" -ForegroundColor Green
            Write-Host "   Última ejecución: $lastRun" -ForegroundColor Gray
            Write-Host "   Próxima ejecución: $nextRun" -ForegroundColor Gray
        }
        catch {
            Write-Host "`n❌ $task - NO INSTALADA" -ForegroundColor Red
        }
    }
    
    Write-Host "`n================================" -ForegroundColor Cyan
}

# ========================================
# MAIN EXECUTION
# ========================================

Write-Host "🚀 CONFIGURADOR DE TAREAS DATA GUARD" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Verificar que se ejecuta como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ ESTE SCRIPT REQUIERE PERMISOS DE ADMINISTRADOR" -ForegroundColor Red
    Write-Host "   Ejecute PowerShell como Administrador e intente nuevamente" -ForegroundColor Yellow
    exit 1
}

switch ($Operation) {
    "install" {
        Write-Host "📅 Instalando automatización completa..." -ForegroundColor Green
        Install-ScheduledTasks
        
        Write-Host "`n📋 RESUMEN DE INSTALACIÓN:" -ForegroundColor Cyan
        Write-Host "✅ Switch LogFile: Cada 5 minutos" -ForegroundColor Green
        Write-Host "✅ Transfer Logs: Cada 10 minutos" -ForegroundColor Green  
        Write-Host "✅ Backup Diario: 2:00 AM" -ForegroundColor Green
        Write-Host "✅ Purga Archivos: 3:00 AM" -ForegroundColor Green
    }
    
    "remove" {
        Remove-ScheduledTasks
        Write-Host "`n✅ Todas las tareas han sido removidas" -ForegroundColor Green
    }
    
    "status" {
        Show-TaskStatus
    }
    
    default {
        Write-Host "❌ Operación no válida: $Operation" -ForegroundColor Red
        Write-Host "Uso: .\task_scheduler_complete.ps1 -Operation [install|remove|status]" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 OPERACIÓN COMPLETADA: $Operation" -ForegroundColor Green
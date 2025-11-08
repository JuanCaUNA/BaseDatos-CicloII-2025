# Script para monitorear el progreso de instalación de Oracle
# Uso: .\monitor_oracle_setup.ps1

Write-Host "=== MONITOR DE INSTALACIÓN ORACLE DATA GUARD ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

$ORACLE_PWD = "admin123"

function Invoke-ContainerSql {
    param(
        [string]$Container,
        [string]$SqlCommand,
        [string]$DbService
    )

    $sqlBlock = @"
sqlplus -s sys/$ORACLE_PWD@//$DbService as sysdba <<'SQL'
SET HEADING OFF;
SET FEEDBACK OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET PAGESIZE 0;
SET LINESIZE 32767;
$SqlCommand
EXIT;
SQL
"@

    $sqlBlock = ($sqlBlock -replace "`r", "")

    try {
        $result = docker exec $Container bash -lc $sqlBlock
        if ($null -eq $result) {
            return $null
        }

        return $result.Trim()
    }
    catch {
        Write-Host ("Error ejecutando SQL en {0}: {1}" -f $Container, $_) -ForegroundColor Red
        return $null
    }
}

# Función para verificar estado de contenedores
function Test-ContainerStatus {
    Write-Host "=== ESTADO DE CONTENEDORES ===" -ForegroundColor Green
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host ""
}

# Función para verificar logs de instalación
function Get-InstallationProgress {
    param([string]$ContainerName)
    
    Write-Host "=== PROGRESO DE INSTALACIÓN: $ContainerName ===" -ForegroundColor Green
    $logs = docker logs $ContainerName --tail 5 2>$null
    if ($logs) {
        $logs | ForEach-Object {
            if ($_ -match "(\d+)% complete") {
                Write-Host $_ -ForegroundColor Yellow
            }
            elseif ($_ -match "DATABASE IS READY TO USE") {
                Write-Host $_ -ForegroundColor Green
            }
            elseif ($_ -match "ERROR|FATAL|FAIL") {
                Write-Host $_ -ForegroundColor Red
            }
            else {
                Write-Host $_
            }
        }
    }
    else {
        Write-Host "No hay logs disponibles para $ContainerName" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Función para probar conectividad SQL
function Test-DatabaseConnection {
    param([string]$ContainerName, [string]$ConnectionString)
    
    Write-Host "=== PRUEBA DE CONEXIÓN: $ContainerName ===" -ForegroundColor Green
    
    $testSql = "SELECT 'DB_READY' AS status FROM dual;"
    $result = Invoke-ContainerSql -Container $ContainerName -SqlCommand $testSql -DbService "localhost:1521/$ConnectionString"

    if ($result -and ($result -match "DB_READY")) {
        Write-Host "✅ Base de datos $ContainerName está lista y responde" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "⏳ Base de datos $ContainerName aún no está lista" -ForegroundColor Yellow
        return $false
    }
}

# Loop principal de monitoreo
$maxWaitMinutes = 30
$waitInterval = 30
$startTime = Get-Date

Write-Host "Monitoreando instalación por hasta $maxWaitMinutes minutos..." -ForegroundColor Cyan
Write-Host "Intervalo de verificación: $waitInterval segundos" -ForegroundColor Cyan
Write-Host ""

do {
    $currentTime = Get-Date
    $elapsedMinutes = [math]::Round(($currentTime - $startTime).TotalMinutes, 1)
    
    Write-Host "--- Tiempo transcurrido: $elapsedMinutes minutos ---" -ForegroundColor Magenta
    
    # Verificar estado de contenedores
    Test-ContainerStatus
    
    # Verificar progreso de instalación
    Get-InstallationProgress -ContainerName "oracle_primary"
    Get-InstallationProgress -ContainerName "oracle_standby"
    
    # Probar conectividad
    $primaryReady = Test-DatabaseConnection -ContainerName "oracle_primary" -ConnectionString "ORCL"
    $standbyReady = Test-DatabaseConnection -ContainerName "oracle_standby" -ConnectionString "STBY"
    
    if ($primaryReady -and $standbyReady) {
        Write-Host "🎉 ¡AMBAS BASES DE DATOS ESTÁN LISTAS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Próximos pasos:" -ForegroundColor Cyan
        Write-Host "1. Ejecutar scripts de configuración Data Guard"
        Write-Host "2. Instalar tareas programadas"
        Write-Host "3. Ejecutar demostración"
        Write-Host ""
        Write-Host "Comandos sugeridos:" -ForegroundColor Yellow
    Write-Host "cd docker\oracle19c\scripts\automation"
        Write-Host ".\dataguard_complete.ps1 -Action status"
        Write-Host ".\task_scheduler_complete.ps1 -Operation install"
        break
    }
    
    if ($elapsedMinutes -ge $maxWaitMinutes) {
        Write-Host "⚠️ TIEMPO DE ESPERA AGOTADO" -ForegroundColor Red
        Write-Host "Las bases de datos pueden necesitar más tiempo para completar la instalación."
        Write-Host "Revisa los logs manualmente con: docker logs oracle_primary"
        break
    }
    
    Write-Host "Esperando $waitInterval segundos antes de la siguiente verificación..." -ForegroundColor Gray
    Start-Sleep -Seconds $waitInterval
    Clear-Host
    
} while ($true)

Write-Host ""
Write-Host "=== MONITOREO COMPLETADO ===" -ForegroundColor Cyan
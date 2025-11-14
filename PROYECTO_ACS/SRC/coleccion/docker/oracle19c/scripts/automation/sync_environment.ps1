# ========================================
# DATA GUARD - SINCRONIZACION DE ENTORNO LOCAL
# Objetivo: preparar carpetas ignoradas por git y copiar archivos base
# ========================================

$scriptRoot = $PSScriptRoot
$oracleRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent
$stackRoot = Split-Path $oracleRoot -Parent

# Allow overrides via environment variables so users can place data on absolute paths (avoid OneDrive)
$envShared = $env:ORACLE_SHARED
$envPrimary = $env:ORADATA_PRIMARY
$envStandby = $env:ORADATA_STANDBY

# Detectar si docker-compose está configurado para usar named volumes por defecto.
$composeFile = Join-Path $stackRoot 'docker-compose.yml'
$composeText = ''
if (Test-Path -LiteralPath $composeFile) {
    try { $composeText = Get-Content -Raw -LiteralPath $composeFile -ErrorAction SilentlyContinue } catch { $composeText = '' }
}
$usesNamedVolumes = $false
if (-not [string]::IsNullOrWhiteSpace($composeText)) {
    if ($composeText -match 'oradata_primary_volume' -or $composeText -match 'oradata_standby_volume' -or $composeText -match 'oracle_shared_volume') {
        $usesNamedVolumes = $true
    }
}

# Si se usan named volumes y NO hay overrides absolutos, NO crear carpetas repo-local
$absoluteOverridesProvided = -not ([string]::IsNullOrWhiteSpace($envShared) -and [string]::IsNullOrWhiteSpace($envPrimary) -and [string]::IsNullOrWhiteSpace($envStandby))
$shouldCreateRepoLocal = -not ($usesNamedVolumes -and -not $absoluteOverridesProvided)

# If env vars are set and non-empty, use them; otherwise fall back to repo-local folders
if (-not [string]::IsNullOrWhiteSpace($envShared)) { $sharedPath = $envShared } else { $sharedPath = Join-Path $stackRoot "shared" }
if (-not [string]::IsNullOrWhiteSpace($envPrimary)) { $primaryPath = $envPrimary } else { $primaryPath = Join-Path $stackRoot "oradata_primary" }
if (-not [string]::IsNullOrWhiteSpace($envStandby)) { $standbyPath = $envStandby } else { $standbyPath = Join-Path $stackRoot "oradata_standby" }
$logsPath = Join-Path $sharedPath "logs"
$statePath = Join-Path $sharedPath "state"
$backupsPath = Join-Path $sharedPath "backups"

$configRoot = Join-Path $oracleRoot "config"
$tnsSource = Join-Path $configRoot "tnsnames_unified.ora"
$tnsTarget = Join-Path $sharedPath "tnsnames_unified.ora"
$tnsPrimaryConfig = Join-Path $primaryPath "dbconfig"
$tnsStandbyConfig = Join-Path $standbyPath "dbconfig"
$tnsPrimary = Join-Path $tnsPrimaryConfig "ORCL"
$tnsStandby = Join-Path $tnsStandbyConfig "STBY"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " PREPARACION DEL ENTORNO LOCAL DATA GUARD" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "-------------------------------------------------" -ForegroundColor Gray
Write-Host "Este asistente crea las carpetas ignoradas por git y copia el archivo tnsnames." -ForegroundColor Gray
Write-Host "No necesitas conocimientos previos: solo revisa los mensajes 'OK' o 'WARN'." -ForegroundColor Gray
Write-Host "Carpeta base detectada: $stackRoot" -ForegroundColor Gray
Write-Host "-------------------------------------------------" -ForegroundColor Gray

# Crear carpetas base si no existen (ignora errores si ya existen)
if ($shouldCreateRepoLocal) {
    foreach ($path in @($sharedPath, $primaryPath, $standbyPath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Host "[CREANDO] $path" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
        else { Write-Host "[OK] $path ya existe" -ForegroundColor Green }
    }
}
else {
    Write-Host "[INFO] docker-compose usa named volumes y no hay overrides absolutos: omitiendo creación de carpetas repo-local." -ForegroundColor Gray
}

# Ensure subfolders under shared (logs/state/backups) are created relative to the chosen sharedPath
$logsPath = Join-Path $sharedPath "logs"
$statePath = Join-Path $sharedPath "state"
$backupsPath = Join-Path $sharedPath "backups"
foreach ($path in @($logsPath, $statePath, $backupsPath)) {
    if (-not (Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

# Copiar archivo TNS unificado
if (Test-Path $tnsSource) {
    Write-Host "-------------------------------------------------" -ForegroundColor Yellow
    Write-Host "[INFO] Copiando archivo tnsnames_unified.ora a todas las ubicaciones necesarias..." -ForegroundColor Yellow
    Write-Host "-------------------------------------------------" -ForegroundColor Yellow
    # Sólo copiar a las ubicaciones repo-local si corresponde (creación permitida o overrides absolutos)
    if ($shouldCreateRepoLocal -or $absoluteOverridesProvided) {
        Copy-Item -Path $tnsSource -Destination $tnsTarget -Force

        foreach ($destination in @($tnsPrimaryConfig, $tnsStandbyConfig, $tnsPrimary, $tnsStandby)) {
            if (-not (Test-Path $destination)) {
                Write-Host "[CREANDO] $destination" -ForegroundColor Yellow
                New-Item -ItemType Directory -Path $destination -Force | Out-Null
            }
            else {
                Write-Host "[OK] $destination ya existe" -ForegroundColor Green
            }
        }

        Copy-Item -Path $tnsSource -Destination (Join-Path $tnsPrimary "tnsnames.ora") -Force
        Copy-Item -Path $tnsSource -Destination (Join-Path $tnsStandby "tnsnames.ora") -Force

        Write-Host "[OK] Archivo tnsnames copiado en shared/ y en cada dbconfig/" -ForegroundColor Green
    }
    else {
        Write-Host "[INFO] No se copió tnsnames a carpetas repo-local porque se usan named volumes y no hay overrides absolutos." -ForegroundColor Gray
    }
}
else {
    Write-Host "[WARN] No se encontró el archivo fuente: $tnsSource" -ForegroundColor Red
    Write-Host "       Revisa que exista en docker/oracle19c/config/ antes de volver a ejecutar." -ForegroundColor Red
}
Write-Host "-------------------------------------------------" -ForegroundColor Cyan
Write-Host " Sincronizacion completada. Continua con docker compose up." -ForegroundColor Cyan
Write-Host "-------------------------------------------------" -ForegroundColor Cyan

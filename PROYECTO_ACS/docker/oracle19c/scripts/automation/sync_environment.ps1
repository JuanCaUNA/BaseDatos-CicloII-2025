# ========================================
# DATA GUARD - SINCRONIZACION DE ENTORNO LOCAL
# Objetivo: preparar carpetas ignoradas por git y copiar archivos base
# ========================================

$scriptRoot = $PSScriptRoot
$oracleRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent
$stackRoot = Split-Path $oracleRoot -Parent

$dataRoot = Join-Path $stackRoot "data"
$sharedPath = Join-Path $dataRoot "shared"
$primaryPath = Join-Path $dataRoot "primary"
$standbyPath = Join-Path $dataRoot "standby"

$configRoot = Join-Path $oracleRoot "config"
$tnsSource = Join-Path $configRoot "tnsnames_unified.ora"
$tnsTarget = Join-Path $sharedPath "tnsnames_unified.ora"
$tnsPrimaryConfig = Join-Path $primaryPath "dbconfig"
$tnsStandbyConfig = Join-Path $standbyPath "dbconfig"
$tnsPrimary = Join-Path $tnsPrimaryConfig "ORCL"
$tnsStandby = Join-Path $tnsStandbyConfig "STBY"

Write-Host "=== SINCRONIZACION DE ENTORNO DATA GUARD ===" -ForegroundColor Cyan
Write-Host "Raiz del stack: $stackRoot" -ForegroundColor Gray

# Crear carpetas base si no existen (ignora errores si ya existen)
foreach ($path in @($sharedPath, $primaryPath, $standbyPath)) {
    if (-not (Test-Path $path)) {
        Write-Host "Creando carpeta $path" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Copiar archivo TNS unificado
if (Test-Path $tnsSource) {
    Write-Host "Copiando archivo TNS unificado..." -ForegroundColor Yellow
    Copy-Item -Path $tnsSource -Destination $tnsTarget -Force

    foreach ($destination in @($tnsPrimaryConfig, $tnsStandbyConfig, $tnsPrimary, $tnsStandby)) {
        if (-not (Test-Path $destination)) {
            Write-Host "Creando carpeta $destination" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
        }
    }

    Copy-Item -Path $tnsSource -Destination (Join-Path $tnsPrimary "tnsnames.ora") -Force
    Copy-Item -Path $tnsSource -Destination (Join-Path $tnsStandby "tnsnames.ora") -Force

    Write-Host "[OK] Archivo TNS sincronizado en shared/ y dbconfig/" -ForegroundColor Green
}
else {
    Write-Host "[WARN] No se encontro el archivo fuente: $tnsSource" -ForegroundColor Red
}

Write-Host "Sincronizacion completada." -ForegroundColor Cyan

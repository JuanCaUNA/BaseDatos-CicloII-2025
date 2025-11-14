<#[
.SYNOPSIS
    Automatiza la preparación y el despliegue del entorno Oracle Data Guard.

.DESCRIPTION
    Opcionalmente limpia volúmenes locales, sincroniza archivos ignorados por git y
    ejecuta docker compose con manejo consistente de errores.

.PARAMETER ForceCleanup
    Elimina carpetas compartidas locales y contenedores previos antes de desplegar.
#>

[CmdletBinding()]
param (
    [switch]$ForceCleanup
)

$ErrorActionPreference = 'Stop'

function Write-Banner {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Message,

        [Parameter(Position = 1)]
        [Alias('Color', 'ForegroundColor')]
        [ConsoleColor]$TextColor = [ConsoleColor]::Cyan
    )

    Write-Host $Message -ForegroundColor $TextColor
}

function Resolve-ComposeFile {
    param([string]$StartDirectory)

    $current = Get-Item -LiteralPath $StartDirectory
    while ($current) {
        foreach ($candidate in 'docker-compose.yml','docker-compose.yaml') {
            $path = Join-Path $current.FullName $candidate
            if (Test-Path -LiteralPath $path) { return $path }
        }
        $parent = Split-Path $current.FullName -Parent
        if (-not $parent -or $parent -eq $current.FullName) { break }
        $current = Get-Item -LiteralPath $parent
    }
    throw "No se encontró docker-compose.yml al ascender desde $StartDirectory."
}

function Invoke-DockerCommand {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location -LiteralPath $WorkingDirectory
    try {
        Write-Host "docker $($Arguments -join ' ')" -ForegroundColor DarkGray

        $originalPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $output = & docker @Arguments 2>&1
            $code = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $originalPreference
        }

        if ($output) { $output | ForEach-Object { Write-Host $_ -ForegroundColor Gray } }
        if ($code -ne 0) {
            throw "docker $($Arguments -join ' ') finalizó con código $code"
        }
    }
    finally {
        Pop-Location
    }
}

function Ensure-DockerCLI {
    if (-not (Get-Command -Name docker -ErrorAction SilentlyContinue)) {
        throw 'No se encontró el comando docker en el PATH. Instala Docker Desktop o ajusta la variable PATH.'
    }
}

$scriptRoot = $PSScriptRoot
$oracleRoot = Split-Path -Parent $scriptRoot
$stackRoot = Split-Path -Parent $oracleRoot
$composeFile = Resolve-ComposeFile -StartDirectory $oracleRoot
$composeDir = Split-Path -Parent $composeFile
$syncScript = Join-Path $scriptRoot 'sync_environment.ps1'

# Ruta por defecto dentro del repo (se usarán sólo si NO se proveen overrides absolutos)
$sharedPath = Join-Path $stackRoot 'shared'
$primaryPath = Join-Path $stackRoot 'oradata_primary'
$standbyPath = Join-Path $stackRoot 'oradata_standby'

# Incluir overrides absolutos desde variables de entorno (ej: C:\oracle_local\...)
$envPrimary = $env:ORADATA_PRIMARY
$envStandby = $env:ORADATA_STANDBY
$envShared = $env:ORACLE_SHARED

# Si el usuario proporcionó rutas absolutas, operamos únicamente sobre ellas
$useAbsoluteOverrides = -not ([string]::IsNullOrWhiteSpace($envPrimary) -and [string]::IsNullOrWhiteSpace($envStandby) -and [string]::IsNullOrWhiteSpace($envShared))

function Add-SafePath {
    param([string]$candidate)
    if ([string]::IsNullOrWhiteSpace($candidate)) { return }
    $resolved = Resolve-Path -LiteralPath $candidate -ErrorAction SilentlyContinue
    if (-not $resolved) {
        # si no existe aún, normalizamos la ruta sin lanzar error
        try { $resolvedPath = (Get-Item -LiteralPath $candidate -ErrorAction SilentlyContinue).FullName } catch { $resolvedPath = $candidate }
    }
    else { $resolvedPath = $resolved.Path }

    if (-not [string]::IsNullOrWhiteSpace($resolvedPath)) {
        # Safety: evitar borrar raíces (ej. C:\) y rutas muy cortas
        if ($resolvedPath.TrimEnd('\','/').Length -le 3) { return }
        if (-not ($pathsToReview -contains $resolvedPath)) { $pathsToReview += $resolvedPath }
    }
}

if ($useAbsoluteOverrides) {
    $pathsToReview = @()
    # Añadimos las rutas absolutas provistas (si existen)
    Add-SafePath $envShared
    Add-SafePath $envPrimary
    Add-SafePath $envStandby
} else {
    # Detectar si el docker-compose usa named volumes por defecto (evitar crear carpetas repo-local)
    $composeText = ''
    try { $composeText = Get-Content -Raw -LiteralPath $composeFile -ErrorAction SilentlyContinue } catch { $composeText = '' }
    $usesNamedVolumes = $false
    if (-not [string]::IsNullOrWhiteSpace($composeText)) {
        if ($composeText -match 'oradata_primary_volume' -or $composeText -match 'oradata_standby_volume' -or $composeText -match 'oracle_shared_volume') {
            $usesNamedVolumes = $true
        }
    }

    if ($usesNamedVolumes) {
        Write-Host "Detected docker-compose default named volumes; skipping creation of repo-local data folders." -ForegroundColor Gray
        $pathsToReview = @()
    }
    else {
        $pathsToReview = @($sharedPath, $primaryPath, $standbyPath)
    }
}

# env paths are added above when $useAbsoluteOverrides is true; avoid duplicate additions here.

# Detección adicional: incluir rutas comunes fuera del repo que puedan contener datos
# (p.ej. C:\oracle_shared, C:\oracle_local, C:\oracle_local\shared). Esto ayuda a
# detectar y limpiar carpetas que el usuario creó manualmente fuera del árbol del repo.
$commonCandidates = @(
    # Sólo rutas externas específicas que suelen usarse. No incluimos C:\oracle_local
    # para evitar crear una raíz adicional que contenga ya las subcarpetas.
    'C:\oracle_shared'
)
foreach ($cand in $commonCandidates) {
    if (Test-Path -LiteralPath $cand) {
        $resolved = Resolve-Path -LiteralPath $cand -ErrorAction SilentlyContinue
        if ($resolved) { $resolvedPath = $resolved.Path } else { $resolvedPath = $cand }
        if ($resolvedPath.TrimEnd('\','/').Length -gt 3 -and -not ($pathsToReview -contains $resolvedPath)) {
            $pathsToReview += $resolvedPath
        }
    }
}

$stalePaths = @()
foreach ($path in $pathsToReview) {
    if (Test-Path -LiteralPath $path) {
        $entries = Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($entries) {
            $stalePaths += $path
        }
    }
}

Write-Banner '================================================================'
Write-Banner '  DATA GUARD - DESPLIEGUE AUTOMATIZADO'
Write-Banner '================================================================'
Write-Host "Carpeta base detectada: $stackRoot" -ForegroundColor Gray
Write-Host "Archivo docker-compose: $composeFile" -ForegroundColor Gray
Write-Host ''

Ensure-DockerCLI

$shouldCleanup = $ForceCleanup.IsPresent
if (-not $shouldCleanup -and $stalePaths.Count -gt 0) {
    Write-Banner 'Se detectaron datos previos en las carpetas compartidas.' ([ConsoleColor]::Yellow)
    $stalePaths | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    if ($Host.Name -eq 'ConsoleHost') {
        $response = Read-Host '¿Deseas eliminarlos antes de desplegar? (S/N)'
        if ($response -match '^(s|S|y|Y)$') {
            $shouldCleanup = $true
        }
    }

    if (-not $shouldCleanup) {
        Write-Host 'Omitiendo limpieza automática. Puedes ejecutar el script con -ForceCleanup para hacerla en la siguiente corrida.' -ForegroundColor DarkYellow
    }
}

if ($shouldCleanup) {
    Write-Banner '[1/5] Limpieza previa de contenedores y volúmenes' ([ConsoleColor]::Yellow)
    try {
        Invoke-DockerCommand -WorkingDirectory $composeDir -Arguments @('compose','down','--volumes','--remove-orphans')
    }
    catch {
        Write-Host "Aviso durante docker compose down: $_" -ForegroundColor DarkYellow
    }

    function Remove-Path-Safely {
        param([string]$p)
        if (-not (Test-Path -LiteralPath $p)) { return }
        Write-Host "Intentando eliminar $p" -ForegroundColor DarkGray
        try {
            Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
            Write-Host "Eliminado: $p" -ForegroundColor Green
            return
        }
        catch {
            Write-Host "No se pudo eliminar $p directamente: $_. Intentando takeown/icacls..." -ForegroundColor Yellow
            try {
                # Tomar propiedad recursivamente
                & takeown /F "$p" /R /D Y 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
            } catch { Write-Host "takeown falló: $_" -ForegroundColor DarkYellow }
            try {
                # Conceder permisos de control total al usuario que ejecuta el script
                $user = $env:USERNAME
                & icacls "$p" /grant "$($user):(F)" /T 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
            } catch { Write-Host "icacls falló: $_" -ForegroundColor DarkYellow }

            # Reintentar eliminar
            try {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
                Write-Host "Eliminado después de ajustar permisos: $p" -ForegroundColor Green
                return
            }
            catch {
                Write-Host "ERROR: No se pudo eliminar $p tras takeown/icacls: $_" -ForegroundColor Red
                return
            }
        }
    }

    $currentUser = $env:USERNAME
    foreach ($path in $pathsToReview) {
        Remove-Path-Safely -p $path
        Write-Host "Recreando $path" -ForegroundColor Gray
        New-Item -ItemType Directory -Path $path -Force | Out-Null

        # Asegurar ACLs: eliminar posibles DENY heredados para Everyone y dar control total al usuario
        try {
            & icacls "$path" /remove:d Everyone /T 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        } catch { }
        try {
            & icacls "$path" /grant:r "$($currentUser):(F)" /T 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        } catch { }
    }
}

Write-Banner '[2/5] Sincronizando archivos ignorados por git' ([ConsoleColor]::Yellow)
if (-not (Test-Path -LiteralPath $syncScript)) {
    throw "No se encontró el script de sincronización: $syncScript"
}

& $syncScript

# Después de sincronizar la estructura repo-local, replicar la estructura básica
# y el archivo tnsnames_unified.ora en posibles rutas absolutas indicadas
# por las variables ORADATA_* y ORACLE_SHARED para que Docker las monte limpias.
$configTns = Join-Path $stackRoot 'config\tnsnames_unified.ora'
if (Test-Path -LiteralPath $configTns) {
    foreach ($p in $pathsToReview) {
        # Saltar rutas que estén dentro del repo (ya fueron creadas por sync)
        $normalized = (Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue)
        if (-not $normalized) { $target = $p } else { $target = $normalized.Path }
        if ($target -like "$stackRoot*") { continue }

        Write-Host "Preparando estructura en: $target" -ForegroundColor Gray
        # crear subcarpetas comunes
        foreach ($sub in @('logs','state','backups')) {
            $subPath = Join-Path $target $sub
            if (-not (Test-Path -LiteralPath $subPath)) { New-Item -ItemType Directory -Path $subPath -Force | Out-Null }
        }

        # crear dbconfig y copiar tnsnames
        $dbConfig = Join-Path $target 'dbconfig'
        $primaryCfg = Join-Path $dbConfig 'ORCL'
        $standbyCfg = Join-Path $dbConfig 'STBY'
        foreach ($d in @($dbConfig, $primaryCfg, $standbyCfg)) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

        Copy-Item -Path $configTns -Destination (Join-Path $target 'tnsnames_unified.ora') -Force -ErrorAction SilentlyContinue
        Copy-Item -Path $configTns -Destination (Join-Path $primaryCfg 'tnsnames.ora') -Force -ErrorAction SilentlyContinue
        Copy-Item -Path $configTns -Destination (Join-Path $standbyCfg 'tnsnames.ora') -Force -ErrorAction SilentlyContinue
        Write-Host "Estructura y TNS creada en: $target" -ForegroundColor Green
    }
}
else {
    Write-Host "[WARN] No se encontró $configTns; omitiendo copia a rutas absolutas." -ForegroundColor Yellow
}

Write-Banner '[3/5] Deteniendo stack previo' ([ConsoleColor]::Yellow)
try {
    Invoke-DockerCommand -WorkingDirectory $composeDir -Arguments @('compose','down')
}
catch {
    Write-Host "No se detectaron contenedores previos o el comando devolvió un aviso: $_" -ForegroundColor DarkYellow
}

Write-Banner '[4/5] Desplegando stack Data Guard' ([ConsoleColor]::Yellow)
Invoke-DockerCommand -WorkingDirectory $composeDir -Arguments @('compose','up','-d','--remove-orphans')

Write-Banner '[5/5] Estado actual del despliegue' ([ConsoleColor]::Yellow)
Invoke-DockerCommand -WorkingDirectory $composeDir -Arguments @('compose','ps')

Write-Host ''
Write-Banner 'Despliegue completado.' ([ConsoleColor]::Green)
Write-Host 'Próximos pasos recomendados:' -ForegroundColor Gray
Write-Host '  1. Revisa shared/logs para confirmar que los contenedores iniciaron correctamente.' -ForegroundColor Gray
Write-Host '  2. Ejecuta validate_dataguard.sh desde el contenedor primario para validar la réplica.' -ForegroundColor Gray

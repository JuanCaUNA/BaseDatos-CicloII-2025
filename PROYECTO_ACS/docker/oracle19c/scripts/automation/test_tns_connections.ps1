# Script simplificado para probar conexiones TNS principales
Write-Host "=== PRUEBA DE CONEXIONES TNS UNIFICADAS ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== ESTADO DE CONTENEDORES ===" -ForegroundColor Green
docker ps --format "table {{.Names}}`t{{.Status}}"
Write-Host ""

Write-Host "=== PROBANDO CONEXION PRINCIPAL ===" -ForegroundColor Yellow
try {
    $result = docker exec oracle_primary bash -c "echo 'SELECT name FROM v`$database;' | sqlplus -s sys/admin123 as sysdba" 2>$null
    if ($result -match "ORCL") {
        Write-Host "✅ Primary ORCL: Conexion exitosa" -ForegroundColor Green
    } else {
        Write-Host "❌ Primary ORCL: Error de conexion" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Primary ORCL: No disponible" -ForegroundColor Red
}

Write-Host "`n=== PROBANDO CONEXION STANDBY ===" -ForegroundColor Yellow
try {
    $result = docker exec oracle_standby bash -c "echo 'SELECT name FROM v`$database;' | sqlplus -s sys/admin123 as sysdba" 2>$null
    if ($result -match "STBY") {
        Write-Host "✅ Standby STBY: Conexion exitosa" -ForegroundColor Green
    } elseif ($result -match "ORA-01507") {
        Write-Host "⚠️  Standby STBY: Base de datos no montada (normal para standby)" -ForegroundColor Yellow
    } else {
        Write-Host "⏳ Standby STBY: Base de datos no lista" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Standby STBY: No disponible" -ForegroundColor Red
}

Write-Host "`n=== ARCHIVO TNS UNIFICADO ===" -ForegroundColor Cyan
Write-Host "Ubicacion: data\shared\tnsnames_unified.ora"
$primaryTNS = "c:\Users\esteb\OneDrive\Escritorio\BaseDatos-CicloII-2025\PROYECTO_ACS\docker\oracle19c\data\primary\dbconfig\ORCL\tnsnames.ora"
$standbyTNS = "c:\Users\esteb\OneDrive\Escritorio\BaseDatos-CicloII-2025\PROYECTO_ACS\docker\oracle19c\data\standby\dbconfig\STBY\tnsnames.ora"

Write-Host "Copiado a:"
if (Test-Path $primaryTNS) {
    Write-Host "  - data\primary\dbconfig\ORCL\tnsnames.ora" -ForegroundColor Green
} else {
    Write-Host "  - data\primary\dbconfig\ORCL\tnsnames.ora (No encontrado)" -ForegroundColor Red
}

if (Test-Path $standbyTNS) {
    Write-Host "  - data\standby\dbconfig\STBY\tnsnames.ora" -ForegroundColor Green
} else {
    Write-Host "  - data\standby\dbconfig\STBY\tnsnames.ora (No encontrado)" -ForegroundColor Red
}

Write-Host "`n=== CONEXIONES DISPONIBLES ===" -ForegroundColor Cyan
Write-Host "Internas (entre contenedores):" -ForegroundColor Gray
Write-Host "  ORCL - Primary Database" -ForegroundColor Gray
Write-Host "  STBY - Standby Database" -ForegroundColor Gray
Write-Host ""
Write-Host "Externas (desde host):" -ForegroundColor Gray
Write-Host "  ORCL_EXT - Primary via localhost:1523" -ForegroundColor Gray
Write-Host "  STBY_EXT - Standby via localhost:1524" -ForegroundColor Gray
Write-Host ""
Write-Host "Data Guard:" -ForegroundColor Gray
Write-Host "  PRIMARY_DG - Primary para Data Guard" -ForegroundColor Gray
Write-Host "  STANDBY_DG - Standby para Data Guard" -ForegroundColor Gray
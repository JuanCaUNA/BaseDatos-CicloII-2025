# Script simple para probar conexiones TNS
Write-Host "=== PRUEBA DE CONEXIONES TNS UNIFICADAS ===" -ForegroundColor Cyan
Write-Host ""

# Verificar estado de contenedores
Write-Host "=== ESTADO DE CONTENEDORES ===" -ForegroundColor Green
docker ps --format "table {{.Names}}`t{{.Status}}"
Write-Host ""

# Probar conexión principal
Write-Host "=== PROBANDO CONEXION PRINCIPAL ===" -ForegroundColor Yellow
try {
    $result = docker exec oracle_primary bash -c "echo 'SELECT name FROM v`$database;' | sqlplus -S sys/admin123@ORCL as sysdba" 2>$null
    if ($result -match "ORCL") {
        Write-Host "✅ Primary ORCL: Conexion exitosa" -ForegroundColor Green
    } else {
        Write-Host "⏳ Primary ORCL: Base de datos no lista" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Primary ORCL: Error de conexion" -ForegroundColor Red
}

Write-Host ""

# Probar conexión standby
Write-Host "=== PROBANDO CONEXION STANDBY ===" -ForegroundColor Yellow
try {
    $result = docker exec oracle_standby bash -c "echo 'SELECT name FROM v`$database;' | sqlplus -S sys/admin123@STBY as sysdba" 2>$null
    if ($result -match "STBY") {
        Write-Host "✅ Standby STBY: Conexion exitosa" -ForegroundColor Green
    } else {
        Write-Host "⏳ Standby STBY: Base de datos no lista" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Standby STBY: Error de conexion" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== ARCHIVO TNS UNIFICADO ===" -ForegroundColor Cyan
Write-Host "Ubicacion: data\shared\tnsnames_unified.ora"
Write-Host "Copiado a:"
Write-Host "  - data\primary\dbconfig\ORCL\tnsnames.ora"
Write-Host "  - data\standby\dbconfig\STBY\tnsnames.ora"
Write-Host ""

Write-Host "=== CONEXIONES DISPONIBLES ===" -ForegroundColor Cyan
Write-Host "Internas (entre contenedores):"
Write-Host "  ORCL - Primary Database"
Write-Host "  STBY - Standby Database"
Write-Host ""
Write-Host "Externas (desde host):"
Write-Host "  ORCL_EXT - Primary via localhost:1523"
Write-Host "  STBY_EXT - Standby via localhost:1524"
Write-Host ""
Write-Host "Data Guard:"
Write-Host "  PRIMARY_DG - Primary para Data Guard"
Write-Host "  STANDBY_DG - Standby para Data Guard"
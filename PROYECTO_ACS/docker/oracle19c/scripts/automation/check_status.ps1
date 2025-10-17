# Script simplificado para verificar estado de Oracle
Write-Host "=== VERIFICACION DE ESTADO ORACLE DATA GUARD ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

# Verificar contenedores
Write-Host "=== ESTADO DE CONTENEDORES ===" -ForegroundColor Green
docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
Write-Host ""

# Verificar logs recientes
Write-Host "=== LOGS PRIMARIA (ultimas 10 lineas) ===" -ForegroundColor Green
docker logs oracle_primary --tail 10
Write-Host ""

Write-Host "=== LOGS STANDBY (ultimas 10 lineas) ===" -ForegroundColor Green
docker logs oracle_standby --tail 10
Write-Host ""

# Prueba de conexion simple
Write-Host "=== PRUEBA DE CONEXION ===" -ForegroundColor Green
Write-Host "Probando conexion a primaria..."

try {
    $result = docker exec oracle_primary bash -c "echo 'SELECT name FROM v`$database;' | sqlplus -S sys/admin123@ORCL as sysdba"
    if ($result -match "ORCL") {
        Write-Host "✅ Primaria esta lista y responde" -ForegroundColor Green
    } else {
        Write-Host "⏳ Primaria aun no esta lista" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error conectando a primaria" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== INFORMACION DE PUERTOS ===" -ForegroundColor Cyan
Write-Host "Primary Database: localhost:1523"
Write-Host "Standby Database: localhost:1524"
Write-Host "Primary EM: http://localhost:8080/em"
Write-Host "Standby EM: http://localhost:8081/em"
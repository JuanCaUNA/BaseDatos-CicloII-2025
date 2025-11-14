# ========================================
# DATA GUARD - FAILOVER DE EMERGENCIA
# Activa Standby como Primary cuando el Primary falló
# ========================================
# ⚠️  IMPORTANTE: Solo usar cuando Primary NO está disponible
# Para cambios planificados usar switchover_dataguard.ps1

param(
    [switch]$Force    # Saltar confirmación (PELIGROSO)
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Red
Write-Host "  DATA GUARD - FAILOVER DE EMERGENCIA" -ForegroundColor Red
Write-Host "================================================================" -ForegroundColor Red
Write-Host ""

if (!$Force) {
    Write-Host "⚠️⚠️⚠️  ADVERTENCIA CRÍTICA  ⚠️⚠️⚠️" -ForegroundColor Red
    Write-Host ""
    Write-Host "Este proceso activará el STANDBY como PRIMARY sin coordinación." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "CONSECUENCIAS:" -ForegroundColor Red
    Write-Host "  • Posible pérdida de datos (últimas transacciones no replicadas)" -ForegroundColor Yellow
    Write-Host "  • El antiguo Primary quedará INVÁLIDO y deberá reconstruirse" -ForegroundColor Yellow
    Write-Host "  • Este proceso NO es reversible automáticamente" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "USAR SOLO SI:" -ForegroundColor Cyan
    Write-Host "  ✓ El Primary está caído y NO recuperable" -ForegroundColor Gray
    Write-Host "  ✓ Es una emergencia que requiere disponibilidad inmediata" -ForegroundColor Gray
    Write-Host "  ✓ Has verificado que no puedes hacer SWITCHOVER" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Si el Primary ESTÁ disponible, usa: .\switchover_dataguard.ps1" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm1 = Read-Host "¿El Primary está REALMENTE caído e irrecuperable? (SI/NO)"
    if ($confirm1 -ne "SI") {
        Write-Host "Operación cancelada. Usa switchover si el Primary funciona." -ForegroundColor Yellow
        exit 0
    }
    
    $confirm2 = Read-Host "¿Entiendes que puede haber pérdida de datos? (SI/NO)"
    if ($confirm2 -ne "SI") {
        Write-Host "Operación cancelada." -ForegroundColor Yellow
        exit 0
    }
    
    $confirm3 = Read-Host "Escribe 'ACTIVAR FAILOVER' para continuar"
    if ($confirm3 -ne "ACTIVAR FAILOVER") {
        Write-Host "Operación cancelada." -ForegroundColor Yellow
        exit 0
    }
}

# Configuración
$STANDBY_CONTAINER = "oracle_standby"
$PRIMARY_CONTAINER = "oracle_primary"  # Para intentar detenerlo si está activo
$ORACLE_PWD = "admin123"

function Invoke-SqlCommand {
    param(
        [string]$Container,
        [string]$SqlCommand,
        [switch]$ShowOutput,
        [switch]$IgnoreError
    )
    
    $sqlBlock = @"
sqlplus -s sys/$ORACLE_PWD@//localhost:1521/ORCL as sysdba <<'EOF'
SET HEADING OFF;
SET FEEDBACK OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET PAGESIZE 0;
SET LINESIZE 32767;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
$SqlCommand
EXIT;
EOF
"@

    $sqlBlock = ($sqlBlock -replace "`r", "")
    
    try {
        $result = docker exec $Container bash -c $sqlBlock 2>&1
        if ($ShowOutput) {
            Write-Host "  $result" -ForegroundColor Gray
        }
        if ($LASTEXITCODE -ne 0 -and !$IgnoreError) {
            throw "Error ejecutando SQL: $result"
        }
        return $result
    }
    catch {
        if ($IgnoreError) {
            Write-Host "  ⚠️  Ignorando error: $_" -ForegroundColor Yellow
            return $null
        }
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
        throw
    }
}

function Get-DatabaseRole {
    param([string]$Container)
    
    $sql = "SELECT database_role FROM v`$database;"
    $result = Invoke-SqlCommand -Container $Container -SqlCommand $sql -IgnoreError
    if ($result) {
        return $result.Trim()
    }
    return "UNAVAILABLE"
}

# ========================================
# PASO 1: Verificar estado del Primary
# ========================================
Write-Host "[1/6] Verificando si Primary está realmente caído..." -ForegroundColor Yellow

$primaryRole = Get-DatabaseRole -Container $PRIMARY_CONTAINER

if ($primaryRole -eq "PRIMARY") {
    Write-Host "  ❌ ERROR: El Primary ESTÁ funcionando!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  El Primary responde y está activo como PRIMARY." -ForegroundColor Yellow
    Write-Host "  NO uses FAILOVER cuando el Primary funciona." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Usa en su lugar:" -ForegroundColor Cyan
    Write-Host "    .\switchover_dataguard.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "  ✅ Primary no responde o no está disponible" -ForegroundColor Green
Write-Host ""

# ========================================
# PASO 2: Verificar estado del Standby
# ========================================
Write-Host "[2/6] Verificando estado del Standby..." -ForegroundColor Yellow

$standbyRole = Get-DatabaseRole -Container $STANDBY_CONTAINER

if ($standbyRole -ne "PHYSICAL STANDBY") {
    Write-Host "  ❌ ERROR: Standby no es PHYSICAL STANDBY (es: $standbyRole)" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Standby está disponible como PHYSICAL STANDBY" -ForegroundColor Green
Write-Host ""

# ========================================
# PASO 3: Verificar datos replicados
# ========================================
Write-Host "[3/6] Verificando últimos datos replicados..." -ForegroundColor Yellow

$lastAppliedSql = @"
SELECT 'Ultimo sequence aplicado: ' || NVL(TO_CHAR(MAX(sequence#)), 'ninguno') 
FROM v`$archived_log 
WHERE applied='YES';
"@

$lastApplied = Invoke-SqlCommand -Container $STANDBY_CONTAINER -SqlCommand $lastAppliedSql
Write-Host "  $lastApplied" -ForegroundColor Gray

Write-Host ""
Write-Host "  ⚠️  NOTA: Cualquier transacción posterior a este sequence se PERDERÁ" -ForegroundColor Yellow
Write-Host ""

# ========================================
# PASO 4: Detener managed recovery
# ========================================
Write-Host "[4/6] Deteniendo managed recovery..." -ForegroundColor Yellow

$stopRecoverySql = "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;"
Invoke-SqlCommand -Container $STANDBY_CONTAINER -SqlCommand $stopRecoverySql | Out-Null

Write-Host "  ✅ Recovery detenido" -ForegroundColor Green
Write-Host ""

# ========================================
# PASO 5: Activar Standby como Primary
# ========================================
Write-Host "[5/6] Activando Standby como PRIMARY (FAILOVER)..." -ForegroundColor Yellow

# 5.1: Finish recovery con todos los logs disponibles
Write-Host "  [5.1] Aplicando todos los logs disponibles..." -ForegroundColor Gray
$finishSql = "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH FORCE;"
Invoke-SqlCommand -Container $STANDBY_CONTAINER -SqlCommand $finishSql -IgnoreError | Out-Null
Start-Sleep -Seconds 3

# 5.2: Activar como primary
Write-Host "  [5.2] Ejecutando FAILOVER TO PRIMARY..." -ForegroundColor Gray
$failoverSql = "ALTER DATABASE ACTIVATE PHYSICAL STANDBY DATABASE;"
Invoke-SqlCommand -Container $STANDBY_CONTAINER -SqlCommand $failoverSql | Out-Null

# 5.3: Abrir la base de datos
Write-Host "  [5.3] Abriendo base de datos..." -ForegroundColor Gray
Invoke-SqlCommand -Container $STANDBY_CONTAINER -SqlCommand "SHUTDOWN IMMEDIATE;" | Out-Null
Start-Sleep -Seconds 3
Invoke-SqlCommand -Container $STANDBY_CONTAINER -SqlCommand "STARTUP;" | Out-Null

Write-Host "  ✅ Standby activado como PRIMARY" -ForegroundColor Green
Write-Host ""

# ========================================
# PASO 6: Verificar rol final
# ========================================
Write-Host "[6/6] Verificando nuevo rol..." -ForegroundColor Yellow

$newRole = Get-DatabaseRole -Container $STANDBY_CONTAINER
Write-Host "  $STANDBY_CONTAINER ahora es: $newRole" -ForegroundColor Gray

if ($newRole -eq "PRIMARY") {
    Write-Host "  ✅ FAILOVER COMPLETADO EXITOSAMENTE" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  ADVERTENCIA: El rol no es PRIMARY (es: $newRole)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  FAILOVER FINALIZADO" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "NUEVO PRIMARY: $STANDBY_CONTAINER (puerto 1524)" -ForegroundColor Cyan
Write-Host "ANTIGUO PRIMARY: $PRIMARY_CONTAINER - INVALIDADO" -ForegroundColor Red
Write-Host ""
Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Conecta aplicaciones al NUEVO Primary:" -ForegroundColor White
Write-Host "   Host: localhost" -ForegroundColor Gray
Write-Host "   Puerto: 1524" -ForegroundColor Gray
Write-Host "   Service: ORCL" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Cuando el antiguo Primary se recupere:" -ForegroundColor White
Write-Host "   • Deberás reconstruirlo desde cero como Standby" -ForegroundColor Gray
Write-Host "   • NO lo inicies sin antes recrearlo" -ForegroundColor Red
Write-Host "   • Usa: .\rebuild_standby.ps1 (cuando lo creemos)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Verifica replicación de datos:" -ForegroundColor White
Write-Host "   docker exec $STANDBY_CONTAINER sqlplus sys/$ORACLE_PWD@//localhost:1521/ORCL as sysdba" -ForegroundColor Gray
Write-Host "   SQL> SELECT open_mode, database_role FROM v`$database;" -ForegroundColor Gray
Write-Host ""

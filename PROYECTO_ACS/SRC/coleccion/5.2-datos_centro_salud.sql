-- ============================================================================
-- DATOS CENTRO DE SALUD
-- Archivo: 5.2-datos_centro_salud.sql
-- Descripción: Carga de datos para el módulo de centros médicos
-- Fecha: 10/11/2025
-- ============================================================================

-- NOTA IMPORTANTE:
-- ACS_MEDICO se genera automáticamente cuando un usuario con tipo 'MEDICO' es aprobado
-- El AME_ID es igual al AUS_ID del usuario médico

-- ============================================================================
-- 1. CREAR TABLAS FALTANTES (ACS_DETALLE_MENSUAL, ACS_MEDICO, ACS_HISTORIAL_PROCEDIMIENTO)
-- ============================================================================

-- ** TABLA ACS_MEDICO **
CREATE TABLE ACS_MEDICO (
    AME_ID NUMBER NOT NULL,
    AME_ESPECIALIDAD VARCHAR2(100),
    AME_CODIGO_MEDICO VARCHAR2(50),
    AME_FECHA_REGISTRO TIMESTAMP(6) DEFAULT SYSTIMESTAMP,
    AME_ESTADO VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT PK_ACS_MEDICO PRIMARY KEY (AME_ID),
    CONSTRAINT FK_AME_X_AUS FOREIGN KEY (AME_ID) REFERENCES ACS_USUARIO(AUS_ID),
    CONSTRAINT CHK_AME_ESTADO CHECK (AME_ESTADO IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO'))
);

COMMENT ON TABLE ACS_MEDICO IS 'Tabla para información específica de médicos del sistema';
COMMENT ON COLUMN ACS_MEDICO.AME_ID IS 'ID del médico (igual al AUS_ID)';
COMMENT ON COLUMN ACS_MEDICO.AME_ESPECIALIDAD IS 'Especialidad médica';
COMMENT ON COLUMN ACS_MEDICO.AME_CODIGO_MEDICO IS 'Código profesional del médico';
COMMENT ON COLUMN ACS_MEDICO.AME_ESTADO IS 'Estado del médico en el sistema';

-- ** TABLA ACS_DETALLE_MENSUAL **
CREATE TABLE ACS_DETALLE_MENSUAL (
    ADM_ID NUMBER GENERATED ALWAYS AS IDENTITY,
    ADM_OBSERVACIONES VARCHAR2(255),
    ADM_FECHA DATE NOT NULL,
    ADM_ESTADO_TURNO VARCHAR2(15) DEFAULT 'CUMPLIDO' NOT NULL,
    ADM_HR_INICIO TIMESTAMP(6),
    ADM_HR_FIN TIMESTAMP(6),
    ADM_ESTADO VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL,
    AEM_ID NUMBER NOT NULL,
    AME_ID NUMBER,
    APM_ID NUMBER,
    ATU_ID NUMBER,
    CONSTRAINT PK_ACS_DETALLE_MENSUAL PRIMARY KEY (ADM_ID),
    CONSTRAINT FK_ADM_X_AEM FOREIGN KEY (AEM_ID) REFERENCES ACS_ESCALA_MENSUAL(AEM_ID),
    CONSTRAINT FK_ADM_X_AME FOREIGN KEY (AME_ID) REFERENCES ACS_MEDICO(AME_ID),
    CONSTRAINT FK_ADM_X_APM FOREIGN KEY (APM_ID) REFERENCES ACS_PUESTO_MEDICO(APM_ID),
    CONSTRAINT FK_ADM_X_ATU FOREIGN KEY (ATU_ID) REFERENCES ACS_TURNO(ATU_ID),
    CONSTRAINT CHK_ADM_ESTADO CHECK (ADM_ESTADO IN ('ACTIVO', 'INACTIVO')),
    CONSTRAINT CHK_ADM_ESTADO_TURNO CHECK (ADM_ESTADO_TURNO IN ('CUMPLIDO','FALTA','CANCELADO','REEMPLAZADO'))
);

COMMENT ON TABLE ACS_DETALLE_MENSUAL IS 'Tabla para detalles diarios de las escalas mensuales';
COMMENT ON COLUMN ACS_DETALLE_MENSUAL.ADM_ID IS 'ID único del detalle mensual';
COMMENT ON COLUMN ACS_DETALLE_MENSUAL.ADM_FECHA IS 'Fecha específica del turno';
COMMENT ON COLUMN ACS_DETALLE_MENSUAL.ADM_ESTADO_TURNO IS 'Estado del cumplimiento del turno';
COMMENT ON COLUMN ACS_DETALLE_MENSUAL.AEM_ID IS 'ID de la escala mensual';
COMMENT ON COLUMN ACS_DETALLE_MENSUAL.AME_ID IS 'ID del médico asignado';

-- ** TABLA ACS_HISTORIAL_PROCEDIMIENTO **
CREATE TABLE ACS_HISTORIAL_PROCEDIMIENTO (
    AHP_ID NUMBER GENERATED ALWAYS AS IDENTITY,
    AHP_NOMBRE VARCHAR2(100) NOT NULL,
    AHP_DESCRIPCION VARCHAR2(255),
    AHP_COSTO NUMBER NOT NULL,
    AHP_PAGO NUMBER NOT NULL,
    AHP_ESTADO VARCHAR2(10) NOT NULL,
    AHP_FECHA_INICIO TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    AHP_FECHA_FIN TIMESTAMP(6),
    APD_ID NUMBER NOT NULL,
    CONSTRAINT PK_ACS_HISTORIAL_PROCEDIMIENTO PRIMARY KEY (AHP_ID),
    CONSTRAINT FK_AHP_X_APD FOREIGN KEY (APD_ID) REFERENCES ACS_PROCEDIMIENTO(APD_ID)
);

COMMENT ON TABLE ACS_HISTORIAL_PROCEDIMIENTO IS 'Tabla para auditoría de cambios en procedimientos';
COMMENT ON COLUMN ACS_HISTORIAL_PROCEDIMIENTO.AHP_ID IS 'ID único del historial';
COMMENT ON COLUMN ACS_HISTORIAL_PROCEDIMIENTO.AHP_FECHA_INICIO IS 'Inicio de vigencia del precio';
COMMENT ON COLUMN ACS_HISTORIAL_PROCEDIMIENTO.AHP_FECHA_FIN IS 'Fin de vigencia (NULL si está activo)';

-- ============================================================================
-- 2. REGISTRAR MÉDICOS (Basado en usuarios aprobados)
-- ============================================================================

-- Los médicos aprobados son: 118690700, CED345678
-- Se insertan automáticamente desde ACS_USUARIO donde APE_TIPO_USUARIO = 'MEDICO'

DECLARE
    V_AUS_ID NUMBER;
BEGIN
    -- Médico 1: Juan Camacho (118690700)
    SELECT AUS_ID INTO V_AUS_ID
    FROM ACS_USUARIO U
    INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
    WHERE P.APE_CEDULA = '118690700';
    
    INSERT INTO ACS_MEDICO (AME_ID, AME_ESPECIALIDAD, AME_CODIGO_MEDICO, AME_ESTADO)
    VALUES (V_AUS_ID, 'Medicina General', 'MED-2024-001', 'ACTIVO');
    
    -- Médico 2: Carlos Ramirez (CED345678)
    SELECT AUS_ID INTO V_AUS_ID
    FROM ACS_USUARIO U
    INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
    WHERE P.APE_CEDULA = 'CED345678';
    
    INSERT INTO ACS_MEDICO (AME_ID, AME_ESPECIALIDAD, AME_CODIGO_MEDICO, AME_ESTADO)
    VALUES (V_AUS_ID, 'Medicina de Emergencias', 'MED-2024-002', 'ACTIVO');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Médicos registrados correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] registrar médicos: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- 3. REGISTRAR DATOS ACS_CENTRO_MEDICO
-- ============================================================================

DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'ACM_NOMBRE,ACM_UBICACION,ACM_TELEFONO,ACM_EMAIL',
                'Hospital Central,San Jose Centro Av Central Calle 14,2222-1000,info@hospitalcentral.cr',
                'Clinica Santa Rita,Heredia Centro 100m Norte Iglesia,2260-2000,contacto@santarita.cr',
                'Centro Medico del Valle,Cartago Ave 4 Calle 2,2550-3000,atencion@cmvalle.cr',
                'Clinica Los Robles,Alajuela Centro Av 3,2430-4000,servicios@losrobles.cr'
            )
        );
BEGIN
    FOR R_LINE IN C_LINES LOOP
        V_LINE := R_LINE.LINE;

        IF V_PRIMERA_LINEA THEN
            V_PRIMERA_LINEA := FALSE;
            CONTINUE;
        END IF;
        
        BEGIN
            INSERT INTO ACS_CENTRO_MEDICO (
                ACM_NOMBRE,
                ACM_UBICACION,
                ACM_TELEFONO,
                ACM_EMAIL,
                ACM_ESTADO
            ) VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                UTIL_GET_FIELD(V_LINE, 2),
                UTIL_GET_FIELD(V_LINE, 3),
                UTIL_GET_FIELD(V_LINE, 4),
                'ACTIVO'
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar centro médico: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_CENTRO_MEDICO: Proceso completado.');
END;
/

-- ============================================================================
-- 4. REGISTRAR DATOS ACS_PUESTO_MEDICO
-- ============================================================================

DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APM_NOMBRE,APM_DESCRIPCION',
                'Emergencias,Atencion de emergencias medicas las 24 horas',
                'Consulta Externa,Consultas medicas programadas',
                'Hospitalizacion,Cuidado de pacientes hospitalizados',
                'Cirugia,Procedimientos quirurgicos',
                'Cuidados Intensivos,UCI - Unidad de cuidados intensivos',
                'Pediatria,Atencion medica pediatrica',
                'Ginecologia,Atencion ginecologica y obstetricia'
            )
        );
BEGIN
    FOR R_LINE IN C_LINES LOOP
        V_LINE := R_LINE.LINE;

        IF V_PRIMERA_LINEA THEN
            V_PRIMERA_LINEA := FALSE;
            CONTINUE;
        END IF;
        
        BEGIN
            INSERT INTO ACS_PUESTO_MEDICO (
                APM_NOMBRE,
                APM_DESCRIPCION,
                APM_ESTADO
            ) VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                UTIL_GET_FIELD(V_LINE, 2),
                'ACTIVO'
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar puesto médico: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PUESTO_MEDICO: Proceso completado.');
END;
/

-- ============================================================================
-- 5. REGISTRAR DATOS ACS_PUESTOXCENTRO
-- ============================================================================

-- Asignar puestos a centros médicos
DECLARE
    V_ACM_ID NUMBER;
    V_APM_ID NUMBER;
    
    TYPE T_CENTRO_PUESTO IS RECORD (
        CENTRO VARCHAR2(100),
        PUESTO VARCHAR2(100)
    );
    
    TYPE T_ASIGNACIONES IS TABLE OF T_CENTRO_PUESTO;
    
    V_ASIGNACIONES T_ASIGNACIONES := T_ASIGNACIONES(
        -- Hospital Central (completo)
        T_CENTRO_PUESTO('Hospital Central', 'Emergencias'),
        T_CENTRO_PUESTO('Hospital Central', 'Consulta Externa'),
        T_CENTRO_PUESTO('Hospital Central', 'Hospitalizacion'),
        T_CENTRO_PUESTO('Hospital Central', 'Cirugia'),
        T_CENTRO_PUESTO('Hospital Central', 'Cuidados Intensivos'),
        T_CENTRO_PUESTO('Hospital Central', 'Pediatria'),
        T_CENTRO_PUESTO('Hospital Central', 'Ginecologia'),
        
        -- Clinica Santa Rita (mediano)
        T_CENTRO_PUESTO('Clinica Santa Rita', 'Emergencias'),
        T_CENTRO_PUESTO('Clinica Santa Rita', 'Consulta Externa'),
        T_CENTRO_PUESTO('Clinica Santa Rita', 'Hospitalizacion'),
        T_CENTRO_PUESTO('Clinica Santa Rita', 'Cirugia'),
        
        -- Centro Medico del Valle (pequeño)
        T_CENTRO_PUESTO('Centro Medico del Valle', 'Emergencias'),
        T_CENTRO_PUESTO('Centro Medico del Valle', 'Consulta Externa'),
        
        -- Clinica Los Robles (pequeño)
        T_CENTRO_PUESTO('Clinica Los Robles', 'Emergencias'),
        T_CENTRO_PUESTO('Clinica Los Robles', 'Consulta Externa'),
        T_CENTRO_PUESTO('Clinica Los Robles', 'Pediatria')
    );
BEGIN
    FOR I IN 1..V_ASIGNACIONES.COUNT LOOP
        BEGIN
            SELECT ACM_ID INTO V_ACM_ID
            FROM ACS_CENTRO_MEDICO
            WHERE ACM_NOMBRE = V_ASIGNACIONES(I).CENTRO;
            
            SELECT APM_ID INTO V_APM_ID
            FROM ACS_PUESTO_MEDICO
            WHERE APM_NOMBRE = V_ASIGNACIONES(I).PUESTO;
            
            INSERT INTO ACS_PUESTOXCENTRO (ACM_ID, APM_ID, APC_ESTADO)
            VALUES (V_ACM_ID, V_APM_ID, 'ACTIVO');
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('[Error] No se encontró: ' || V_ASIGNACIONES(I).CENTRO || ' - ' || V_ASIGNACIONES(I).PUESTO);
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar puesto x centro: ' || SQLERRM);
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PUESTOXCENTRO: Proceso completado.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] general en puestos x centro: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- 6. REGISTRAR DATOS ACS_PROCEDIMIENTO
-- ============================================================================

DECLARE
    V_LINE VARCHAR2(2000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APD_NOMBRE,APD_DESCRIPCION',
                'Consulta General,Consulta medica general de primera vez o control',
                'Consulta Especializada,Consulta con medico especialista',
                'Electrocardiograma,Estudio de actividad electrica del corazon',
                'Radiografia Simple,Examen radiologico simple',
                'Ultrasonido,Estudio por ultrasonido',
                'Analisis de Sangre Basico,Hemograma completo y quimica sanguinea',
                'Sutura Simple,Cierre de heridas simples',
                'Curacion de Heridas,Curacion y limpieza de heridas',
                'Inyeccion Intramuscular,Aplicacion de medicamento IM',
                'Nebulizacion,Terapia respiratoria por nebulizacion',
                'Cirugia Menor,Procedimientos quirurgicos menores ambulatorios',
                'Control Prenatal,Control de embarazo',
                'Parto Normal,Atencion de parto vaginal',
                'Cesarea,Parto por cesarea',
                'Hospitalizacion Dia,Costo por dia de hospitalizacion'
            )
        );
BEGIN
    FOR R_LINE IN C_LINES LOOP
        V_LINE := R_LINE.LINE;

        IF V_PRIMERA_LINEA THEN
            V_PRIMERA_LINEA := FALSE;
            CONTINUE;
        END IF;
        
        BEGIN
            INSERT INTO ACS_PROCEDIMIENTO (
                APD_NOMBRE,
                APD_DESCRIPCION,
                APD_ESTADO
            ) VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                UTIL_GET_FIELD(V_LINE, 2),
                'ACTIVO'
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar procedimiento: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PROCEDIMIENTO: Proceso completado.');
END;
/

-- ============================================================================
-- 7. AGREGAR CAMPOS FALTANTES A ACS_PROCEDIMIENTO (COSTO Y PAGO)
-- ============================================================================

-- Verificar si las columnas existen antes de agregarlas
DECLARE
    V_COLUMN_EXISTS NUMBER;
BEGIN
    -- Verificar APD_COSTO
    SELECT COUNT(*) INTO V_COLUMN_EXISTS
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'ACS_PROCEDIMIENTO' AND COLUMN_NAME = 'APD_COSTO';
    
    IF V_COLUMN_EXISTS = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ACS_PROCEDIMIENTO ADD APD_COSTO NUMBER DEFAULT 0 NOT NULL';
        DBMS_OUTPUT.PUT_LINE('[ok] Columna APD_COSTO agregada.');
    END IF;
    
    -- Verificar APD_PAGO
    SELECT COUNT(*) INTO V_COLUMN_EXISTS
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'ACS_PROCEDIMIENTO' AND COLUMN_NAME = 'APD_PAGO';
    
    IF V_COLUMN_EXISTS = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ACS_PROCEDIMIENTO ADD APD_PAGO NUMBER DEFAULT 0 NOT NULL';
        DBMS_OUTPUT.PUT_LINE('[ok] Columna APD_PAGO agregada.');
    END IF;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] verificar/agregar columnas: ' || SQLERRM);
END;
/

-- Actualizar precios de procedimientos
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 25000, APD_PAGO = 15000 WHERE APD_NOMBRE = 'Consulta General';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 50000, APD_PAGO = 30000 WHERE APD_NOMBRE = 'Consulta Especializada';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 35000, APD_PAGO = 20000 WHERE APD_NOMBRE = 'Electrocardiograma';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 40000, APD_PAGO = 22000 WHERE APD_NOMBRE = 'Radiografia Simple';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 60000, APD_PAGO = 35000 WHERE APD_NOMBRE = 'Ultrasonido';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 30000, APD_PAGO = 18000 WHERE APD_NOMBRE = 'Analisis de Sangre Basico';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 45000, APD_PAGO = 25000 WHERE APD_NOMBRE = 'Sutura Simple';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 20000, APD_PAGO = 12000 WHERE APD_NOMBRE = 'Curacion de Heridas';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 8000, APD_PAGO = 5000 WHERE APD_NOMBRE = 'Inyeccion Intramuscular';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 15000, APD_PAGO = 9000 WHERE APD_NOMBRE = 'Nebulizacion';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 150000, APD_PAGO = 80000 WHERE APD_NOMBRE = 'Cirugia Menor';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 35000, APD_PAGO = 20000 WHERE APD_NOMBRE = 'Control Prenatal';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 500000, APD_PAGO = 250000 WHERE APD_NOMBRE = 'Parto Normal';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 800000, APD_PAGO = 400000 WHERE APD_NOMBRE = 'Cesarea';
UPDATE ACS_PROCEDIMIENTO SET APD_COSTO = 120000, APD_PAGO = 60000 WHERE APD_NOMBRE = 'Hospitalizacion Dia';

COMMIT;
DBMS_OUTPUT.PUT_LINE('[ok] Precios de procedimientos actualizados.');

-- ============================================================================
-- 8. REGISTRAR DATOS ACS_PROCEDIMIENTOXCENTRO
-- ============================================================================

-- Asignar procedimientos a centros con precios específicos por centro
DECLARE
    V_ACM_ID NUMBER;
    V_APD_ID NUMBER;
    
    TYPE T_CENTRO_PROC IS RECORD (
        CENTRO VARCHAR2(100),
        PROCEDIMIENTO VARCHAR2(100),
        COSTO NUMBER,
        PAGO NUMBER
    );
    
    TYPE T_ASIGNACIONES IS TABLE OF T_CENTRO_PROC;
    
    V_ASIGNACIONES T_ASIGNACIONES := T_ASIGNACIONES(
        -- Hospital Central (todos los procedimientos - precios premium)
        T_CENTRO_PROC('Hospital Central', 'Consulta General', 30000, 18000),
        T_CENTRO_PROC('Hospital Central', 'Consulta Especializada', 60000, 36000),
        T_CENTRO_PROC('Hospital Central', 'Electrocardiograma', 40000, 24000),
        T_CENTRO_PROC('Hospital Central', 'Radiografia Simple', 45000, 27000),
        T_CENTRO_PROC('Hospital Central', 'Ultrasonido', 70000, 42000),
        T_CENTRO_PROC('Hospital Central', 'Analisis de Sangre Basico', 35000, 21000),
        T_CENTRO_PROC('Hospital Central', 'Sutura Simple', 50000, 30000),
        T_CENTRO_PROC('Hospital Central', 'Curacion de Heridas', 25000, 15000),
        T_CENTRO_PROC('Hospital Central', 'Cirugia Menor', 180000, 100000),
        T_CENTRO_PROC('Hospital Central', 'Parto Normal', 600000, 300000),
        T_CENTRO_PROC('Hospital Central', 'Cesarea', 900000, 450000),
        T_CENTRO_PROC('Hospital Central', 'Hospitalizacion Dia', 150000, 75000),
        
        -- Clinica Santa Rita (procedimientos comunes)
        T_CENTRO_PROC('Clinica Santa Rita', 'Consulta General', 25000, 15000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Consulta Especializada', 50000, 30000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Electrocardiograma', 35000, 20000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Radiografia Simple', 40000, 22000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Ultrasonido', 60000, 35000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Analisis de Sangre Basico', 30000, 18000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Sutura Simple', 45000, 25000),
        T_CENTRO_PROC('Clinica Santa Rita', 'Cirugia Menor', 150000, 80000),
        
        -- Centro Medico del Valle (básicos)
        T_CENTRO_PROC('Centro Medico del Valle', 'Consulta General', 20000, 12000),
        T_CENTRO_PROC('Centro Medico del Valle', 'Curacion de Heridas', 18000, 11000),
        T_CENTRO_PROC('Centro Medico del Valle', 'Inyeccion Intramuscular', 8000, 5000),
        T_CENTRO_PROC('Centro Medico del Valle', 'Nebulizacion', 15000, 9000),
        
        -- Clinica Los Robles (básicos + pediatría)
        T_CENTRO_PROC('Clinica Los Robles', 'Consulta General', 22000, 13000),
        T_CENTRO_PROC('Clinica Los Robles', 'Control Prenatal', 35000, 20000),
        T_CENTRO_PROC('Clinica Los Robles', 'Curacion de Heridas', 20000, 12000),
        T_CENTRO_PROC('Clinica Los Robles', 'Nebulizacion', 15000, 9000)
    );
BEGIN
    FOR I IN 1..V_ASIGNACIONES.COUNT LOOP
        BEGIN
            SELECT ACM_ID INTO V_ACM_ID
            FROM ACS_CENTRO_MEDICO
            WHERE ACM_NOMBRE = V_ASIGNACIONES(I).CENTRO;
            
            SELECT APD_ID INTO V_APD_ID
            FROM ACS_PROCEDIMIENTO
            WHERE APD_NOMBRE = V_ASIGNACIONES(I).PROCEDIMIENTO;
            
            INSERT INTO ACS_PROCEDIMIENTOXCENTRO (
                ACM_ID,
                APD_ID,
                APRC_COSTO,
                APRC_PAGO,
                APRC_ESTADO
            ) VALUES (
                V_ACM_ID,
                V_APD_ID,
                V_ASIGNACIONES(I).COSTO,
                V_ASIGNACIONES(I).PAGO,
                'ACTIVO'
            );
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('[Error] No se encontró: ' || V_ASIGNACIONES(I).CENTRO || ' - ' || V_ASIGNACIONES(I).PROCEDIMIENTO);
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar procedimiento x centro: ' || SQLERRM);
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PROCEDIMIENTOXCENTRO: Proceso completado.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] general en procedimientos x centro: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- 9. REGISTRAR DATOS ACS_TURNO
-- ============================================================================

-- Crear turnos base para generar escalas mensuales
DECLARE
    V_APM_ID_EMERGENCIAS NUMBER;
    V_APM_ID_CONSULTA NUMBER;
    V_AME_ID_1 NUMBER;
    V_AME_ID_2 NUMBER;
BEGIN
    -- Obtener IDs de puestos
    SELECT APM_ID INTO V_APM_ID_EMERGENCIAS FROM ACS_PUESTO_MEDICO WHERE APM_NOMBRE = 'Emergencias';
    SELECT APM_ID INTO V_APM_ID_CONSULTA FROM ACS_PUESTO_MEDICO WHERE APM_NOMBRE = 'Consulta Externa';
    
    -- Obtener IDs de médicos
    SELECT AME_ID INTO V_AME_ID_1 FROM ACS_MEDICO WHERE AME_CODIGO_MEDICO = 'MED-2024-001';
    SELECT AME_ID INTO V_AME_ID_2 FROM ACS_MEDICO WHERE AME_CODIGO_MEDICO = 'MED-2024-002';
    
    -- Turnos de Emergencias (24 horas)
    INSERT INTO ACS_TURNO (ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TIPO_PAGO, ATU_COSTO, ATU_PAGO, ATU_ESTADO, APM_ID, AME_ID)
    VALUES ('Emergencias Mañana', TO_TIMESTAMP('08:00:00', 'HH24:MI:SS'), TO_TIMESTAMP('16:00:00', 'HH24:MI:SS'), 'TURNO', 80000, 50000, 'ACTIVO', V_APM_ID_EMERGENCIAS, NULL);
    
    INSERT INTO ACS_TURNO (ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TIPO_PAGO, ATU_COSTO, ATU_PAGO, ATU_ESTADO, APM_ID, AME_ID)
    VALUES ('Emergencias Tarde', TO_TIMESTAMP('16:00:00', 'HH24:MI:SS'), TO_TIMESTAMP('00:00:00', 'HH24:MI:SS'), 'TURNO', 90000, 55000, 'ACTIVO', V_APM_ID_EMERGENCIAS, NULL);
    
    INSERT INTO ACS_TURNO (ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TIPO_PAGO, ATU_COSTO, ATU_PAGO, ATU_ESTADO, APM_ID, AME_ID)
    VALUES ('Emergencias Noche', TO_TIMESTAMP('00:00:00', 'HH24:MI:SS'), TO_TIMESTAMP('08:00:00', 'HH24:MI:SS'), 'TURNO', 100000, 60000, 'ACTIVO', V_APM_ID_EMERGENCIAS, NULL);
    
    -- Turnos de Consulta Externa (solo día)
    INSERT INTO ACS_TURNO (ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TIPO_PAGO, ATU_COSTO, ATU_PAGO, ATU_ESTADO, APM_ID, AME_ID)
    VALUES ('Consulta Mañana', TO_TIMESTAMP('08:00:00', 'HH24:MI:SS'), TO_TIMESTAMP('12:00:00', 'HH24:MI:SS'), 'HORAS', 40000, 25000, 'ACTIVO', V_APM_ID_CONSULTA, NULL);
    
    INSERT INTO ACS_TURNO (ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TIPO_PAGO, ATU_COSTO, ATU_PAGO, ATU_ESTADO, APM_ID, AME_ID)
    VALUES ('Consulta Tarde', TO_TIMESTAMP('13:00:00', 'HH24:MI:SS'), TO_TIMESTAMP('17:00:00', 'HH24:MI:SS'), 'HORAS', 40000, 25000, 'ACTIVO', V_APM_ID_CONSULTA, NULL);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Turnos base creados correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] crear turnos: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- 10. AGREGAR CAMPO ATU_TARIFA_HORARIA A ACS_TURNO
-- ============================================================================

DECLARE
    V_COLUMN_EXISTS NUMBER;
BEGIN
    SELECT COUNT(*) INTO V_COLUMN_EXISTS
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'ACS_TURNO' AND COLUMN_NAME = 'ATU_TARIFA_HORARIA';
    
    IF V_COLUMN_EXISTS = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ACS_TURNO ADD ATU_TARIFA_HORARIA NUMBER';
        DBMS_OUTPUT.PUT_LINE('[ok] Columna ATU_TARIFA_HORARIA agregada.');
        
        -- Actualizar tarifas horarias para turnos tipo HORAS
        EXECUTE IMMEDIATE '
            UPDATE ACS_TURNO
            SET ATU_TARIFA_HORARIA = CASE
                WHEN ATU_TIPO_PAGO = ''HORAS'' THEN
                    ATU_PAGO / EXTRACT(HOUR FROM (ATU_HORA_FIN - ATU_HORA_INICIO))
                ELSE NULL
            END
            WHERE ATU_TIPO_PAGO = ''HORAS''';
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('[ok] Tarifas horarias calculadas.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[Info] Columna ATU_TARIFA_HORARIA ya existe.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] agregar tarifa horaria: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- 11. GENERAR ESCALA MENSUAL DE PRUEBA (Noviembre 2025)
-- ============================================================================

-- Generar escala para Hospital Central - Noviembre 2025
DECLARE
    V_ACM_ID NUMBER;
BEGIN
    SELECT ACM_ID INTO V_ACM_ID
    FROM ACS_CENTRO_MEDICO
    WHERE ACM_NOMBRE = 'Hospital Central';
    
    -- Usar el procedimiento PRC_GENERAR_ESCALA_MENSUAL
    PRC_GENERAR_ESCALA_MENSUAL(
        p_acm_id => V_ACM_ID,
        p_mes    => 11,
        p_anio   => 2025
    );
    
    DBMS_OUTPUT.PUT_LINE('[ok] Escala mensual generada para Hospital Central - Noviembre 2025.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] generar escala mensual: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Asignar médicos a algunos turnos específicos para demostración
DECLARE
    V_AME_ID_1 NUMBER;
    V_AME_ID_2 NUMBER;
    V_CONTADOR NUMBER := 0;
BEGIN
    SELECT AME_ID INTO V_AME_ID_1 FROM ACS_MEDICO WHERE AME_CODIGO_MEDICO = 'MED-2024-001';
    SELECT AME_ID INTO V_AME_ID_2 FROM ACS_MEDICO WHERE AME_CODIGO_MEDICO = 'MED-2024-002';
    
    -- Asignar médico 1 a turnos de días impares
    FOR R IN (
        SELECT ADM_ID
        FROM ACS_DETALLE_MENSUAL
        WHERE EXTRACT(DAY FROM ADM_FECHA) <= 15
        AND ROWNUM <= 10
    ) LOOP
        UPDATE ACS_DETALLE_MENSUAL
        SET AME_ID = V_AME_ID_1,
            ADM_ESTADO_TURNO = 'CUMPLIDO'
        WHERE ADM_ID = R.ADM_ID;
        
        V_CONTADOR := V_CONTADOR + 1;
    END LOOP;
    
    -- Asignar médico 2 a turnos de días pares
    FOR R IN (
        SELECT ADM_ID
        FROM ACS_DETALLE_MENSUAL
        WHERE EXTRACT(DAY FROM ADM_FECHA) > 15
        AND AME_ID IS NULL
        AND ROWNUM <= 10
    ) LOOP
        UPDATE ACS_DETALLE_MENSUAL
        SET AME_ID = V_AME_ID_2,
            ADM_ESTADO_TURNO = 'CUMPLIDO'
        WHERE ADM_ID = R.ADM_ID;
        
        V_CONTADOR := V_CONTADOR + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] ' || V_CONTADOR || ' turnos asignados a médicos.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] asignar médicos a turnos: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- 12. REGISTRAR PROCEDIMIENTOS APLICADOS DE EJEMPLO
-- ============================================================================

DECLARE
    V_AME_ID NUMBER;
    V_APD_ID NUMBER;
    V_ACM_ID NUMBER;
BEGIN
    -- Obtener IDs
    SELECT AME_ID INTO V_AME_ID FROM ACS_MEDICO WHERE AME_CODIGO_MEDICO = 'MED-2024-001';
    SELECT APD_ID INTO V_APD_ID FROM ACS_PROCEDIMIENTO WHERE APD_NOMBRE = 'Consulta General';
    SELECT ACM_ID INTO V_ACM_ID FROM ACS_CENTRO_MEDICO WHERE ACM_NOMBRE = 'Hospital Central';
    
    -- Insertar procedimiento aplicado (el trigger completará COSTO y PAGO automáticamente)
    INSERT INTO ACS_PROC_APLICADO (APA_FECHA, APA_COSTO, APA_PAGO, APA_ESTADO, AME_ID, APD_ID, ACM_ID)
    VALUES (SYSTIMESTAMP, 30000, 18000, 'ACTIVO', V_AME_ID, V_APD_ID, V_ACM_ID);
    
    -- Otro procedimiento
    SELECT APD_ID INTO V_APD_ID FROM ACS_PROCEDIMIENTO WHERE APD_NOMBRE = 'Electrocardiograma';
    
    INSERT INTO ACS_PROC_APLICADO (APA_FECHA, APA_COSTO, APA_PAGO, APA_ESTADO, AME_ID, APD_ID, ACM_ID)
    VALUES (SYSTIMESTAMP, 40000, 24000, 'ACTIVO', V_AME_ID, V_APD_ID, V_ACM_ID);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Procedimientos aplicados registrados.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] registrar procedimientos aplicados: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- VERIFICACIÓN FINAL
-- ============================================================================

-- Verificar datos cargados
SELECT 'CENTROS MEDICOS' AS TABLA, COUNT(*) AS CANTIDAD FROM ACS_CENTRO_MEDICO
UNION ALL
SELECT 'PUESTOS MEDICOS', COUNT(*) FROM ACS_PUESTO_MEDICO
UNION ALL
SELECT 'PUESTOS X CENTRO', COUNT(*) FROM ACS_PUESTOXCENTRO
UNION ALL
SELECT 'PROCEDIMIENTOS', COUNT(*) FROM ACS_PROCEDIMIENTO
UNION ALL
SELECT 'PROC X CENTRO', COUNT(*) FROM ACS_PROCEDIMIENTOXCENTRO
UNION ALL
SELECT 'MEDICOS', COUNT(*) FROM ACS_MEDICO
UNION ALL
SELECT 'TURNOS', COUNT(*) FROM ACS_TURNO
UNION ALL
SELECT 'ESCALAS MENSUALES', COUNT(*) FROM ACS_ESCALA_MENSUAL
UNION ALL
SELECT 'DETALLES MENSUALES', COUNT(*) FROM ACS_DETALLE_MENSUAL
UNION ALL
SELECT 'PROC APLICADOS', COUNT(*) FROM ACS_PROC_APLICADO;

DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('============================================');
DBMS_OUTPUT.PUT_LINE('CARGA DE DATOS COMPLETADA EXITOSAMENTE');
DBMS_OUTPUT.PUT_LINE('============================================');
DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('Próximos pasos sugeridos:');
DBMS_OUTPUT.PUT_LINE('1. Consultar escalas: EXEC PRC_Consultar_Escalas(1, 11, 2025)');
DBMS_OUTPUT.PUT_LINE('2. Cambiar estado: EXEC PRC_Escala_Cambiar_Estado(1, ''VIGENTE'')');
DBMS_OUTPUT.PUT_LINE('3. Marcar para pago: EXEC PRC_Escalas_Marcar_Lista_Pago(11, 2025, NULL)');
DBMS_OUTPUT.PUT_LINE('');

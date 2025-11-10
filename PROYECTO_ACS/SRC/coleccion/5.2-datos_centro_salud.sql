-- Datos módulo Centros de Salud
-- Supuestos:
--  * ACS_USUARIO, ACS_MEDICO, ACS_ADMINISTRATIVO ya existen y comparten el ID base.
--  * Este script crea centros, puestos, procedimientos, relaciones y turnos activos.
--  * Ajusta cantidades/costos según necesidad.
--  * Usa COMMIT por bloque para aislar errores.

-- SET SERVEROUTPUT ON;

-- PROMPT ==== Cargar Centros Médicos ====
DECLARE
    CURSOR C_CENTROS IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'NOMBRE,UBICACION,TELEFONO,EMAIL,ESTADO',
                'Centro Norte,Av. Principal 123,22223333,norte@salud.com,ACTIVO',
                'Clinica Sur,Calle 45 S,22224444,sur@salud.com,ACTIVO',
                'Hospital Central,Boulevard Salud,22225555,central@salud.com,ACTIVO'
            )
        );
    v_first BOOLEAN := TRUE;
BEGIN
    FOR r IN C_CENTROS LOOP
        IF v_first THEN v_first := FALSE; CONTINUE; END IF;
        BEGIN
            INSERT INTO ACS_CENTRO_MEDICO(
                ACM_NOMBRE, ACM_UBICACION, ACM_TELEFONO, ACM_EMAIL, ACM_ESTADO
            ) VALUES (
                UTIL_GET_FIELD(r.LINE,1),
                UTIL_GET_FIELD(r.LINE,2),
                UTIL_GET_FIELD(r.LINE,3),
                UTIL_GET_FIELD(r.LINE,4),
                UTIL_GET_FIELD(r.LINE,5)
            );
            COMMIT;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Centro error: '||SQLERRM);
            ROLLBACK;
        END;
    END LOOP;
END;
/

-- PROMPT ==== Cargar Puestos Médicos ====
DECLARE
    CURSOR C_PUESTOS IS
        SELECT COLUMN_VALUE AS LINE FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'NOMBRE,DESCRIPCION,ESTADO',
                'CARDIOLOGO,Especialista en corazon,ACTIVO',
                'PEDIATRA,Especialista en ninos,ACTIVO',
                'GENERAL,Medicina general,ACTIVO'
            )
        );
    v_first BOOLEAN := TRUE;
BEGIN
    FOR r IN C_PUESTOS LOOP
        IF v_first THEN v_first := FALSE; CONTINUE; END IF;
        BEGIN
            INSERT INTO ACS_PUESTO_MEDICO(APM_NOMBRE, APM_DESCRIPCION, APM_ESTADO)
            VALUES (
                UTIL_GET_FIELD(r.LINE,1),
                UTIL_GET_FIELD(r.LINE,2),
                UTIL_GET_FIELD(r.LINE,3)
            );
            COMMIT;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Puesto error: '||SQLERRM);
            ROLLBACK;
        END;
    END LOOP;
END;
/

-- PROMPT ==== Relacionar Puestos con Centros ====
DECLARE
    v_acm_id ACS_CENTRO_MEDICO.ACM_ID%TYPE;
    v_apm_id ACS_PUESTO_MEDICO.APM_ID%TYPE;
BEGIN
    FOR c IN (SELECT ACM_ID FROM ACS_CENTRO_MEDICO WHERE ACM_ESTADO='ACTIVO') LOOP
        FOR p IN (SELECT APM_ID FROM ACS_PUESTO_MEDICO WHERE APM_ESTADO='ACTIVO') LOOP
            BEGIN
                INSERT INTO ACS_PUESTOXCENTRO(ACM_ID, APM_ID, APC_ESTADO)
                VALUES (c.ACM_ID, p.APM_ID, 'ACTIVO');
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('PXCentro error: '||SQLERRM); END;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- PROMPT ==== Cargar Procedimientos ====
DECLARE
    CURSOR C_PROC IS SELECT COLUMN_VALUE LINE FROM TABLE(
        SYS.ODCIVARCHAR2LIST(
            'NOMBRE,DESCRIPCION,ESTADO',
            'Electrocardiograma,Prueba de actividad electrica,ACTIVO',
            'Consulta General,Valoracion integral,ACTIVO',
            'Vacunacion,Aplicacion de vacunas,ACTIVO'
        )
    );
    v_first BOOLEAN := TRUE;
BEGIN
    FOR r IN C_PROC LOOP
        IF v_first THEN v_first := FALSE; CONTINUE; END IF;
        BEGIN
            INSERT INTO ACS_PROCEDIMIENTO(APD_NOMBRE, APD_DESCRIPCION, APD_ESTADO)
            VALUES (
                UTIL_GET_FIELD(r.LINE,1),
                UTIL_GET_FIELD(r.LINE,2),
                UTIL_GET_FIELD(r.LINE,3)
            );
            COMMIT;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Procedimiento error: '||SQLERRM);
            ROLLBACK;
        END;
    END LOOP;
END;
/

-- PROMPT ==== Relacionar Procedimientos con Centros (costos/pagos hipoteticos) ====
DECLARE
BEGIN
    FOR c IN (SELECT ACM_ID FROM ACS_CENTRO_MEDICO WHERE ACM_ESTADO='ACTIVO') LOOP
        FOR pr IN (SELECT APD_ID FROM ACS_PROCEDIMIENTO WHERE APD_ESTADO='ACTIVO') LOOP
            BEGIN
                INSERT INTO ACS_PROCEDIMIENTOXCENTRO(APRC_COSTO, APRC_PAGO, APRC_ESTADO, ACM_ID, APD_ID)
                VALUES (
                    50000 + (c.ACM_ID*1000), -- costo base variable
                    30000 + (pr.APD_ID*500), -- pago variable
                    'ACTIVO',
                    c.ACM_ID,
                    pr.APD_ID
                );
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('PXC error: '||SQLERRM); END;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- PROMPT ==== Cargar Turnos ====
DECLARE
    CURSOR C_TURNOS IS SELECT COLUMN_VALUE LINE FROM TABLE(
        SYS.ODCIVARCHAR2LIST(
            'NOMBRE,HORA_INICIO,HORA_FIN,TIPO_PAGO,ESTADO',
            'MANANA,07:00,13:00,TURNO,ACTIVO',
            'TARDE,13:00,19:00,TURNO,ACTIVO',
            'NOCHE,19:00,07:00,HORAS,ACTIVO'
        )
    );
    v_first BOOLEAN := TRUE;
    v_hora_ini VARCHAR2(5);
    v_hora_fin VARCHAR2(5);
    v_tipo     VARCHAR2(10);
    v_costo    NUMBER;
    v_pago     NUMBER;
BEGIN
    FOR r IN C_TURNOS LOOP
        IF v_first THEN v_first := FALSE; CONTINUE; END IF;
        v_hora_ini := UTIL_GET_FIELD(r.LINE,2);
        v_hora_fin := UTIL_GET_FIELD(r.LINE,3);
        BEGIN
            v_tipo := UTIL_GET_FIELD(r.LINE,4);
            -- Montos base simples por tipo de pago
            IF v_tipo = 'TURNO' THEN
                v_costo := 80000; v_pago := 50000;
            ELSE -- HORAS
                v_costo := 12000; v_pago := 8000;
            END IF;
            INSERT INTO ACS_TURNO(
                ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TIPO_PAGO, ATU_COSTO, ATU_PAGO, ATU_ESTADO
            ) VALUES (
                UTIL_GET_FIELD(r.LINE,1),
                TO_TIMESTAMP(v_hora_ini,'HH24:MI'),
                TO_TIMESTAMP(v_hora_fin,'HH24:MI'),
                v_tipo,
                v_costo,
                v_pago,
                UTIL_GET_FIELD(r.LINE,5)
            );
            COMMIT;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Turno error: '||SQLERRM);
            ROLLBACK;
        END;
    END LOOP;
END;
/

-- PROMPT ==== Generar Escala Mensual (ejemplo para cada centro) ====
DECLARE
    v_mes NUMBER := EXTRACT(MONTH FROM SYSDATE);
    v_anio NUMBER := EXTRACT(YEAR FROM SYSDATE);
BEGIN
    FOR c IN (SELECT ACM_ID FROM ACS_CENTRO_MEDICO WHERE ACM_ESTADO='ACTIVO') LOOP
        BEGIN
            PRC_GENERAR_ESCALA_MENSUAL(c.ACM_ID, v_mes, v_anio);
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Escala ya existe para centro '||c.ACM_ID||' o error: '||SQLERRM);
        END;
    END LOOP;
END;
/

-- PROMPT ==== Mostrar Escalas Generadas ====
DECLARE
    v_mes NUMBER := EXTRACT(MONTH FROM SYSDATE);
    v_anio NUMBER := EXTRACT(YEAR FROM SYSDATE);
BEGIN
    FOR c IN (SELECT ACM_ID FROM ACS_CENTRO_MEDICO WHERE ACM_ESTADO='ACTIVO') LOOP
        PRC_Consultar_Escalas(c.ACM_ID, v_mes, v_anio);
    END LOOP;
END;
/

-- PROMPT ==== Fin datos centros de salud ====

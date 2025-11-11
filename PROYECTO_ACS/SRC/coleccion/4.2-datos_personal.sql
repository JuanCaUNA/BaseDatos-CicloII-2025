-- Datos personal
-- ** REGISTRAR DATOS PERSONA **
DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APE_CEDULA,APE_NOMBRE,APE_P_APELLIDO,APE_S_APELLIDO,APE_FECHA_NACIMIENTO,APE_SEXO,APE_ESTADO_CIVIL,APE_NACIONALIDAD,APE_TIPO_USUARIO,APE_EMAIL,APE_TELEFONO,APE_RESIDENCIA,APE_DIRECCION_CASA,APE_DIRECCION_TRABAJO',
                'CED123456,Juan,Perez,Gomez,15/04/1985,MASCULINO,CASADO,NACIONAL,MEDICO,juan.perez@mail.com,555-1234,Ciudad A,Calle 123,Oficina 456',
                'CED234567,Maria,Lopez,Diaz,22/08/1990,FEMENINO,SOLTERO,EXTRANJERO,ADMINISTRATIVO,maria.lopez@mail.com,555-5678,Ciudad B,Calle 456,Oficina 789',
                'CED345678,Carlos,Ramirez,Suarez,10/12/1975,MASCULINO,DIVORCIADO,NACIONAL,MEDICO,carlos.ramirez@mail.com,555-9012,Ciudad C,Calle 789,Oficina 012',
                'CED456789,Ana,Martinez,Castro,05/03/1982,FEMENINO,CASADO,NACIONAL,ADMINISTRATIVO,ana.martinez@mail.com,555-3456,Ciudad D,Calle 234,Oficina 345',
                'CED567890,Jose,Gonzalez,Reyes,18/07/1988,MASCULINO,SOLTERO,EXTRANJERO,MEDICO,jose.gonzalez@mail.com,555-6789,Ciudad E,Calle 567,Oficina 678',
                'CED678901,Laura,Hernandez,Morales,25/11/1992,FEMENINO,UNION LIBRE,NACIONAL,ADMINISTRATIVO,laura.hernandez@mail.com,555-2345,Ciudad F,Calle 890,Oficina 901',
                'CED789012,Pedro,Alvarez,Rojas,30/09/1980,MASCULINO,VIUDO,NACIONAL,MEDICO,pedro.alvarez@mail.com,555-4567,Ciudad G,Calle 012,Oficina 123',
                'CED890123,Sofia,Jimenez,Ortiz,12/02/1987,FEMENINO,CASADO,EXTRANJERO,ADMINISTRATIVO,sofia.jimenez@mail.com,555-7890,Ciudad H,Calle 345,Oficina 456',
                'CED901234,Diego,Castillo,Padilla,08/06/1995,MASCULINO,SOLTERO,NACIONAL,MEDICO,diego.castillo@mail.com,555-0123,Ciudad I,Calle 678,Oficina 789',
                'CED012345,Valeria,Mendoza,Salas,19/01/1983,FEMENINO,DIVORCIADO,NACIONAL,ADMINISTRATIVO,valeria.mendoza@mail.com,555-3450,Ciudad J,Calle 901,Oficina 234',
                '118690700,Juan,Camacho,Solano,12/05/2000,MASCULINO,SOLTERO,NACIONAL,MEDICO,juancarlos19defebrero@gmail.com,3104567890,Bogota,Carrera 45 # 32-12,Empresa XYZ'
            )
        );
BEGIN
    FOR R_LINE IN C_LINES LOOP
        V_LINE := R_LINE.LINE;

        -- Saltar encabezado si existe
        IF V_PRIMERA_LINEA THEN
            V_PRIMERA_LINEA := FALSE;
            CONTINUE;
        END IF;
        
        BEGIN
            -- Llamar al procedimiento para insertar registro. UTIL_GET_FIELD(LINEA, POSICION)
            ACS_PRC_REGISTRO_PERSONA(
                P_APE_CEDULA => UTIL_GET_FIELD(V_LINE, 1),
                P_APE_NOMBRE => UTIL_GET_FIELD(V_LINE, 2),
                P_APE_P_APELLIDO => UTIL_GET_FIELD(V_LINE, 3),
                P_APE_S_APELLIDO => UTIL_GET_FIELD(V_LINE, 4),
                P_APE_FECHA_NACIMIENTO => TO_TIMESTAMP(UTIL_GET_FIELD(V_LINE, 5), 'DD/MM/YYYY'),
                P_APE_SEXO => UTIL_GET_FIELD(V_LINE, 6),
                P_APE_ESTADO_CIVIL => UTIL_GET_FIELD(V_LINE, 7),
                P_APE_NACIONALIDAD => UTIL_GET_FIELD(V_LINE, 8),
                P_APE_TIPO_USUARIO => UTIL_GET_FIELD(V_LINE, 9),
                P_APE_EMAIL => UTIL_GET_FIELD(V_LINE, 10),
                P_APE_TELEFONO => UTIL_GET_FIELD(V_LINE, 11),
                P_APE_RESIDENCIA => UTIL_GET_FIELD(V_LINE, 12),
                P_APE_DIRECCION_CASA => UTIL_GET_FIELD(V_LINE, 13),
                P_APE_DIRECCION_TRABAJO => UTIL_GET_FIELD(V_LINE, 14)
            );
        COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar registro');
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos: Proceso completado.');
END;
/

-- APROBAR O RECHAZAR. ACS_PRC_ACTUALIZAR_ESTADO_PERSONA(CEDULA, NEW_ESTADO)
BEGIN
    ACS_PRC_ACTUALIZAR_ESTADO_PERSONA('118690700', 'APROBADO');
    ACS_PRC_ACTUALIZAR_ESTADO_PERSONA('CED345678', 'APROBADO');
    ACS_PRC_ACTUALIZAR_ESTADO_PERSONA('CED678901', 'APROBADO');
    ACS_PRC_ACTUALIZAR_ESTADO_PERSONA('CED890123', 'APROBADO');

    ACS_PRC_ACTUALIZAR_ESTADO_PERSONA('CED234567', 'RECHAZADO');
    commit;
END;
/

-- ** REGISTRAR DATOS ACS_TIPO_DOCUMENTO **
DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'ATD_TIPO_USUARIO,ATD_DOCUMENTO_REQUERIDO',
                'TODOS,Cedula de Identidad',
                'TODOS,Certificado de Nacimiento',
                'TODOS,Curriculum Vitae',
                'MEDICO,Licencia Medica',
                'MEDICO,Certificado de Especialidad',
                'MEDICO,Titulo Universitario Medicina',
                'ADMINISTRATIVO,Titulo Universitario',
                'ADMINISTRATIVO,Certificados de Capacitacion'
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
            INSERT INTO ACS_TIPO_DOCUMENTO (ATD_TIPO_USUARIO, ATD_DOCUMENTO_REQUERIDO, ATD_ESTADO)
            VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                UTIL_GET_FIELD(V_LINE, 2),
                'ACTIVO'
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar tipo documento: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_TIPO_DOCUMENTO: Proceso completado.');
END;
/

-- ** REGISTRAR DATOS ACS_BANCO **
DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'ABA_NOMBRE,ABA_TELEFONO',
                'Banco Nacional de Costa Rica,2212-2000',
                'Banco de Costa Rica,2287-9000',
                'Banco Davivienda,2220-2020',
                'BAC Credomatic,2295-9595',
                'Banco Popular,2202-2000',
                'Scotiabank Costa Rica,2506-4000'
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
            INSERT INTO ACS_BANCO (ABA_NOMBRE, ABA_TELEFONO, ABA_ESTADO)
            VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                UTIL_GET_FIELD(V_LINE, 2),
                'ACTIVO'
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar banco: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_BANCO: Proceso completado.');
END;
/

-- ** REGISTRAR DATOS ACS_CUENTA_BANCARIA **
-- Para los usuarios aprobados: 118690700, CED345678, CED678901, CED890123
DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    V_AUS_ID NUMBER;
    V_ABA_ID NUMBER;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APE_CEDULA,ACB_NUMERO_CUENTA,ACB_ES_PRINCIPAL,ACB_TIPO_CUENTA,ABA_NOMBRE',
                '118690700,CR12015202001026284066,SI,AHORRO,Banco Nacional de Costa Rica',
                '118690700,CR79010200009292817840,NO,CORRIENTE,Banco de Costa Rica',
                'CED345678,CR45015202001034567890,SI,CORRIENTE,BAC Credomatic',
                'CED345678,CR23010200009298765432,NO,AHORRO,Banco Davivienda',
                'CED678901,CR67015202001045678901,SI,AHORRO,Banco Popular',
                'CED890123,CR89010200009287654321,SI,CORRIENTE,Scotiabank Costa Rica'
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
            -- Obtener ID del usuario basado en la cedula
            SELECT U.AUS_ID INTO V_AUS_ID
            FROM ACS_USUARIO U
            INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
            WHERE P.APE_CEDULA = UTIL_GET_FIELD(V_LINE, 1);
            
            -- Obtener ID del banco
            SELECT ABA_ID INTO V_ABA_ID
            FROM ACS_BANCO
            WHERE ABA_NOMBRE = UTIL_GET_FIELD(V_LINE, 5);
            
            INSERT INTO ACS_CUENTA_BANCARIA (
                ACB_NUMERO_CUENTA, 
                ACB_ES_PRINCIPAL, 
                ACB_TIPO_CUENTA, 
                ACB_ESTADO,
                AUS_ID, 
                ABA_ID
            )
            VALUES (
                UTIL_GET_FIELD(V_LINE, 2),
                UTIL_GET_FIELD(V_LINE, 3),
                UTIL_GET_FIELD(V_LINE, 4),
                'ACTIVO',
                V_AUS_ID,
                V_ABA_ID
            );
            COMMIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('[Error] No se encontro usuario o banco para cedula: ' || UTIL_GET_FIELD(V_LINE, 1));
                ROLLBACK;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar cuenta bancaria: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_CUENTA_BANCARIA: Proceso completado.');
END;
/

-- ** REGISTRAR DATOS ACS_DOCUMENTO_USUARIO **
-- Para los usuarios aprobados: 118690700, CED345678, CED678901, CED890123
DECLARE
    V_LINE VARCHAR2(2000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    V_AUS_ID NUMBER;
    V_ATD_ID NUMBER;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APE_CEDULA,ATD_DOCUMENTO_REQUERIDO,ADU_URL,ADU_COMENTARIOS,ADU_ESTADO',
                '118690700,Cedula de Identidad,https://docs.sistema.com/118690700_cedula.pdf,Cedula vigente,APROBADO',
                '118690700,Licencia Medica,https://docs.sistema.com/118690700_licencia.pdf,Licencia medica vigente hasta 2027,APROBADO',
                '118690700,Titulo Universitario Medicina,https://docs.sistema.com/118690700_titulo.pdf,Universidad de Costa Rica,APROBADO',
                'CED345678,Cedula de Identidad,https://docs.sistema.com/CED345678_cedula.pdf,Cedula actualizada,APROBADO',
                'CED345678,Licencia Medica,https://docs.sistema.com/CED345678_licencia.pdf,Licencia medica especialidad cardiologia,APROBADO',
                'CED345678,Certificado de Especialidad,https://docs.sistema.com/CED345678_especialidad.pdf,Especialista en Cardiologia,APROBADO',
                'CED678901,Cedula de Identidad,https://docs.sistema.com/CED678901_cedula.pdf,Documento en regla,APROBADO',
                'CED678901,Titulo Universitario,https://docs.sistema.com/CED678901_titulo.pdf,Licenciatura en Administracion,APROBADO',
                'CED678901,Certificados de Capacitacion,https://docs.sistema.com/CED678901_capacitacion.pdf,Cursos de gestion administrativa,APROBADO',
                'CED890123,Cedula de Identidad,https://docs.sistema.com/CED890123_cedula.pdf,Cedula vigente,APROBADO',
                'CED890123,Titulo Universitario,https://docs.sistema.com/CED890123_titulo.pdf,Contabilidad Publica,APROBADO',
                'CED890123,Curriculum Vitae,https://docs.sistema.com/CED890123_cv.pdf,CV actualizado 2025,APROBADO'
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
            -- Obtener ID del usuario basado en la cedula
            SELECT U.AUS_ID INTO V_AUS_ID
            FROM ACS_USUARIO U
            INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
            WHERE P.APE_CEDULA = UTIL_GET_FIELD(V_LINE, 1);
            
            -- Obtener ID del tipo de documento
            SELECT ATD_ID INTO V_ATD_ID
            FROM ACS_TIPO_DOCUMENTO
            WHERE ATD_DOCUMENTO_REQUERIDO = UTIL_GET_FIELD(V_LINE, 2)
            AND ROWNUM = 1;
            
            INSERT INTO ACS_DOCUMENTO_USUARIO (
                ADU_URL,
                ADU_COMENTARIOS,
                ADU_ESTADO,
                ATD_ID,
                AUS_ID
            )
            VALUES (
                UTIL_GET_FIELD(V_LINE, 3),
                UTIL_GET_FIELD(V_LINE, 4),
                UTIL_GET_FIELD(V_LINE, 5),
                V_ATD_ID,
                V_AUS_ID
            );
            COMMIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('[Error] No se encontro usuario o tipo documento para: ' || UTIL_GET_FIELD(V_LINE, 1));
                ROLLBACK;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar documento usuario: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_DOCUMENTO_USUARIO: Proceso completado.');
END;
/

-- ** REGISTRAR DATOS ACS_PERMISO **
DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APR_PANTALLA,APR_LEER,APR_CREAR,APR_EDITAR,APR_BORRAR',
                'PERSONAS,1,1,1,1',
                'USUARIOS,1,1,1,1',
                'BANCOS,1,1,1,0',
                'CUENTAS_BANCARIAS,1,1,1,0',
                'DOCUMENTOS,1,1,1,1',
                'PERFILES,1,1,1,0',
                'PERMISOS,1,0,1,0',
                'CENTROS_SALUD,1,1,1,0',
                'ESCALAS_MEDICAS,1,1,1,1',
                'PLANILLAS,1,1,1,0',
                'REPORTES_FINANCIEROS,1,0,0,0',
                'AUDITORIA,1,0,0,0'
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
            INSERT INTO ACS_PERMISO (
                APR_PANTALLA,
                APR_LEER,
                APR_CREAR,
                APR_EDITAR,
                APR_BORRAR
            )
            VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                TO_NUMBER(UTIL_GET_FIELD(V_LINE, 2)),
                TO_NUMBER(UTIL_GET_FIELD(V_LINE, 3)),
                TO_NUMBER(UTIL_GET_FIELD(V_LINE, 4)),
                TO_NUMBER(UTIL_GET_FIELD(V_LINE, 5))
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar permiso: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PERMISO: Proceso completado.');
END;
/

-- ** REGISTRAR DATOS ACS_PERFIL **
DECLARE
    V_LINE VARCHAR2(1000);
    V_PRIMERA_LINEA BOOLEAN := TRUE;
    
    CURSOR C_LINES IS
        SELECT COLUMN_VALUE AS LINE
        FROM TABLE(
            SYS.ODCIVARCHAR2LIST(
                'APF_NOMBRE,APF_DESCRIPCION',
                'SUPERUSUARIO,Acceso total al sistema con todos los permisos',
                'MEDICO,Perfil para personal medico con acceso a escalas y pacientes',
                'ADMINISTRATIVO,Perfil para personal administrativo con acceso a gestion general',
                'CONTADOR,Perfil especializado en gestion financiera y planillas',
                'RRHH,Perfil para recursos humanos con gestion de personal'
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
            INSERT INTO ACS_PERFIL (
                APF_NOMBRE,
                APF_DESCRIPCION,
                APF_PADRE_ID
            )
            VALUES (
                UTIL_GET_FIELD(V_LINE, 1),
                UTIL_GET_FIELD(V_LINE, 2),
                NULL
            );
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('[Error] insertar perfil: ' || SQLERRM);
                ROLLBACK;
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PERFIL: Proceso completado.');
END;
/

-- ** REGISTRAR DATOS ACS_PERFIL_PERMISO **
-- Vincular permisos a perfiles
DECLARE
    V_APF_ID NUMBER;
    V_APR_ID NUMBER;
BEGIN
    -- SUPERUSUARIO - todos los permisos
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'SUPERUSUARIO';
    
    FOR R IN (SELECT APR_ID FROM ACS_PERMISO) LOOP
        INSERT INTO ACS_PERFIL_PERMISO (APR_ID, APF_ID)
        VALUES (R.APR_ID, V_APF_ID);
    END LOOP;
    
    -- MEDICO - permisos especificos
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'MEDICO';
    
    FOR R IN (SELECT APR_ID FROM ACS_PERMISO 
            WHERE APR_PANTALLA IN ('CENTROS_SALUD', 'ESCALAS_MEDICAS', 'DOCUMENTOS', 'CUENTAS_BANCARIAS')) LOOP
        INSERT INTO ACS_PERFIL_PERMISO (APR_ID, APF_ID)
        VALUES (R.APR_ID, V_APF_ID);
    END LOOP;
    
    -- ADMINISTRATIVO - permisos de gestion general
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'ADMINISTRATIVO';
    
    FOR R IN (SELECT APR_ID FROM ACS_PERMISO 
            WHERE APR_PANTALLA IN ('PERSONAS', 'USUARIOS', 'BANCOS', 'DOCUMENTOS', 'REPORTES_FINANCIEROS')) LOOP
        INSERT INTO ACS_PERFIL_PERMISO (APR_ID, APF_ID)
        VALUES (R.APR_ID, V_APF_ID);
    END LOOP;
    
    -- CONTADOR - permisos financieros
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'CONTADOR';
    
    FOR R IN (SELECT APR_ID FROM ACS_PERMISO 
            WHERE APR_PANTALLA IN ('PLANILLAS', 'REPORTES_FINANCIEROS', 'CUENTAS_BANCARIAS', 'AUDITORIA')) LOOP
        INSERT INTO ACS_PERFIL_PERMISO (APR_ID, APF_ID)
        VALUES (R.APR_ID, V_APF_ID);
    END LOOP;
    
    -- RRHH - permisos de recursos humanos
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'RRHH';
    
    FOR R IN (SELECT APR_ID FROM ACS_PERMISO 
            WHERE APR_PANTALLA IN ('PERSONAS', 'USUARIOS', 'DOCUMENTOS', 'PERFILES', 'BANCOS', 'CUENTAS_BANCARIAS')) LOOP
        INSERT INTO ACS_PERFIL_PERMISO (APR_ID, APF_ID)
        VALUES (R.APR_ID, V_APF_ID);
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_PERFIL_PERMISO: Proceso completado.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] insertar perfil_permiso: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ** REGISTRAR DATOS ACS_USUARIO_PERFIL **
-- Asignar perfiles a usuarios aprobados
DECLARE
    V_AUS_ID NUMBER;
    V_APF_ID NUMBER;
BEGIN
    -- Usuario 118690700 (Juan Camacho) - MEDICO y SUPERUSUARIO
    SELECT U.AUS_ID INTO V_AUS_ID
    FROM ACS_USUARIO U
    INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
    WHERE P.APE_CEDULA = '118690700';
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'SUPERUSUARIO';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'MEDICO';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    -- Usuario CED345678 (Carlos Ramirez) - MEDICO
    SELECT U.AUS_ID INTO V_AUS_ID
    FROM ACS_USUARIO U
    INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
    WHERE P.APE_CEDULA = 'CED345678';
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'MEDICO';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    -- Usuario CED678901 (Laura Hernandez) - ADMINISTRATIVO y RRHH
    SELECT U.AUS_ID INTO V_AUS_ID
    FROM ACS_USUARIO U
    INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
    WHERE P.APE_CEDULA = 'CED678901';
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'ADMINISTRATIVO';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'RRHH';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    -- Usuario CED890123 (Sofia Jimenez) - ADMINISTRATIVO y CONTADOR
    SELECT U.AUS_ID INTO V_AUS_ID
    FROM ACS_USUARIO U
    INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
    WHERE P.APE_CEDULA = 'CED890123';
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'ADMINISTRATIVO';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    SELECT APF_ID INTO V_APF_ID FROM ACS_PERFIL WHERE APF_NOMBRE = 'CONTADOR';
    INSERT INTO ACS_USUARIO_PERFIL (APF_ID, AUS_ID) VALUES (V_APF_ID, V_AUS_ID);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[ok] Cargar datos ACS_USUARIO_PERFIL: Proceso completado.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Error] insertar usuario_perfil: ' || SQLERRM);
        ROLLBACK;
END;
/

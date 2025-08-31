-- SCRIPT DE CREACIÓN DE TABLAS PARA ORACLE
-- Basado en los módulos: Personal, Centro de Salud, y Planillas

-- Limpieza de tablas previas (en orden inverso de dependencias)
BEGIN
   -- Módulo Planillas
   EXECUTE IMMEDIATE 'DROP TABLE procedimiento_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE turno_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE bitacora_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE envio_comprobante CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE movimiento_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE detalle_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE personal_tipo_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE tipo_movimiento CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE tipo_planilla CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Módulo Centro Salud
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE escala_mensual_detalle CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE escala_mensual CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE escala_semanal CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE procedimiento_detalle CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE procedimiento CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE turno CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE puesto_medico CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE centro_salud CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Módulo Personal
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE administrativo CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE medico CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE cuenta_bancaria CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE documento CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE detalle_documento CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE permiso CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE accesos CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE preregistro CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE usuario CASCADE CONSTRAINTS' ; EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ========================= CREACIÓN DE TABLAS DEL MÓDULO PERSONAL =========================

-- Tabla Usuario
CREATE TABLE ACS_usuario (
    usuario_id NUMBER PRIMARY KEY,
    cedula VARCHAR2(50) UNIQUE,
    nombre VARCHAR2(100) NOT NULL,
    apellidos VARCHAR2(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo VARCHAR2(10) NOT NULL,
    estado_civil VARCHAR2(30) NOT NULL,
    nacionalidad VARCHAR2(15) NOT NULL CHECK (nacionalidad IN ('NACIONAL', 'EXTRANJERO')),
    email VARCHAR2(150) UNIQUE NOT NULL,
    telefono VARCHAR2(30) NOT NULL,
    residencia VARCHAR2(200) NOT NULL,
    direccion_casa VARCHAR2(200) NOT NULL,
    direccion_trabajo VARCHAR2(200) NOT NULL
);

-- Secuencia para usuario
CREATE SEQUENCE usuario_seq START WITH 1 INCREMENT BY 1;

-- Tabla Preregistro
CREATE TABLE ACS_preregistro (
    preregistro_id NUMBER PRIMARY KEY,
    cedula VARCHAR2(50) UNIQUE,
    nombre VARCHAR2(100) NOT NULL,
    apellidos VARCHAR2(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo VARCHAR2(10) NOT NULL,
    estado_civil VARCHAR2(30) NOT NULL,
    nacionalidad VARCHAR2(15) NOT NULL CHECK (nacionalidad IN ('NACIONAL', 'EXTRANJERO')),
    email VARCHAR2(150) UNIQUE NOT NULL,
    telefono VARCHAR2(30) NOT NULL,
    direccion_casa VARCHAR2(200) NOT NULL,
    direccion_trabajo VARCHAR2(200) NOT NULL,
    residencia VARCHAR2(200) NOT NULL,
    estado_registro VARCHAR2(20) DEFAULT 'PENDIENTE' CHECK (estado_registro IN ('PENDIENTE', 'APROBADO', 'RECHAZADO'))
);

-- Secuencia para preregistro
CREATE SEQUENCE preregistro_seq START WITH 1 INCREMENT BY 1;

-- Tabla Accesos
CREATE TABLE ACS_accesos (
    accesos_id NUMBER PRIMARY KEY,
    tipo_usuario VARCHAR2(20) NOT NULL CHECK (tipo_usuario IN ('MEDICO', 'ADMINISTRATIVO'))
);

-- Secuencia para accesos
CREATE SEQUENCE accesos_seq START WITH 1 INCREMENT BY 1;

-- Tabla Permiso
CREATE TABLE ACS_permiso (
    permiso_id NUMBER PRIMARY KEY,
    pantalla VARCHAR2(100) UNIQUE NOT NULL,
    lectura NUMBER(1) DEFAULT 0 CHECK (lectura IN (0, 1)),
    escritura NUMBER(1) DEFAULT 0 CHECK (escritura IN (0, 1)),
    eliminacion NUMBER(1) DEFAULT 0 CHECK (eliminacion IN (0, 1)),
    accesos_id NUMBER,
    CONSTRAINT fk_permiso_accesos FOREIGN KEY (accesos_id) REFERENCES accesos(id)
);

-- Secuencia para permiso
CREATE SEQUENCE permiso_seq START WITH 1 INCREMENT BY 1;

-- Tabla DetalleDocumento
CREATE TABLE ACS_detalle_documento (
    detalle_documento_id NUMBER PRIMARY KEY,
    tipo_usuario VARCHAR2(20) NOT NULL CHECK (tipo_usuario IN ('MEDICO', 'ADMINISTRATIVO')),
    documentos_requeridos VARCHAR2(4000) NOT NULL
);

-- Secuencia para detalle_documento
CREATE SEQUENCE detalle_documento_seq START WITH 1 INCREMENT BY 1;

-- Tabla Medico
CREATE TABLE ACS_medico (
    medico_id NUMBER PRIMARY KEY,
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    tipo_usuario VARCHAR2(20) DEFAULT 'MEDICO' CHECK (tipo_usuario = 'MEDICO'),
    usuario_id NUMBER UNIQUE,
    CONSTRAINT fk_medico_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

-- Secuencia para medico
CREATE SEQUENCE medico_seq START WITH 1 INCREMENT BY 1;

-- Tabla Administrativo
CREATE TABLE ACS_administrativo (
    administrativo_id NUMBER PRIMARY KEY,
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    tipo_usuario VARCHAR2(20) DEFAULT 'ADMINISTRATIVO' CHECK (tipo_usuario = 'ADMINISTRATIVO'),
    usuario_id NUMBER UNIQUE,
    CONSTRAINT fk_admin_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

-- Secuencia para administrativo
CREATE SEQUENCE administrativo_seq START WITH 1 INCREMENT BY 1;

-- Tabla Documento
CREATE TABLE ACS_documento (
    documento_id NUMBER PRIMARY KEY,
    url VARCHAR2(255) UNIQUE NOT NULL,
    descripcion VARCHAR2(255) NOT NULL,
    medico_id NUMBER,
    administrativo_id NUMBER,
    CONSTRAINT fk_doc_medico FOREIGN KEY (medico_id) REFERENCES medico(id),
    CONSTRAINT fk_doc_admin FOREIGN KEY (administrativo_id) REFERENCES administrativo(id),
    CONSTRAINT ck_doc_tipo CHECK (
        (medico_id IS NOT NULL AND administrativo_id IS NULL) OR 
        (medico_id IS NULL AND administrativo_id IS NOT NULL)
    )
);

-- Secuencia para documento
CREATE SEQUENCE documento_seq START WITH 1 INCREMENT BY 1;

-- Tabla CuentaBancaria
CREATE TABLE ACS_cuenta_bancaria (
    cuenta_bancaria_id NUMBER PRIMARY KEY,
    banco VARCHAR2(100) NOT NULL,
    numero VARCHAR2(50) UNIQUE NOT NULL,
    titular VARCHAR2(200) NOT NULL,
    tipo_cuenta VARCHAR2(20) NOT NULL CHECK (tipo_cuenta IN ('AHORROS', 'CORRIENTE')),
    es_principal NUMBER(1) NOT NULL CHECK (es_principal IN (0, 1)),
    usuario_id NUMBER,
    CONSTRAINT fk_cuenta_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

-- Secuencia para cuenta_bancaria
CREATE SEQUENCE cuenta_bancaria_seq START WITH 1 INCREMENT BY 1;

-- ========================= CREACIÓN DE TABLAS DEL MÓDULO CENTRO DE SALUD =========================

-- Tabla centro_salud
CREATE TABLE ACS_centro_salud (
    centro_salud_id NUMBER PRIMARY KEY,
    nombre VARCHAR2(150) NOT NULL,
    ubicacion VARCHAR2(255) NOT NULL,
    contacto VARCHAR2(150),
    telefono VARCHAR2(50),
    email VARCHAR2(150),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

-- Secuencia para centro_salud
CREATE SEQUENCE centro_salud_seq START WITH 1 INCREMENT BY 1;

-- Tabla puesto_medico
CREATE TABLE ACS_puesto_medico (
    puesto_medico_id NUMBER PRIMARY KEY,
    centro_salud_id NUMBER NOT NULL,
    especialidad VARCHAR2(150) NOT NULL,
    descripcion VARCHAR2(4000),
    costo_turno NUMBER(18,2) DEFAULT 0.0 NOT NULL,
    pago_turno NUMBER(18,2) DEFAULT 0.0 NOT NULL,
    pago_hora NUMBER(18,2),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_puesto_centro FOREIGN KEY (centro_salud_id) REFERENCES centro_salud(id)
);

-- Secuencia para puesto_medico
CREATE SEQUENCE puesto_medico_seq START WITH 1 INCREMENT BY 1;

-- Tabla turno
CREATE TABLE ACS_turno (
    turno_id NUMBER PRIMARY KEY,
    puesto_id NUMBER NOT NULL,
    nombre VARCHAR2(50) NOT NULL,
    hora_inicio_min NUMBER NOT NULL,
    hora_fin_min NUMBER NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_turno_puesto FOREIGN KEY (puesto_id) REFERENCES puesto_medico(id)
);

-- Secuencia para turno
CREATE SEQUENCE turno_seq START WITH 1 INCREMENT BY 1;

-- Tabla procedimiento
CREATE TABLE ACS_procedimiento (
    procedimiento_id NUMBER PRIMARY KEY,
    centro_salud_id NUMBER NOT NULL,
    nombre VARCHAR2(150) NOT NULL,
    descripcion VARCHAR2(4000),
    costo_centro NUMBER(18,2) DEFAULT 0.0 NOT NULL,
    pago_medico NUMBER(18,2) DEFAULT 0.0 NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_proc_centro FOREIGN KEY (centro_salud_id) REFERENCES centro_salud(id)
);

-- Secuencia para procedimiento
CREATE SEQUENCE procedimiento_seq START WITH 1 INCREMENT BY 1;

-- Tabla procedimiento_detalle
CREATE TABLE ACS_procedimiento_detalle (
    procedimiento_detalle_id NUMBER PRIMARY KEY,
    procedimiento_id NUMBER NOT NULL,
    medico_id NUMBER NOT NULL,
    fecha DATE NOT NULL,
    observaciones VARCHAR2(4000),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_procdet_proc FOREIGN KEY (procedimiento_id) REFERENCES procedimiento(id),
    CONSTRAINT fk_procdet_medico FOREIGN KEY (medico_id) REFERENCES medico(id)
);

-- Secuencia para procedimiento_detalle
CREATE SEQUENCE procedimiento_detalle_seq START WITH 1 INCREMENT BY 1;

-- Tabla escala_semanal
CREATE TABLE ACS_escala_semanal (
    escala_semanal_id NUMBER PRIMARY KEY,
    puesto_id NUMBER NOT NULL,
    turno_id NUMBER NOT NULL,
    semana NUMBER NOT NULL,
    anio NUMBER NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_escsem_puesto FOREIGN KEY (puesto_id) REFERENCES puesto_medico(id),
    CONSTRAINT fk_escsem_turno FOREIGN KEY (turno_id) REFERENCES turno(id),
    CONSTRAINT uk_escala_semanal UNIQUE (puesto_id, turno_id, semana, anio)
);

-- Secuencia para escala_semanal
CREATE SEQUENCE escala_semanal_seq START WITH 1 INCREMENT BY 1;

-- Tabla escala_mensual
CREATE TABLE ACS_escala_mensual (
    escala_mensual_id NUMBER PRIMARY KEY,
    centro_id NUMBER NOT NULL,
    mes NUMBER NOT NULL,
    anio NUMBER NOT NULL,
    estado VARCHAR2(20) DEFAULT 'CONSTRUCCION' CHECK (estado IN ('CONSTRUCCION', 'VIGENTE', 'REVISION', 'LISTA_PAGO', 'PROCESADA')),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_escmen_centro FOREIGN KEY (centro_id) REFERENCES centro_salud(id),
    CONSTRAINT uk_escala_mensual UNIQUE (centro_id, mes, anio)
);

-- Secuencia para escala_mensual
CREATE SEQUENCE escala_mensual_seq START WITH 1 INCREMENT BY 1;

-- Tabla escala_mensual_detalle
CREATE TABLE ACS_escala_mensual_detalle (
    escala_mensual_detalle_id NUMBER PRIMARY KEY,
    escala_mensual_id NUMBER NOT NULL,
    escala_semanal_id NUMBER,
    medico_id NUMBER,
    fecha DATE NOT NULL,
    trabajada CHAR(1) DEFAULT 'N' CHECK (trabajada IN ('S', 'N')),
    hora_real_inicio TIMESTAMP,
    hora_real_fin TIMESTAMP,
    observacion_cambio VARCHAR2(4000),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_escmendet_escmen FOREIGN KEY (escala_mensual_id) REFERENCES escala_mensual(id),
    CONSTRAINT fk_escmendet_escsem FOREIGN KEY (escala_semanal_id) REFERENCES escala_semanal(id),
    CONSTRAINT fk_escmendet_medico FOREIGN KEY (medico_id) REFERENCES medico(id),
    CONSTRAINT uk_escala_mensual_detalle UNIQUE (escala_mensual_id, fecha, escala_semanal_id, medico_id)
);

-- Secuencia para escala_mensual_detalle
CREATE SEQUENCE escala_mensual_detalle_seq START WITH 1 INCREMENT BY 1;

-- ========================= CREACIÓN DE TABLAS DEL MÓDULO PLANILLAS =========================

-- Tabla tipo_planilla
CREATE TABLE ACS_tipo_planilla (
    tipo_planilla_id NUMBER PRIMARY KEY,
    nombre VARCHAR2(80) NOT NULL,
    aplica_a VARCHAR2(20) NOT NULL CHECK (aplica_a IN ('ADMINISTRATIVO', 'MEDICO', 'AMBOS')),
    descripcion VARCHAR2(255),
    activo NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1))
);

-- Secuencia para tipo_planilla
CREATE SEQUENCE tipo_planilla_seq START WITH 1 INCREMENT BY 1;

-- Tabla tipo_movimiento
CREATE TABLE ACS_tipo_movimiento (
    tipo_movimiento_id NUMBER PRIMARY KEY,
    codigo VARCHAR2(40) UNIQUE NOT NULL,
    nombre VARCHAR2(120) NOT NULL,
    naturaleza VARCHAR2(20) NOT NULL CHECK (naturaleza IN ('INGRESO', 'DEDUCCION')),
    aplica_a VARCHAR2(20) NOT NULL CHECK (aplica_a IN ('ADMINISTRATIVO', 'MEDICO', 'AMBOS')),
    modo VARCHAR2(20) NOT NULL CHECK (modo IN ('FIJO', 'PORCENTAJE')),
    base VARCHAR2(20) NOT NULL CHECK (base IN ('BRUTO', 'SALARIO_BASE', 'HORAS', 'PROCEDIMIENTOS', 'PERSONALIZADA')),
    porcentaje NUMBER(8,4),
    monto_fijo NUMBER(18,2),
    es_automatico NUMBER(1) DEFAULT 1 CHECK (es_automatico IN (0, 1)),
    prioridad NUMBER DEFAULT 100,
    activo NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    regla_json CLOB,
    creado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    actualizado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

-- Secuencia para tipo_movimiento
CREATE SEQUENCE tipo_movimiento_seq START WITH 1 INCREMENT BY 1;

-- Tabla personal_tipo_planilla
CREATE TABLE ACS_personal_tipo_planilla (
    personal_tipo_planilla_id NUMBER PRIMARY KEY,
    personal_id NUMBER NOT NULL,
    tipo_planilla_id NUMBER NOT NULL,
    activo NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    asignado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_pertipoplan_tipoplan FOREIGN KEY (tipo_planilla_id) REFERENCES tipo_planilla(id),
    CONSTRAINT uk_personal_tipo_planilla UNIQUE (personal_id, tipo_planilla_id)
);

-- Secuencia para personal_tipo_planilla
CREATE SEQUENCE personal_tipo_planilla_seq START WITH 1 INCREMENT BY 1;

-- Tabla planilla
CREATE TABLE ACS_planilla (
    planilla_id NUMBER PRIMARY KEY,
    tipo_planilla_id NUMBER NOT NULL,
    periodo_anio NUMBER NOT NULL,
    periodo_mes NUMBER NOT NULL,
    estado VARCHAR2(20) DEFAULT 'CONSTRUCCION' CHECK (estado IN ('CONSTRUCCION', 'APROBADA', 'PROCESADA', 'NOTIFICADA')),
    fecha_generacion TIMESTAMP,
    fecha_aprobacion TIMESTAMP,
    fecha_procesada TIMESTAMP,
    fecha_notificada TIMESTAMP,
    total_bruto NUMBER(18,2) DEFAULT 0 NOT NULL,
    total_deducciones NUMBER(18,2) DEFAULT 0 NOT NULL,
    total_neto NUMBER(18,2) DEFAULT 0 NOT NULL,
    creado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    actualizado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_planilla_tipoplan FOREIGN KEY (tipo_planilla_id) REFERENCES tipo_planilla(id),
    CONSTRAINT uk_planilla UNIQUE (tipo_planilla_id, periodo_anio, periodo_mes)
);

-- Secuencia para planilla
CREATE SEQUENCE planilla_seq START WITH 1 INCREMENT BY 1;

-- Crear índice en tipo_planilla_id
CREATE INDEX idx_planilla_tipo ON planilla(tipo_planilla_id);

-- Tabla detalle_planilla
CREATE TABLE ACS_detalle_planilla (
    detalle_planilla_id NUMBER PRIMARY KEY,
    planilla_id NUMBER NOT NULL,
    personal_id NUMBER NOT NULL,
    tipo_personal VARCHAR2(20) NOT NULL,
    salario_base NUMBER(18,2) DEFAULT 0 NOT NULL,
    bruto NUMBER(18,2) DEFAULT 0 NOT NULL,
    deducciones NUMBER(18,2) DEFAULT 0 NOT NULL,
    neto NUMBER(18,2) DEFAULT 0 NOT NULL,
    cuenta_bancaria_id NUMBER,
    notificado_en TIMESTAMP,
    email_enviado NUMBER(1) DEFAULT 0 CHECK (email_enviado IN (0, 1)),
    comprobante_html CLOB,
    creado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    actualizado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_detplan_planilla FOREIGN KEY (planilla_id) REFERENCES planilla(id),
    CONSTRAINT fk_detplan_cuentabanc FOREIGN KEY (cuenta_bancaria_id) REFERENCES cuenta_bancaria(id),
    CONSTRAINT uk_detalle_planilla UNIQUE (planilla_id, personal_id)
);

-- Secuencia para detalle_planilla
CREATE SEQUENCE detalle_planilla_seq START WITH 1 INCREMENT BY 1;

-- Crear índices
CREATE INDEX idx_detplan_planilla ON detalle_planilla(planilla_id);
CREATE INDEX idx_detplan_personal ON detalle_planilla(personal_id);
CREATE INDEX idx_detplan_cuenta ON detalle_planilla(cuenta_bancaria_id);

-- Tabla movimiento_planilla
CREATE TABLE ACS_movimiento_planilla (
    movimiento_planilla_id NUMBER PRIMARY KEY,
    detalle_planilla_id NUMBER NOT NULL,
    tipo_movimiento_id NUMBER NOT NULL,
    fuente VARCHAR2(20) DEFAULT 'AUTOMATICO' CHECK (fuente IN ('AUTOMATICO', 'MANUAL')),
    monto NUMBER(18,2) NOT NULL,
    observacion VARCHAR2(255),
    calculo_json CLOB,
    creado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_movplan_detplan FOREIGN KEY (detalle_planilla_id) REFERENCES detalle_planilla(id),
    CONSTRAINT fk_movplan_tipomov FOREIGN KEY (tipo_movimiento_id) REFERENCES tipo_movimiento(id)
);

-- Secuencia para movimiento_planilla
CREATE SEQUENCE movimiento_planilla_seq START WITH 1 INCREMENT BY 1;

-- Crear índices
CREATE INDEX idx_movplan_detplan ON movimiento_planilla(detalle_planilla_id);
CREATE INDEX idx_movplan_tipomov ON movimiento_planilla(tipo_movimiento_id);

-- Tabla envio_comprobante
CREATE TABLE ACS_envio_comprobante (
    envio_comprobante_id NUMBER PRIMARY KEY,
    detalle_planilla_id NUMBER NOT NULL,
    email VARCHAR2(150) NOT NULL,
    enviado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    error VARCHAR2(255),
    CONSTRAINT fk_envcom_detplan FOREIGN KEY (detalle_planilla_id) REFERENCES detalle_planilla(id)
);

-- Secuencia para envio_comprobante
CREATE SEQUENCE envio_comprobante_seq START WITH 1 INCREMENT BY 1;

-- Crear índice
CREATE INDEX idx_envcom_detplan ON envio_comprobante(detalle_planilla_id);

-- Tabla bitacora_planilla
CREATE TABLE ACS_bitacora_planilla (
    bitacora_planilla_id NUMBER PRIMARY KEY,
    planilla_id NUMBER NOT NULL,
    accion VARCHAR2(30) NOT NULL CHECK (accion IN ('CREAR', 'GENERAR_DETALLES', 'APROBAR', 'APLICAR', 'ENVIAR_COMPROBANTES', 'REVERTIR')),
    detalle VARCHAR2(255),
    actor_id NUMBER,
    creado_en TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_bitplan_planilla FOREIGN KEY (planilla_id) REFERENCES planilla(id)
);

-- Secuencia para bitacora_planilla
CREATE SEQUENCE bitacora_planilla_seq START WITH 1 INCREMENT BY 1;

-- Crear índices
CREATE INDEX idx_bitplan_planilla ON bitacora_planilla(planilla_id);
CREATE INDEX idx_bitplan_actor ON bitacora_planilla(actor_id);

-- Tabla turno_planilla
CREATE TABLE ACS_turno_planilla (
    turno_planilla_id NUMBER PRIMARY KEY,
    detalle_planilla_id NUMBER NOT NULL,
    escala_mensual_detalle_id NUMBER NOT NULL,
    horas NUMBER(10,2) NOT NULL,
    monto_cobrado_centro NUMBER(18,2) NOT NULL,
    monto_pagado_medico NUMBER(18,2) NOT NULL,
    procesado NUMBER(1) DEFAULT 0 CHECK (procesado IN (0, 1)),
    procesado_en TIMESTAMP,
    CONSTRAINT fk_turnplan_detplan FOREIGN KEY (detalle_planilla_id) REFERENCES detalle_planilla(id),
    CONSTRAINT fk_turnplan_escmendet FOREIGN KEY (escala_mensual_detalle_id) REFERENCES escala_mensual_detalle(id)
);

-- Secuencia para turno_planilla
CREATE SEQUENCE turno_planilla_seq START WITH 1 INCREMENT BY 1;

-- Crear índices
CREATE INDEX idx_turnplan_detplan ON turno_planilla(detalle_planilla_id);
CREATE INDEX idx_turnplan_escmendet ON turno_planilla(escala_mensual_detalle_id);

-- Tabla procedimiento_planilla
CREATE TABLE ACS_procedimiento_planilla (
    procedimiento_planilla_id NUMBER PRIMARY KEY,
    detalle_planilla_id NUMBER NOT NULL,
    procedimiento_id NUMBER NOT NULL,
    cantidad NUMBER DEFAULT 1 NOT NULL,
    monto_cobrado NUMBER(18,2) NOT NULL,
    monto_pagado_medico NUMBER(18,2) NOT NULL,
    procesado NUMBER(1) DEFAULT 0 CHECK (procesado IN (0, 1)),
    procesado_en TIMESTAMP,
    CONSTRAINT fk_procplan_detplan FOREIGN KEY (detalle_planilla_id) REFERENCES detalle_planilla(id),
    CONSTRAINT fk_procplan_proc FOREIGN KEY (procedimiento_id) REFERENCES procedimiento(id)
);

-- Secuencia para procedimiento_planilla
CREATE SEQUENCE procedimiento_planilla_seq START WITH 1 INCREMENT BY 1;

-- Crear índices
CREATE INDEX idx_procplan_detplan ON procedimiento_planilla(detalle_planilla_id);
CREATE INDEX idx_procplan_proc ON procedimiento_planilla(procedimiento_id);

-- Crear triggers para secuencias
CREATE OR REPLACE TRIGGER trg_usuario_bi
BEFORE INSERT ON usuario
FOR EACH ROW
BEGIN
    SELECT usuario_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_preregistro_bi
BEFORE INSERT ON preregistro
FOR EACH ROW
BEGIN
    SELECT preregistro_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_accesos_bi
BEFORE INSERT ON accesos
FOR EACH ROW
BEGIN
    SELECT accesos_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_permiso_bi
BEFORE INSERT ON permiso
FOR EACH ROW
BEGIN
    SELECT permiso_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_detalle_documento_bi
BEFORE INSERT ON detalle_documento
FOR EACH ROW
BEGIN
    SELECT detalle_documento_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_medico_bi
BEFORE INSERT ON medico
FOR EACH ROW
BEGIN
    SELECT medico_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_administrativo_bi
BEFORE INSERT ON administrativo
FOR EACH ROW
BEGIN
    SELECT administrativo_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_documento_bi
BEFORE INSERT ON documento
FOR EACH ROW
BEGIN
    SELECT documento_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_cuenta_bancaria_bi
BEFORE INSERT ON cuenta_bancaria
FOR EACH ROW
BEGIN
    SELECT cuenta_bancaria_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_centro_salud_bi
BEFORE INSERT ON centro_salud
FOR EACH ROW
BEGIN
    SELECT centro_salud_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_puesto_medico_bi
BEFORE INSERT ON puesto_medico
FOR EACH ROW
BEGIN
    SELECT puesto_medico_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_turno_bi
BEFORE INSERT ON turno
FOR EACH ROW
BEGIN
    SELECT turno_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_procedimiento_bi
BEFORE INSERT ON procedimiento
FOR EACH ROW
BEGIN
    SELECT procedimiento_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_procedimiento_detalle_bi
BEFORE INSERT ON procedimiento_detalle
FOR EACH ROW
BEGIN
    SELECT procedimiento_detalle_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_escala_semanal_bi
BEFORE INSERT ON escala_semanal
FOR EACH ROW
BEGIN
    SELECT escala_semanal_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_escala_mensual_bi
BEFORE INSERT ON escala_mensual
FOR EACH ROW
BEGIN
    SELECT escala_mensual_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_escala_mensual_detalle_bi
BEFORE INSERT ON escala_mensual_detalle
FOR EACH ROW
BEGIN
    SELECT escala_mensual_detalle_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_tipo_planilla_bi
BEFORE INSERT ON tipo_planilla
FOR EACH ROW
BEGIN
    SELECT tipo_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_tipo_movimiento_bi
BEFORE INSERT ON tipo_movimiento
FOR EACH ROW
BEGIN
    SELECT tipo_movimiento_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_personal_tipo_planilla_bi
BEFORE INSERT ON personal_tipo_planilla
FOR EACH ROW
BEGIN
    SELECT personal_tipo_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_planilla_bi
BEFORE INSERT ON planilla
FOR EACH ROW
BEGIN
    SELECT planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_detalle_planilla_bi
BEFORE INSERT ON detalle_planilla
FOR EACH ROW
BEGIN
    SELECT detalle_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_movimiento_planilla_bi
BEFORE INSERT ON movimiento_planilla
FOR EACH ROW
BEGIN
    SELECT movimiento_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_envio_comprobante_bi
BEFORE INSERT ON envio_comprobante
FOR EACH ROW
BEGIN
    SELECT envio_comprobante_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_bitacora_planilla_bi
BEFORE INSERT ON bitacora_planilla
FOR EACH ROW
BEGIN
    SELECT bitacora_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_turno_planilla_bi
BEFORE INSERT ON turno_planilla
FOR EACH ROW
BEGIN
    SELECT turno_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER trg_procedimiento_planilla_bi
BEFORE INSERT ON procedimiento_planilla
FOR EACH ROW
BEGIN
    SELECT procedimiento_planilla_seq.NEXTVAL INTO :NEW.id FROM DUAL;
END;
/

COMMIT;

-- Fin del script de creación
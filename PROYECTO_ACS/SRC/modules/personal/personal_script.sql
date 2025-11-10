prompt PL/SQL Developer Export Tables for user JUAN@ORCLPDB
prompt Created by juanc on domingo, 9 de noviembre de 2025
set feedback off
set define off

prompt Dropping ACS_BANCO...
drop table ACS_BANCO cascade constraints;
prompt Dropping ACS_PERSONA...
drop table ACS_PERSONA cascade constraints;
prompt Dropping ACS_USUARIO...
drop table ACS_USUARIO cascade constraints;
prompt Dropping ACS_CUENTA_BANCARIA...
drop table ACS_CUENTA_BANCARIA cascade constraints;
prompt Dropping ACS_TIPO_DOCUMENTO...
drop table ACS_TIPO_DOCUMENTO cascade constraints;
prompt Dropping ACS_DOCUMENTO_USUARIO...
drop table ACS_DOCUMENTO_USUARIO cascade constraints;
prompt Dropping ACS_PERFIL...
drop table ACS_PERFIL cascade constraints;
prompt Dropping ACS_PERMISO...
drop table ACS_PERMISO cascade constraints;
prompt Dropping ACS_PERFIL_PERMISO...
drop table ACS_PERFIL_PERMISO cascade constraints;
prompt Dropping ACS_USUARIO_PERFIL...
drop table ACS_USUARIO_PERFIL cascade constraints;
prompt Creating ACS_BANCO...
create table ACS_BANCO
(
  aba_id       NUMBER generated always as identity,
  aba_nombre   VARCHAR2(100) not null,
  aba_telefono VARCHAR2(20),
  aba_estado   VARCHAR2(10) default 'ACTIVO' not null
)
;
comment on table ACS_BANCO
  is 'Tabla para representa, manejar y almacenar bamco que hay en el sistema';
comment on column ACS_BANCO.aba_id
  is 'ID unico de cada banco';
comment on column ACS_BANCO.aba_nombre
  is 'Nombre propio y unico de cada banco';
comment on column ACS_BANCO.aba_telefono
  is '+506 8888 8888';
comment on column ACS_BANCO.aba_estado
  is 'Estado: ACTIVO, INACTIVO. Para visibilidad ';
create unique index UQ_ABA_NOMBRE on ACS_BANCO (ABA_NOMBRE);
alter table ACS_BANCO
  add constraint PK_ACS_BANCO primary key (ABA_ID);
alter table ACS_BANCO
  add constraint CHK_ABA_ESTADO
  check (ABA_ESTADO IN ('ACTIVO', 'INACTIVO', 'ARCHIVADO', 'SUSPENDIDO'));

prompt Creating ACS_PERSONA...
create table ACS_PERSONA
(
  ape_id                  NUMBER generated always as identity,
  ape_cedula              VARCHAR2(20) not null,
  ape_nombre              VARCHAR2(200) not null,
  ape_p_apellido          VARCHAR2(100) not null,
  ape_s_apellido          VARCHAR2(100),
  ape_fecha_nacimiento    TIMESTAMP(6) not null,
  ape_sexo                VARCHAR2(10),
  ape_estado_civil        VARCHAR2(15),
  ape_nacionalidad        VARCHAR2(10),
  ape_tipo_usuario        VARCHAR2(15) not null,
  ape_estado_registro     VARCHAR2(10) not null,
  ape_email               VARCHAR2(255) not null,
  ape_telefono            VARCHAR2(20),
  ape_residencia          VARCHAR2(255),
  ape_direcion_casa       VARCHAR2(255),
  ape_direccion_trabajo   VARCHAR2(255),
  ape_fecha_creacion      TIMESTAMP(6) default SYSDATE not null,
  ape_fecha_actualizacion TIMESTAMP(6) not null
)
;
comment on table ACS_PERSONA
  is 'Tabla para representa, manejar y almacenar personal que hay en el sistema';
comment on column ACS_PERSONA.ape_cedula
  is 'Unico';
comment on column ACS_PERSONA.ape_nombre
  is 'Requerido';
comment on column ACS_PERSONA.ape_p_apellido
  is 'Requerido';
comment on column ACS_PERSONA.ape_s_apellido
  is 'Opcional';
comment on column ACS_PERSONA.ape_fecha_nacimiento
  is 'Requerido';
comment on column ACS_PERSONA.ape_sexo
  is 'MASCULINO, FEMENINO, OTRO';
comment on column ACS_PERSONA.ape_tipo_usuario
  is 'Evalua para que puesto aplica el usuario, no cambia una vez definido
valores: MEDICO, ADMINISTRATIVO';
comment on column ACS_PERSONA.ape_estado_registro
  is 'Estado para saber el tipo de estado de persona, si esta aceptado no se borra. Valores: PENDIENTE, ACEPTADO, RECHAZADO
';
comment on column ACS_PERSONA.ape_email
  is 'Unico';
comment on column ACS_PERSONA.ape_telefono
  is '+506 8888 8888';
comment on column ACS_PERSONA.ape_residencia
  is 'Lugar donde vive';
comment on column ACS_PERSONA.ape_direcion_casa
  is 'Direccion exacta donde vive';
comment on column ACS_PERSONA.ape_direccion_trabajo
  is 'Direccion exacta del lugar de trabajo';
comment on column ACS_PERSONA.ape_fecha_creacion
  is 'Automatico';
comment on column ACS_PERSONA.ape_fecha_actualizacion
  is 'Automatico';
create index IDX_APE_NOMBRE on ACS_PERSONA (APE_NOMBRE, APE_P_APELLIDO, APE_S_APELLIDO);
create unique index UQ_APE_CEDULA on ACS_PERSONA (APE_CEDULA);
create unique index UQ_APE_EMAIL on ACS_PERSONA (APE_EMAIL);
alter table ACS_PERSONA
  add constraint PK_ACS_PERSONA primary key (APE_ID);
alter table ACS_PERSONA
  add constraint CHK_APE_ESTADO_CIVIL
  check (APE_ESTADO_CIVIL IN ('SOLTERO', 'CASADO', 'DIVORCIADO', 'VIUDO', 'UNION LIBRE'));
alter table ACS_PERSONA
  add constraint CHK_APE_ESTADO_REGISTRO
  check (APE_ESTADO_REGISTRO IN ('PENDIENTE', 'APROBADO', 'RECHAZADO'));
alter table ACS_PERSONA
  add constraint CHK_APE_NACIONALIDAD
  check (APE_NACIONALIDAD IN ('NACIONAL', 'EXTRANJERO'));
alter table ACS_PERSONA
  add constraint CHK_APE_SEXO
  check (APE_SEXO IN ('MASCULINO', 'FEMENINO'));
alter table ACS_PERSONA
  add constraint CHK_APE_TIPO_USUARIO
  check (APE_TIPO_USUARIO in ('MEDICO', 'ADMINISTRATIVO'));

prompt Creating ACS_USUARIO...
create table ACS_USUARIO
(
  aus_id             NUMBER generated always as identity,
  aus_estado         VARCHAR2(10) default 'ACTIVO' not null,
  aus_fecha_creacion TIMESTAMP(6) default SYSDATE not null,
  aus_ultimo_acceso  TIMESTAMP(6) default SYSDATE not null,
  ape_id             NUMBER not null
)
;
comment on table ACS_USUARIO
  is 'Tabla para representa, manejar y almacenar usuarios que hay en el sistema';
comment on column ACS_USUARIO.aus_id
  is 'ID unico de cada usuario del sistema
';
comment on column ACS_USUARIO.aus_estado
  is 'Estado: ACTIVO, INACTIVO. Para visibilidad y gestion de perfiles de usuario';
comment on column ACS_USUARIO.aus_fecha_creacion
  is 'Automatico
';
comment on column ACS_USUARIO.aus_ultimo_acceso
  is 'Automatico/trigger';
comment on column ACS_USUARIO.ape_id
  is 'Fk';
alter table ACS_USUARIO
  add constraint PK_ACS_USUARIO primary key (AUS_ID);
alter table ACS_USUARIO
  add constraint AUS_X_APE foreign key (APE_ID)
  references ACS_PERSONA (APE_ID);
alter table ACS_USUARIO
  add constraint CHK_AUS_ESTADO
  check (AUS_ESTADO IN ('ACTIVO', 'INACTIVO'));
grant select, insert, update, delete, read on ACS_USUARIO to ADMINISTRADOR;

prompt Creating ACS_CUENTA_BANCARIA...
create table ACS_CUENTA_BANCARIA
(
  acb_id            NUMBER generated always as identity,
  acb_numero_cuenta VARCHAR2(50) not null,
  acb_es_principal  VARCHAR2(2) default 'NO' not null,
  acb_tipo_cuenta   VARCHAR2(10) not null,
  acb_estado        VARCHAR2(10) default 'ACTIVO' not null,
  aus_id            NUMBER not null,
  aba_id            NUMBER not null
)
;
comment on table ACS_CUENTA_BANCARIA
  is 'Tabla para representa, manejar y almacenar cuentas bancarias de los usuarios que hay en el sistema';
comment on column ACS_CUENTA_BANCARIA.acb_id
  is 'ID unico de cada cuenta bancaria';
comment on column ACS_CUENTA_BANCARIA.acb_numero_cuenta
  is 'Numero propio y unico de la cuenta bancaria';
comment on column ACS_CUENTA_BANCARIA.acb_es_principal
  is 'SI, NO';
comment on column ACS_CUENTA_BANCARIA.acb_tipo_cuenta
  is 'CORRIENTE o de AHORRO';
comment on column ACS_CUENTA_BANCARIA.acb_estado
  is 'Estado: ACTIVO, INACTIVO. Para visibilidad ';
comment on column ACS_CUENTA_BANCARIA.aus_id
  is 'ID del usuario relacionado a la cuenta bancaria';
comment on column ACS_CUENTA_BANCARIA.aba_id
  is 'ID del banco relacionado a la cuenta bancaria';
create unique index UQ_ACB_ES_PRINCIPAL_USUARIO on ACS_CUENTA_BANCARIA (CASE ACB_ES_PRINCIPAL WHEN 'SI' THEN AUS_ID END);
create unique index UQ_ACB_NUMERO_CUENTA on ACS_CUENTA_BANCARIA (ACB_NUMERO_CUENTA);
alter table ACS_CUENTA_BANCARIA
  add constraint PK_ACS_CUENTA_BANCARIA primary key (ACB_ID);
alter table ACS_CUENTA_BANCARIA
  add constraint ACB_X_ABA foreign key (ABA_ID)
  references ACS_BANCO (ABA_ID);
alter table ACS_CUENTA_BANCARIA
  add constraint ACB_X_AUS foreign key (AUS_ID)
  references ACS_USUARIO (AUS_ID);
alter table ACS_CUENTA_BANCARIA
  add constraint CHK_ACB_ES_PRINCIPAL
  check (ACB_ES_PRINCIPAL IN ('SI', 'NO'));
alter table ACS_CUENTA_BANCARIA
  add constraint CHK_ACB_ESTADO
  check (ACB_ESTADO IN ('ACTIVO', 'INACTIVO'));
alter table ACS_CUENTA_BANCARIA
  add constraint CHK_ACB_TIPO_CUENTA
  check (ACB_TIPO_CUENTA in ('AHORRO', 'CORRIENTE'));

prompt Creating ACS_TIPO_DOCUMENTO...
create table ACS_TIPO_DOCUMENTO
(
  atd_id                  NUMBER generated always as identity,
  atd_tipo_usuario        VARCHAR2(15) not null,
  atd_documento_requerido VARCHAR2(200) not null,
  atd_estado              VARCHAR2(10) default 'ACTIVO' not null
)
;
comment on table ACS_TIPO_DOCUMENTO
  is 'Tabla para representa, manejar y almacenar tipo de documento que hay en el sistema';
comment on column ACS_TIPO_DOCUMENTO.atd_tipo_usuario
  is 'MEDICO, ADMINISTRATIVO, TODOS';
comment on column ACS_TIPO_DOCUMENTO.atd_documento_requerido
  is 'Nombre docuemnto solicitado';
comment on column ACS_TIPO_DOCUMENTO.atd_estado
  is 'Estado: ACTIVO, INACTIVO. Para visibilidad ';
create unique index UQ_ATD_TIPO_U_X_ATD_DOCU_R on ACS_TIPO_DOCUMENTO (ATD_TIPO_USUARIO, ATD_DOCUMENTO_REQUERIDO);
alter table ACS_TIPO_DOCUMENTO
  add constraint PK_ACS_TIPO_DOCUMENTO primary key (ATD_ID);
alter table ACS_TIPO_DOCUMENTO
  add constraint CHK_ATD_ESTADO
  check (ATD_ESTADO IN ('ACTIVO', 'INACTIVO'));
alter table ACS_TIPO_DOCUMENTO
  add constraint CHK_ATD_TIPO_USUARIO
  check (ATD_TIPO_USUARIO in ('MEDICO', 'ADMINISTRATIVO', 'TODOS'));

prompt Creating ACS_DOCUMENTO_USUARIO...
create table ACS_DOCUMENTO_USUARIO
(
  adu_id                  NUMBER generated always as identity,
  adu_url                 VARCHAR2(1000) not null,
  adu_comentarios         VARCHAR2(400),
  adu_estado              VARCHAR2(10) default 'PENDIENTE' not null,
  adu_fecha_creacion      TIMESTAMP(6) default SYSDATE not null,
  adu_fecha_actualizacion TIMESTAMP(6) default SYSDATE not null,
  atd_id                  NUMBER not null,
  aus_id                  NUMBER not null
)
;
comment on table ACS_DOCUMENTO_USUARIO
  is 'Tabla para representa, manejar y almacenar documentos de los usuarios que hay en el sistema';
comment on column ACS_DOCUMENTO_USUARIO.adu_id
  is 'ID unico del documento';
comment on column ACS_DOCUMENTO_USUARIO.adu_url
  is 'URL del documento adjunto';
comment on column ACS_DOCUMENTO_USUARIO.adu_comentarios
  is 'Descripcion propia del documento';
comment on column ACS_DOCUMENTO_USUARIO.adu_estado
  is '(''PENDIENTE'', ''APROBADO'', ''RECHAZADO'')
';
comment on column ACS_DOCUMENTO_USUARIO.adu_fecha_creacion
  is 'automatico';
comment on column ACS_DOCUMENTO_USUARIO.adu_fecha_actualizacion
  is 'automatico';
comment on column ACS_DOCUMENTO_USUARIO.aus_id
  is 'ID del usuario relacionado al documento';
create unique index UQ_AUS_ID_X_ATD_ID on ACS_DOCUMENTO_USUARIO (AUS_ID, ATD_ID);
alter table ACS_DOCUMENTO_USUARIO
  add constraint PK_ACS_DOCUMENTO_USUARIO primary key (ADU_ID);
alter table ACS_DOCUMENTO_USUARIO
  add constraint ADU_X_ATD foreign key (ATD_ID)
  references ACS_TIPO_DOCUMENTO (ATD_ID);
alter table ACS_DOCUMENTO_USUARIO
  add constraint ADU_X_AUS foreign key (AUS_ID)
  references ACS_USUARIO (AUS_ID);
alter table ACS_DOCUMENTO_USUARIO
  add constraint CHK_ADU_ESTADO
  check (ADU_ESTADO IN ('PENDIENTE', 'APROBADO', 'RECHAZADO'));

prompt Creating ACS_PERFIL...
create table ACS_PERFIL
(
  apf_id          NUMBER generated always as identity,
  apf_nombre      CHAR(100) not null,
  apf_descripcion CHAR(400),
  apf_padre_id    NUMBER
)
;
create index APF_X_APF on ACS_PERFIL (APF_PADRE_ID);
create unique index UQ_APF_NOMBRE on ACS_PERFIL (APF_NOMBRE);
alter table ACS_PERFIL
  add constraint PK_ACS_PERFIL primary key (APF_ID);
alter table ACS_PERFIL
  add constraint APF_X_APF foreign key (APF_PADRE_ID)
  references ACS_PERFIL (APF_ID);

prompt Creating ACS_PERMISO...
create table ACS_PERMISO
(
  apr_id       NUMBER generated always as identity,
  apr_pantalla VARCHAR2(100) not null,
  apr_leer     NUMBER not null,
  apr_crear    NUMBER not null,
  apr_editar   NUMBER not null,
  apr_borrar   NUMBER not null
)
;
comment on table ACS_PERMISO
  is 'Tabla para detallar los permisos que puede tener un usuario en las diferentes pantallas';
create unique index UQ_APR_PAN_TIU on ACS_PERMISO (APR_PANTALLA);
alter table ACS_PERMISO
  add constraint PK_ACS_PERMISO primary key (APR_ID);
alter table ACS_PERMISO
  add constraint CHK_APR_PERMISO_BORRAR
  check (APR_BORRAR IN (0, 1));
alter table ACS_PERMISO
  add constraint CHK_APR_PERMISO_CREAR
  check (APR_CREAR IN (0, 1));
alter table ACS_PERMISO
  add constraint CHK_APR_PERMISO_EDITAR
  check (APR_EDITAR IN (0, 1));
alter table ACS_PERMISO
  add constraint CHK_APR_PERMISO_LEER
  check (APR_LEER IN (0, 1));

prompt Creating ACS_PERFIL_PERMISO...
create table ACS_PERFIL_PERMISO
(
  app_id NUMBER generated always as identity,
  apr_id NUMBER not null,
  apf_id NUMBER not null
)
;
create index APP_X_APF on ACS_PERFIL_PERMISO (APF_ID);
create index APP_X_APR on ACS_PERFIL_PERMISO (APR_ID);
alter table ACS_PERFIL_PERMISO
  add constraint PK_ACS_PERFIL_PERMISO primary key (APP_ID);
alter table ACS_PERFIL_PERMISO
  add constraint APP_X_APF foreign key (APF_ID)
  references ACS_PERFIL (APF_ID);
alter table ACS_PERFIL_PERMISO
  add constraint APP_X_APR foreign key (APR_ID)
  references ACS_PERMISO (APR_ID);

prompt Creating ACS_USUARIO_PERFIL...
create table ACS_USUARIO_PERFIL
(
  apf_id NUMBER not null,
  aus_id NUMBER not null
)
;
create index IX_Relationship5 on ACS_USUARIO_PERFIL (APF_ID);
create index IX_Relationship6 on ACS_USUARIO_PERFIL (AUS_ID);
alter table ACS_USUARIO_PERFIL
  add constraint AUP_X_APF foreign key (APF_ID)
  references ACS_PERFIL (APF_ID);
alter table ACS_USUARIO_PERFIL
  add constraint AUP_X_AUS foreign key (AUS_ID)
  references ACS_USUARIO (AUS_ID);

prompt Disabling triggers for ACS_BANCO...
alter table ACS_BANCO disable all triggers;
prompt Disabling triggers for ACS_PERSONA...
alter table ACS_PERSONA disable all triggers;
prompt Disabling triggers for ACS_USUARIO...
alter table ACS_USUARIO disable all triggers;
prompt Disabling triggers for ACS_CUENTA_BANCARIA...
alter table ACS_CUENTA_BANCARIA disable all triggers;
prompt Disabling triggers for ACS_TIPO_DOCUMENTO...
alter table ACS_TIPO_DOCUMENTO disable all triggers;
prompt Disabling triggers for ACS_DOCUMENTO_USUARIO...
alter table ACS_DOCUMENTO_USUARIO disable all triggers;
prompt Disabling triggers for ACS_PERFIL...
alter table ACS_PERFIL disable all triggers;
prompt Disabling triggers for ACS_PERMISO...
alter table ACS_PERMISO disable all triggers;
prompt Disabling triggers for ACS_PERFIL_PERMISO...
alter table ACS_PERFIL_PERMISO disable all triggers;
prompt Disabling triggers for ACS_USUARIO_PERFIL...
alter table ACS_USUARIO_PERFIL disable all triggers;
prompt Disabling foreign key constraints for ACS_USUARIO...
alter table ACS_USUARIO disable constraint AUS_X_APE;
prompt Disabling foreign key constraints for ACS_CUENTA_BANCARIA...
alter table ACS_CUENTA_BANCARIA disable constraint ACB_X_ABA;
alter table ACS_CUENTA_BANCARIA disable constraint ACB_X_AUS;
prompt Disabling foreign key constraints for ACS_DOCUMENTO_USUARIO...
alter table ACS_DOCUMENTO_USUARIO disable constraint ADU_X_ATD;
alter table ACS_DOCUMENTO_USUARIO disable constraint ADU_X_AUS;
prompt Disabling foreign key constraints for ACS_PERFIL...
alter table ACS_PERFIL disable constraint APF_X_APF;
prompt Disabling foreign key constraints for ACS_PERFIL_PERMISO...
alter table ACS_PERFIL_PERMISO disable constraint APP_X_APF;
alter table ACS_PERFIL_PERMISO disable constraint APP_X_APR;
prompt Disabling foreign key constraints for ACS_USUARIO_PERFIL...
alter table ACS_USUARIO_PERFIL disable constraint AUP_X_APF;
alter table ACS_USUARIO_PERFIL disable constraint AUP_X_AUS;
prompt Loading ACS_BANCO...
insert into ACS_BANCO (aba_id, aba_nombre, aba_telefono, aba_estado)
values (1, 'Banco Nacional de Costa Rica', '2212-2000', 'ACTIVO');
insert into ACS_BANCO (aba_id, aba_nombre, aba_telefono, aba_estado)
values (2, 'Banco de Costa Rica', '2287-9000', 'ACTIVO');
insert into ACS_BANCO (aba_id, aba_nombre, aba_telefono, aba_estado)
values (3, 'Banco Davivienda', '2220-2020', 'ACTIVO');
insert into ACS_BANCO (aba_id, aba_nombre, aba_telefono, aba_estado)
values (4, 'BAC Credomatic', '2295-9595', 'ACTIVO');
insert into ACS_BANCO (aba_id, aba_nombre, aba_telefono, aba_estado)
values (5, 'Banco Popular', '2202-2000', 'ACTIVO');
insert into ACS_BANCO (aba_id, aba_nombre, aba_telefono, aba_estado)
values (6, 'Scotiabank Costa Rica', '2506-4000', 'ACTIVO');
commit;
prompt 6 records loaded
prompt Loading ACS_PERSONA...
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (1, 'CED123456', 'Juan', 'Perez', 'Gomez', to_timestamp('15-04-1985 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'MASCULINO', 'CASADO', 'NACIONAL', 'MEDICO', 'PENDIENTE', 'juan.perez@mail.com', '555-1234', 'Ciudad A', 'Calle 123', 'Oficina 456', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (2, 'CED234567', 'Maria', 'Lopez', 'Diaz', to_timestamp('22-08-1990 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'FEMENINO', 'SOLTERO', 'EXTRANJERO', 'ADMINISTRATIVO', 'RECHAZADO', 'maria.lopez@mail.com', '555-5678', 'Ciudad B', 'Calle 456', 'Oficina 789', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:55:24.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (3, 'CED345678', 'Carlos', 'Ramirez', 'Suarez', to_timestamp('10-12-1975 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'MASCULINO', 'DIVORCIADO', 'NACIONAL', 'MEDICO', 'APROBADO', 'carlos.ramirez@mail.com', '555-9012', 'Ciudad C', 'Calle 789', 'Oficina 012', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:55:24.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (4, 'CED456789', 'Ana', 'Martinez', 'Castro', to_timestamp('05-03-1982 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'FEMENINO', 'CASADO', 'NACIONAL', 'ADMINISTRATIVO', 'PENDIENTE', 'ana.martinez@mail.com', '555-3456', 'Ciudad D', 'Calle 234', 'Oficina 345', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (5, 'CED567890', 'Jose', 'Gonzalez', 'Reyes', to_timestamp('18-07-1988 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'MASCULINO', 'SOLTERO', 'EXTRANJERO', 'MEDICO', 'PENDIENTE', 'jose.gonzalez@mail.com', '555-6789', 'Ciudad E', 'Calle 567', 'Oficina 678', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (6, 'CED678901', 'Laura', 'Hernandez', 'Morales', to_timestamp('25-11-1992 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'FEMENINO', 'UNION LIBRE', 'NACIONAL', 'ADMINISTRATIVO', 'APROBADO', 'laura.hernandez@mail.com', '555-2345', 'Ciudad F', 'Calle 890', 'Oficina 901', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:55:24.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (7, 'CED789012', 'Pedro', 'Alvarez', 'Rojas', to_timestamp('30-09-1980 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'MASCULINO', 'VIUDO', 'NACIONAL', 'MEDICO', 'PENDIENTE', 'pedro.alvarez@mail.com', '555-4567', 'Ciudad G', 'Calle 012', 'Oficina 123', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (8, 'CED890123', 'Sofia', 'Jimenez', 'Ortiz', to_timestamp('12-02-1987 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'FEMENINO', 'CASADO', 'EXTRANJERO', 'ADMINISTRATIVO', 'APROBADO', 'sofia.jimenez@mail.com', '555-7890', 'Ciudad H', 'Calle 345', 'Oficina 456', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:55:24.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (9, 'CED901234', 'Diego', 'Castillo', 'Padilla', to_timestamp('08-06-1995 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'MASCULINO', 'SOLTERO', 'NACIONAL', 'MEDICO', 'PENDIENTE', 'diego.castillo@mail.com', '555-0123', 'Ciudad I', 'Calle 678', 'Oficina 789', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (10, 'CED012345', 'Valeria', 'Mendoza', 'Salas', to_timestamp('19-01-1983 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'FEMENINO', 'DIVORCIADO', 'NACIONAL', 'ADMINISTRATIVO', 'PENDIENTE', 'valeria.mendoza@mail.com', '555-3450', 'Ciudad J', 'Calle 901', 'Oficina 234', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
insert into ACS_PERSONA (ape_id, ape_cedula, ape_nombre, ape_p_apellido, ape_s_apellido, ape_fecha_nacimiento, ape_sexo, ape_estado_civil, ape_nacionalidad, ape_tipo_usuario, ape_estado_registro, ape_email, ape_telefono, ape_residencia, ape_direcion_casa, ape_direccion_trabajo, ape_fecha_creacion, ape_fecha_actualizacion)
values (11, '118690700', 'Juan', 'Camacho', 'Solano', to_timestamp('12-05-2000 00:00:00.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), 'MASCULINO', 'SOLTERO', 'NACIONAL', 'MEDICO', 'APROBADO', 'juancarlos19defebrero@gmail.com', '3104567890', 'Bogota', 'Carrera 45 # 32-12', 'Empresa XYZ', to_timestamp('09-11-2025 16:52:49.000000', 'dd-mm-yyyy hh24:mi:ss.ff'), to_timestamp('09-11-2025 16:55:24.000000', 'dd-mm-yyyy hh24:mi:ss.ff'));
commit;
prompt 11 records loaded
prompt Loading ACS_USUARIO...
prompt Table is empty
prompt Loading ACS_CUENTA_BANCARIA...
prompt Table is empty
prompt Loading ACS_TIPO_DOCUMENTO...
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (1, 'TODOS', 'Cedula de Identidad', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (2, 'TODOS', 'Certificado de Nacimiento', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (3, 'TODOS', 'Curriculum Vitae', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (4, 'MEDICO', 'Licencia Medica', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (5, 'MEDICO', 'Certificado de Especialidad', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (6, 'MEDICO', 'Titulo Universitario Medicina', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (7, 'ADMINISTRATIVO', 'Titulo Universitario', 'ACTIVO');
insert into ACS_TIPO_DOCUMENTO (atd_id, atd_tipo_usuario, atd_documento_requerido, atd_estado)
values (8, 'ADMINISTRATIVO', 'Certificados de Capacitacion', 'ACTIVO');
commit;
prompt 8 records loaded
prompt Loading ACS_DOCUMENTO_USUARIO...
prompt Table is empty
prompt Loading ACS_PERFIL...
insert into ACS_PERFIL (apf_id, apf_nombre, apf_descripcion, apf_padre_id)
values (1, 'SUPERUSUARIO                                                                                        ', 'Acceso total al sistema con todos los permisos                                                                                                                                                                                                                                                                                                                                                                  ', null);
insert into ACS_PERFIL (apf_id, apf_nombre, apf_descripcion, apf_padre_id)
values (2, 'MEDICO                                                                                              ', 'Perfil para personal medico con acceso a escalas y pacientes                                                                                                                                                                                                                                                                                                                                                    ', null);
insert into ACS_PERFIL (apf_id, apf_nombre, apf_descripcion, apf_padre_id)
values (3, 'ADMINISTRATIVO                                                                                      ', 'Perfil para personal administrativo con acceso a gestion general                                                                                                                                                                                                                                                                                                                                                ', null);
insert into ACS_PERFIL (apf_id, apf_nombre, apf_descripcion, apf_padre_id)
values (4, 'CONTADOR                                                                                            ', 'Perfil especializado en gestion financiera y planillas                                                                                                                                                                                                                                                                                                                                                          ', null);
insert into ACS_PERFIL (apf_id, apf_nombre, apf_descripcion, apf_padre_id)
values (5, 'RRHH                                                                                                ', 'Perfil para recursos humanos con gestion de personal                                                                                                                                                                                                                                                                                                                                                            ', null);
commit;
prompt 5 records loaded
prompt Loading ACS_PERMISO...
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (1, 'PERSONAS', 1, 1, 1, 1);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (2, 'USUARIOS', 1, 1, 1, 1);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (3, 'BANCOS', 1, 1, 1, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (4, 'CUENTAS_BANCARIAS', 1, 1, 1, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (5, 'DOCUMENTOS', 1, 1, 1, 1);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (6, 'PERFILES', 1, 1, 1, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (7, 'PERMISOS', 1, 0, 1, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (8, 'CENTROS_SALUD', 1, 1, 1, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (9, 'ESCALAS_MEDICAS', 1, 1, 1, 1);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (10, 'PLANILLAS', 1, 1, 1, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (11, 'REPORTES_FINANCIEROS', 1, 0, 0, 0);
insert into ACS_PERMISO (apr_id, apr_pantalla, apr_leer, apr_crear, apr_editar, apr_borrar)
values (12, 'AUDITORIA', 1, 0, 0, 0);
commit;
prompt 12 records loaded
prompt Loading ACS_PERFIL_PERMISO...
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (1, 1, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (2, 2, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (3, 3, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (4, 4, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (5, 5, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (6, 6, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (7, 7, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (8, 8, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (9, 9, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (10, 10, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (11, 11, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (12, 12, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (13, 8, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (14, 4, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (15, 5, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (16, 9, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (17, 3, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (18, 5, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (19, 1, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (20, 11, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (21, 2, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (22, 12, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (23, 4, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (24, 10, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (25, 11, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (26, 3, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (27, 4, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (28, 5, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (29, 6, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (30, 1, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (31, 2, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (32, 1, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (33, 2, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (34, 3, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (35, 4, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (36, 5, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (37, 6, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (38, 7, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (39, 8, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (40, 9, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (41, 10, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (42, 11, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (43, 12, 1);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (44, 8, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (45, 4, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (46, 5, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (47, 9, 2);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (48, 3, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (49, 5, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (50, 1, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (51, 11, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (52, 2, 3);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (53, 12, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (54, 4, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (55, 10, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (56, 11, 4);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (57, 3, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (58, 4, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (59, 5, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (60, 6, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (61, 1, 5);
insert into ACS_PERFIL_PERMISO (app_id, apr_id, apf_id)
values (62, 2, 5);
commit;
prompt 62 records loaded
prompt Loading ACS_USUARIO_PERFIL...
prompt Table is empty
prompt Enabling foreign key constraints for ACS_USUARIO...
alter table ACS_USUARIO enable constraint AUS_X_APE;
prompt Enabling foreign key constraints for ACS_CUENTA_BANCARIA...
alter table ACS_CUENTA_BANCARIA enable constraint ACB_X_ABA;
alter table ACS_CUENTA_BANCARIA enable constraint ACB_X_AUS;
prompt Enabling foreign key constraints for ACS_DOCUMENTO_USUARIO...
alter table ACS_DOCUMENTO_USUARIO enable constraint ADU_X_ATD;
alter table ACS_DOCUMENTO_USUARIO enable constraint ADU_X_AUS;
prompt Enabling foreign key constraints for ACS_PERFIL...
alter table ACS_PERFIL enable constraint APF_X_APF;
prompt Enabling foreign key constraints for ACS_PERFIL_PERMISO...
alter table ACS_PERFIL_PERMISO enable constraint APP_X_APF;
alter table ACS_PERFIL_PERMISO enable constraint APP_X_APR;
prompt Enabling foreign key constraints for ACS_USUARIO_PERFIL...
alter table ACS_USUARIO_PERFIL enable constraint AUP_X_APF;
alter table ACS_USUARIO_PERFIL enable constraint AUP_X_AUS;
prompt Enabling triggers for ACS_BANCO...
alter table ACS_BANCO enable all triggers;
prompt Enabling triggers for ACS_PERSONA...
alter table ACS_PERSONA enable all triggers;
prompt Enabling triggers for ACS_USUARIO...
alter table ACS_USUARIO enable all triggers;
prompt Enabling triggers for ACS_CUENTA_BANCARIA...
alter table ACS_CUENTA_BANCARIA enable all triggers;
prompt Enabling triggers for ACS_TIPO_DOCUMENTO...
alter table ACS_TIPO_DOCUMENTO enable all triggers;
prompt Enabling triggers for ACS_DOCUMENTO_USUARIO...
alter table ACS_DOCUMENTO_USUARIO enable all triggers;
prompt Enabling triggers for ACS_PERFIL...
alter table ACS_PERFIL enable all triggers;
prompt Enabling triggers for ACS_PERMISO...
alter table ACS_PERMISO enable all triggers;
prompt Enabling triggers for ACS_PERFIL_PERMISO...
alter table ACS_PERFIL_PERMISO enable all triggers;
prompt Enabling triggers for ACS_USUARIO_PERFIL...
alter table ACS_USUARIO_PERFIL enable all triggers;

set feedback on
set define on
prompt Done

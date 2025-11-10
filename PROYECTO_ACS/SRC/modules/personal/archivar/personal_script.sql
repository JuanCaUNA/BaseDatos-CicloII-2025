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

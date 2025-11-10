prompt PL/SQL Developer Export Tables for user JUAN@ORCLPDB
prompt Created by juanc on domingo, 9 de noviembre de 2025
set feedback off
set define off

prompt Dropping ACS_AUDITORIA_DETALLE_MENSUAL...
drop table ACS_AUDITORIA_DETALLE_MENSUAL cascade constraints;
prompt Dropping ACS_CENTRO_MEDICO...
drop table ACS_CENTRO_MEDICO cascade constraints;
prompt Dropping ACS_ESCALA_MENSUAL...
drop table ACS_ESCALA_MENSUAL cascade constraints;
prompt Dropping ACS_PROCEDIMIENTO...
drop table ACS_PROCEDIMIENTO cascade constraints;
prompt Dropping ACS_PROC_APLICADO...
drop table ACS_PROC_APLICADO cascade constraints;
prompt Dropping ACS_PROCEDIMIENTOXCENTRO...
drop table ACS_PROCEDIMIENTOXCENTRO cascade constraints;
prompt Dropping ACS_PUESTO_MEDICO...
drop table ACS_PUESTO_MEDICO cascade constraints;
prompt Dropping ACS_PUESTOXCENTRO...
drop table ACS_PUESTOXCENTRO cascade constraints;
prompt Dropping ACS_RESUMEN_FIN_MENSUAL...
drop table ACS_RESUMEN_FIN_MENSUAL cascade constraints;
prompt Dropping ACS_TURNO...
drop table ACS_TURNO cascade constraints;
prompt Dropping ACS_TURNO_PLANILLA...
drop table ACS_TURNO_PLANILLA cascade constraints;
prompt Creating ACS_AUDITORIA_DETALLE_MENSUAL...
create table ACS_AUDITORIA_DETALLE_MENSUAL
(
  aum_id            NUMBER generated always as identity,
  aum_observaciones VARCHAR2(255),
  aum_fecha         TIMESTAMP(6) not null,
  aum_estado_turno  VARCHAR2(15),
  aum_hr_inicio     TIMESTAMP(9),
  aum_hr_fin        TIMESTAMP(9),
  aum_estado        VARCHAR2(10) not null,
  aum_usuario       VARCHAR2(50) not null,
  aum_cambios       VARCHAR2(100),
  aum_accion        VARCHAR2(10),
  aem_id            NUMBER,
  ame_id            NUMBER,
  apm_id            NUMBER,
  atu_id            NUMBER,
  adm_id            NUMBER
)
;
comment on table ACS_AUDITORIA_DETALLE_MENSUAL
  is 'Tabla para representa, manejar y almacenarr los detalles de las escalas mensuales que hay en el sistema, este es un punto que reune medicos, centros, puestos, turnos y demás, esto se maneja así ya que pueden haber muchos cambios y se requiere flexibilidad en esos campos, por eso no se relacionan entre ellos si no que se junta en una tabla ';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_id
  is 'ID unico del detalle de la escala mensual';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_observaciones
  is 'Observaciones del detalle mensual';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_fecha
  is 'Fecha especifica del detalle';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_estado_turno
  is 'Campo para saber en que está relamente quedó el turno';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_hr_inicio
  is 'Hora real en la que inició';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_hr_fin
  is 'Hora real en la que finalizó';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_estado
  is 'Estado en el que se encuentra el detalle mensual';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_usuario
  is 'Usuario que realizó el cambio';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_cambios
  is 'para saber qué campos cambiaron';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aum_accion
  is 'INSERT, UPDATE, DELETE';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.aem_id
  is 'ID de referencia con la escala mensual';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.ame_id
  is 'ID de referencia con el medico
';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.apm_id
  is 'ID de referencia con el puesto medico
';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.atu_id
  is 'ID del turno relacionado ';
comment on column ACS_AUDITORIA_DETALLE_MENSUAL.adm_id
  is 'ID de referencia al detalle de escala mensual';
alter table ACS_AUDITORIA_DETALLE_MENSUAL
  add constraint PK_ACS_AUDITORIA_DETALLE_MENSUAL primary key (AUM_ID);
alter table ACS_AUDITORIA_DETALLE_MENSUAL
  add constraint CHK_ADM_ESTADO (AUM)
  check (AUM_ESTADO IN ('ACTIVO', 'INACTIVO'));
alter table ACS_AUDITORIA_DETALLE_MENSUAL
  add constraint CHK_AMD_ESTADO_TURNO (AUM)
  check (AUM_ESTADO_TURNO IN ('CUMPLIDO','FALTA','CANCELADO','REEMPLAZADO'));

prompt Creating ACS_CENTRO_MEDICO...
create table ACS_CENTRO_MEDICO
(
  acm_id        NUMBER generated always as identity,
  acm_nombre    VARCHAR2(150) not null,
  acm_ubicacion VARCHAR2(255),
  acm_telefono  VARCHAR2(50),
  acm_email     VARCHAR2(150),
  acm_estado    VARCHAR2(10) not null
)
;
comment on table ACS_CENTRO_MEDICO
  is 'Tabla para representa, manejar y almacenarr los centros de salud que hay en el sistema';
comment on column ACS_CENTRO_MEDICO.acm_id
  is 'ID unico de cada centro de salud del sistema';
comment on column ACS_CENTRO_MEDICO.acm_nombre
  is 'Nombre unico de cada uno de los centros de salud del sistema';
comment on column ACS_CENTRO_MEDICO.acm_ubicacion
  is 'Ubicación exacta y detallada del centro de salud';
comment on column ACS_CENTRO_MEDICO.acm_telefono
  is 'Telefono para contactar al centro de salud';
comment on column ACS_CENTRO_MEDICO.acm_email
  is 'Emial propio del centro de salud';
comment on column ACS_CENTRO_MEDICO.acm_estado
  is 'Campo para validar en que estado se encuentra el centro medico
';
alter table ACS_CENTRO_MEDICO
  add constraint PK_ACS_CENTRO_MEDICO primary key (ACM_ID);
alter table ACS_CENTRO_MEDICO
  add constraint CHK_ACM_ESTADO
  check (ACM_ESTADO IN ('ACTIVO', 'INACTIVO'));

prompt Creating ACS_ESCALA_MENSUAL...
create table ACS_ESCALA_MENSUAL
(
  aem_id     NUMBER generated always as identity,
  aem_mes    NUMBER not null,
  aem_anio   NUMBER not null,
  aem_estado VARCHAR2(20) not null,
  acm_id     NUMBER not null
)
;
comment on table ACS_ESCALA_MENSUAL
  is 'Tabla para representa, manejar y almacenarr las escalas mensuales que hay en el sistema';
comment on column ACS_ESCALA_MENSUAL.aem_id
  is 'ID unico de cada escala mensual
';
comment on column ACS_ESCALA_MENSUAL.aem_mes
  is 'Mes exacto de la escala mensual';
comment on column ACS_ESCALA_MENSUAL.aem_anio
  is 'Año exacto de la escala mensual';
comment on column ACS_ESCALA_MENSUAL.aem_estado
  is 'Estado en el que se encuentra la escala mensual';
comment on column ACS_ESCALA_MENSUAL.acm_id
  is 'ID del centro relacionado a la escala mensual';
alter table ACS_ESCALA_MENSUAL
  add constraint PK_ACS_ESCALA_MENSUAL primary key (AEM_ID);
alter table ACS_ESCALA_MENSUAL
  add constraint AEM_X_ACM foreign key (ACM_ID)
  references ACS_CENTRO_MEDICO (ACM_ID);
alter table ACS_ESCALA_MENSUAL
  add constraint CHK_AEM_ANIO
  check (AEM_ANIO >= 2000);
alter table ACS_ESCALA_MENSUAL
  add constraint CHK_AEM_ESTADO
  check (AEM_ESTADO IN ('CONSTRUCCION', 'VIGENTE', 'EN REVISION', 'LISTA PARA PAGO', 'PROCESADA'));
alter table ACS_ESCALA_MENSUAL
  add constraint CHK_AEM_MES
  check (AEM_MES BETWEEN 1 AND 12);

prompt Creating ACS_PROCEDIMIENTO...
create table ACS_PROCEDIMIENTO
(
  apd_id          NUMBER generated always as identity,
  apd_nombre      VARCHAR2(100) not null,
  apd_descripcion VARCHAR2(255),
  apd_estado      VARCHAR2(10) not null
)
;
comment on table ACS_PROCEDIMIENTO
  is 'Tabla para representa, manejar y almacenarr los procedimientos medicos que hay en el sistema';
comment on column ACS_PROCEDIMIENTO.apd_id
  is 'ID unico de cada procedimiento ';
comment on column ACS_PROCEDIMIENTO.apd_nombre
  is 'Nombre unico del procedimiento';
comment on column ACS_PROCEDIMIENTO.apd_descripcion
  is 'Descripción del procedimiento';
comment on column ACS_PROCEDIMIENTO.apd_estado
  is 'Estado en el que se encuentra el procedimiento
';
alter table ACS_PROCEDIMIENTO
  add constraint PK_ACS_PROCEDIMIENTO primary key (APD_ID);
alter table ACS_PROCEDIMIENTO
  add constraint CHK_APD_ESTADO
  check (APD_ESTADO IN ('ACTIVO', 'INACTIVO'));

prompt Creating ACS_PROC_APLICADO...
create table ACS_PROC_APLICADO
(
  apa_id     NUMBER generated always as identity,
  apa_fecha  TIMESTAMP(6) not null,
  apa_costo  NUMBER not null,
  apa_pago   NUMBER not null,
  apa_estado VARCHAR2(10) not null,
  ame_id     NUMBER not null,
  apd_id     NUMBER not null,
  acm_id     NUMBER
)
;
comment on table ACS_PROC_APLICADO
  is 'Tabla para representa, manejar y almacenarr los procedimientos aplicados que hay en el sistema, ya que un medico puede hcaer muchos procedimientos y un procedimiento puede hacerse varias veces pero por diferentes medicos';
comment on column ACS_PROC_APLICADO.apa_id
  is 'ID unico del procedimiento aplicado';
comment on column ACS_PROC_APLICADO.apa_fecha
  is 'Fecha en la que se aplicó el procedimiento';
comment on column ACS_PROC_APLICADO.apa_costo
  is 'Costo REAL una vez el procedimiento fue aplicado';
comment on column ACS_PROC_APLICADO.apa_pago
  is 'Precioa REAL a pagarle al medico por el procedimiento';
comment on column ACS_PROC_APLICADO.apa_estado
  is 'Estado en que se encuentra el procecimiento aplicado';
comment on column ACS_PROC_APLICADO.ame_id
  is 'ID del medico relacionado';
comment on column ACS_PROC_APLICADO.apd_id
  is 'ID del procedimineto relacionado';
create index IDX_ACM_ID on ACS_PROC_APLICADO (ACM_ID);
create index IDX_AME_ID (APA) on ACS_PROC_APLICADO (AME_ID);
create index IDX_AME_ID_X_ACM_ID on ACS_PROC_APLICADO (AME_ID, ACM_ID);
alter table ACS_PROC_APLICADO
  add constraint PK_ACS_PROC_APLICADO primary key (APA_ID);
alter table ACS_PROC_APLICADO
  add constraint APA_X_ACM foreign key (ACM_ID)
  references ACS_CENTRO_MEDICO (ACM_ID);
alter table ACS_PROC_APLICADO
  add constraint APA_X_AME foreign key (AME_ID)
  references ACS_MEDICO (AME_ID);
alter table ACS_PROC_APLICADO
  add constraint APA_X_APD foreign key (APD_ID)
  references ACS_PROCEDIMIENTO (APD_ID);
alter table ACS_PROC_APLICADO
  add constraint CHK_APA_ESTADO
  check (APA_ESTADO IN ('ACTIVO', 'INACTIVO'));

prompt Creating ACS_PROCEDIMIENTOXCENTRO...
create table ACS_PROCEDIMIENTOXCENTRO
(
  aprc_id     NUMBER generated always as identity,
  aprc_costo  NUMBER not null,
  aprc_pago   NUMBER not null,
  aprc_estado VARCHAR2(30) not null,
  acm_id      NUMBER not null,
  apd_id      NUMBER not null
)
;
comment on table ACS_PROCEDIMIENTOXCENTRO
  is 'Tabla para relacionar los centros de salud con un los procedimientos medicos, ya que un centro puede tener muchos procedimientos y un procedimiento puede realizarce en mucho centros';
comment on column ACS_PROCEDIMIENTOXCENTRO.aprc_id
  is 'ID propio de la tabla intermedia';
comment on column ACS_PROCEDIMIENTOXCENTRO.aprc_costo
  is 'Costo que supone para el centro medico';
comment on column ACS_PROCEDIMIENTOXCENTRO.aprc_pago
  is 'Pago que se le hace al medico
';
comment on column ACS_PROCEDIMIENTOXCENTRO.aprc_estado
  is 'Estado en el que se encuentra el prodecimiento aplicado en el centro medico
';
comment on column ACS_PROCEDIMIENTOXCENTRO.acm_id
  is 'ID de relación con el centro medico';
comment on column ACS_PROCEDIMIENTOXCENTRO.apd_id
  is 'ID de relación con el procedimiento
';
alter table ACS_PROCEDIMIENTOXCENTRO
  add constraint PK_ACS_PROCEDIMIENTOXCENTRO primary key (APRC_ID);
alter table ACS_PROCEDIMIENTOXCENTRO
  add constraint APRC_X_ACM foreign key (ACM_ID)
  references ACS_CENTRO_MEDICO (ACM_ID);
alter table ACS_PROCEDIMIENTOXCENTRO
  add constraint APRC_X_APD foreign key (APD_ID)
  references ACS_PROCEDIMIENTO (APD_ID);
alter table ACS_PROCEDIMIENTOXCENTRO
  add constraint CHK_APRC_ESTADO
  check (APRC_ESTADO IN ('ACTIVO', 'INACTIVO'));

prompt Creating ACS_PUESTO_MEDICO...
create table ACS_PUESTO_MEDICO
(
  apm_id          NUMBER generated always as identity,
  apm_nombre      VARCHAR2(150) not null,
  apm_descripcion VARCHAR2(255),
  apm_estado      VARCHAR2(10) not null
)
;
comment on table ACS_PUESTO_MEDICO
  is 'Tabla para representa, manejar y almacenarr los puestos medicos que hay en el sistema';
comment on column ACS_PUESTO_MEDICO.apm_id
  is 'ID unico de cada puesto medico
';
comment on column ACS_PUESTO_MEDICO.apm_nombre
  is 'Nombre unico del puesto medico';
comment on column ACS_PUESTO_MEDICO.apm_descripcion
  is 'Descripción del puesto medico';
comment on column ACS_PUESTO_MEDICO.apm_estado
  is 'Campo para validar en que estado se encuentra el puesto medico
';
alter table ACS_PUESTO_MEDICO
  add constraint PK_ACS_PUESTO_MEDICO primary key (APM_ID);
alter table ACS_PUESTO_MEDICO
  add constraint CHK_APM_ESTADO
  check (APM_ESTADO IN ('ACTIVO', 'INACTIVO'));

prompt Creating ACS_PUESTOXCENTRO...
create table ACS_PUESTOXCENTRO
(
  apc_id     NUMBER generated always as identity,
  acm_id     NUMBER not null,
  apm_id     NUMBER not null,
  apc_estado VARCHAR2(10) not null
)
;
comment on table ACS_PUESTOXCENTRO
  is 'Tabla para relacionar los centros de salud con el puesto medico, ya que un centro puede tener muchos puestos y un puesto puede estar en mucho centros';
comment on column ACS_PUESTOXCENTRO.apc_id
  is 'ID propio de la tabla intermedia';
comment on column ACS_PUESTOXCENTRO.acm_id
  is 'ID de relación con el centro medico
';
comment on column ACS_PUESTOXCENTRO.apm_id
  is 'ID de relación con el puesto medico
';
comment on column ACS_PUESTOXCENTRO.apc_estado
  is 'Estado en el que se encuentra la relación de puesto con el centro medico';
alter table ACS_PUESTOXCENTRO
  add constraint PK_ACS_PUESTOXCENTRO primary key (APC_ID);
alter table ACS_PUESTOXCENTRO
  add constraint APC_X_ACM foreign key (ACM_ID)
  references ACS_CENTRO_MEDICO (ACM_ID);
alter table ACS_PUESTOXCENTRO
  add constraint APC_X_APM foreign key (APM_ID)
  references ACS_PUESTO_MEDICO (APM_ID);
alter table ACS_PUESTOXCENTRO
  add constraint CHK_APC_ESTADO
  check (APC_ESTADO IN ('ACTIVO', 'INACTIVO'));

prompt Creating ACS_RESUMEN_FIN_MENSUAL...
create table ACS_RESUMEN_FIN_MENSUAL
(
  arm_id                  NUMBER generated always as identity,
  arm_periodo_anio        NUMBER not null,
  arm_periodo_mes         NUMBER not null,
  arm_ingresos            NUMBER not null,
  arm_gastos              NUMBER not null,
  arm_utilidad            NUMBER not null,
  arm_fecha_creacion      TIMESTAMP(6) not null,
  arm_fecha_actualizacion TIMESTAMP(6) not null
)
;
comment on table ACS_RESUMEN_FIN_MENSUAL
  is 'Tabla para representa, manejar y almacenar los resumenes de fin de mes que hay en el sistema';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_id
  is 'Identificador del resumen mensual';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_periodo_anio
  is 'Año del resumen';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_periodo_mes
  is 'Mes del resumen';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_ingresos
  is 'Total de ingresos del mes';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_gastos
  is 'Total de gastos del mes';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_utilidad
  is 'Ingresos - Gastos';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_fecha_creacion
  is 'Fecha de creación';
comment on column ACS_RESUMEN_FIN_MENSUAL.arm_fecha_actualizacion
  is 'Fecha de última actualización';
alter table ACS_RESUMEN_FIN_MENSUAL
  add constraint PK_ACS_RESUMEN_FIN_MENSUAL primary key (ARM_ID);
alter table ACS_RESUMEN_FIN_MENSUAL
  add constraint CHK_ARM_PERIODO_ANIO
  check (ARM_PERIODO_ANIO >= 2000);
alter table ACS_RESUMEN_FIN_MENSUAL
  add constraint CHK_ARM_PERIODO_MES
  check (ARM_PERIODO_MES BETWEEN 1 AND 12);

prompt Creating ACS_TURNO...
create table ACS_TURNO
(
  atu_id          NUMBER generated always as identity,
  atu_nombre      VARCHAR2(30) not null,
  atu_hora_inicio TIMESTAMP(6) not null,
  atu_hora_fin    TIMESTAMP(6) not null,
  atu_tipo_pago   VARCHAR2(10) not null,
  atu_costo       NUMBER not null,
  atu_pago        NUMBER not null,
  atu_estado      VARCHAR2(10) not null,
  apm_id          NUMBER,
  ame_id          NUMBER
)
;
comment on table ACS_TURNO
  is 'Tabla para representa, manejar y almacenarr los turnos medicos que hay en el sistema';
comment on column ACS_TURNO.atu_id
  is 'ID unico de cada turno';
comment on column ACS_TURNO.atu_nombre
  is 'Nombre unico del turno';
comment on column ACS_TURNO.atu_hora_inicio
  is 'Hora de inicio del turno';
comment on column ACS_TURNO.atu_hora_fin
  is 'Hora de finalización del turno';
comment on column ACS_TURNO.atu_tipo_pago
  is 'Campo para definir si se paga por hora o por turno';
comment on column ACS_TURNO.atu_costo
  is 'Costo que supone para el centro medico';
comment on column ACS_TURNO.atu_pago
  is 'Pago que se le hace al medico';
comment on column ACS_TURNO.atu_estado
  is 'Estado en el que se encuentra el turno';
alter table ACS_TURNO
  add constraint PK_ACS_TURNO primary key (ATU_ID);
alter table ACS_TURNO
  add constraint ATU_X_AME foreign key (AME_ID)
  references ACS_MEDICO (AME_ID);
alter table ACS_TURNO
  add constraint ATU_X_APM foreign key (APM_ID)
  references ACS_PUESTO_MEDICO (APM_ID);
alter table ACS_TURNO
  add constraint CHK_ATU_ESTADO
  check (ATU_ESTADO IN ('ACTIVO', 'INACTIVO'));
alter table ACS_TURNO
  add constraint CHK_ATU_TIPO_PAGO
  check (ATU_TIPO_PAGO IN ('TURNO', 'HORAS'));

prompt Creating ACS_TURNO_PLANILLA...
create table ACS_TURNO_PLANILLA
(
  atrp_id                   NUMBER generated always as identity,
  atrp_horas                NUMBER not null,
  atrp_monto_cobrado_centro NUMBER not null,
  atrp_monto_pagado_medico  NUMBER not null,
  atrp_procesado            NUMBER not null,
  atrp_fecha_procesamiento  TIMESTAMP(6),
  adp_id                    NUMBER not null,
  adm_id                    NUMBER not null
)
;
comment on table ACS_TURNO_PLANILLA
  is 'Tabla para representa, manejar y almacenar turnos de planillas que hay en el sistema';
comment on column ACS_TURNO_PLANILLA.atrp_id
  is 'Identificador único del turno procesado en planilla';
comment on column ACS_TURNO_PLANILLA.atrp_horas
  is 'Horas trabajadas';
comment on column ACS_TURNO_PLANILLA.atrp_monto_cobrado_centro
  is 'Monto cobrado al centro de salud';
comment on column ACS_TURNO_PLANILLA.atrp_monto_pagado_medico
  is 'Monto pagado al médico';
comment on column ACS_TURNO_PLANILLA.atrp_procesado
  is 'Indica si fue procesado';
comment on column ACS_TURNO_PLANILLA.atrp_fecha_procesamiento
  is 'Fecha de procesamiento';
comment on column ACS_TURNO_PLANILLA.adp_id
  is 'Detalle de planilla asociado';
comment on column ACS_TURNO_PLANILLA.adm_id
  is 'Turno mensual registrado';
alter table ACS_TURNO_PLANILLA
  add constraint PK_ACS_TURNO_PLANILLA primary key (ATRP_ID);
alter table ACS_TURNO_PLANILLA
  add constraint ATRP_X_ADM foreign key (ADM_ID)
  references ACS_DETALLE_MENSUAL (ADM_ID);
alter table ACS_TURNO_PLANILLA
  add constraint ATRP_X_ADP foreign key (ADP_ID)
  references ACS_DETALLE_PLANILLA (ADP_ID);
alter table ACS_TURNO_PLANILLA
  add constraint CHK_ATRP_PROCESADO
  check (ATRP_PROCESADO IN (0,1));

prompt Disabling triggers for ACS_AUDITORIA_DETALLE_MENSUAL...
alter table ACS_AUDITORIA_DETALLE_MENSUAL disable all triggers;
prompt Disabling triggers for ACS_CENTRO_MEDICO...
alter table ACS_CENTRO_MEDICO disable all triggers;
prompt Disabling triggers for ACS_ESCALA_MENSUAL...
alter table ACS_ESCALA_MENSUAL disable all triggers;
prompt Disabling triggers for ACS_PROCEDIMIENTO...
alter table ACS_PROCEDIMIENTO disable all triggers;
prompt Disabling triggers for ACS_PROC_APLICADO...
alter table ACS_PROC_APLICADO disable all triggers;
prompt Disabling triggers for ACS_PROCEDIMIENTOXCENTRO...
alter table ACS_PROCEDIMIENTOXCENTRO disable all triggers;
prompt Disabling triggers for ACS_PUESTO_MEDICO...
alter table ACS_PUESTO_MEDICO disable all triggers;
prompt Disabling triggers for ACS_PUESTOXCENTRO...
alter table ACS_PUESTOXCENTRO disable all triggers;
prompt Disabling triggers for ACS_RESUMEN_FIN_MENSUAL...
alter table ACS_RESUMEN_FIN_MENSUAL disable all triggers;
prompt Disabling triggers for ACS_TURNO...
alter table ACS_TURNO disable all triggers;
prompt Disabling triggers for ACS_TURNO_PLANILLA...
alter table ACS_TURNO_PLANILLA disable all triggers;
prompt Disabling foreign key constraints for ACS_ESCALA_MENSUAL...
alter table ACS_ESCALA_MENSUAL disable constraint AEM_X_ACM;
prompt Disabling foreign key constraints for ACS_PROC_APLICADO...
alter table ACS_PROC_APLICADO disable constraint APA_X_ACM;
alter table ACS_PROC_APLICADO disable constraint APA_X_AME;
alter table ACS_PROC_APLICADO disable constraint APA_X_APD;
prompt Disabling foreign key constraints for ACS_PROCEDIMIENTOXCENTRO...
alter table ACS_PROCEDIMIENTOXCENTRO disable constraint APRC_X_ACM;
alter table ACS_PROCEDIMIENTOXCENTRO disable constraint APRC_X_APD;
prompt Disabling foreign key constraints for ACS_PUESTOXCENTRO...
alter table ACS_PUESTOXCENTRO disable constraint APC_X_ACM;
alter table ACS_PUESTOXCENTRO disable constraint APC_X_APM;
prompt Disabling foreign key constraints for ACS_TURNO...
alter table ACS_TURNO disable constraint ATU_X_AME;
alter table ACS_TURNO disable constraint ATU_X_APM;
prompt Disabling foreign key constraints for ACS_TURNO_PLANILLA...
alter table ACS_TURNO_PLANILLA disable constraint ATRP_X_ADM;
alter table ACS_TURNO_PLANILLA disable constraint ATRP_X_ADP;
prompt Loading ACS_AUDITORIA_DETALLE_MENSUAL...
prompt Table is empty
prompt Loading ACS_CENTRO_MEDICO...
prompt Table is empty
prompt Loading ACS_ESCALA_MENSUAL...
prompt Table is empty
prompt Loading ACS_PROCEDIMIENTO...
prompt Table is empty
prompt Loading ACS_PROC_APLICADO...
prompt Table is empty
prompt Loading ACS_PROCEDIMIENTOXCENTRO...
prompt Table is empty
prompt Loading ACS_PUESTO_MEDICO...
prompt Table is empty
prompt Loading ACS_PUESTOXCENTRO...
prompt Table is empty
prompt Loading ACS_RESUMEN_FIN_MENSUAL...
prompt Table is empty
prompt Loading ACS_TURNO...
prompt Table is empty
prompt Loading ACS_TURNO_PLANILLA...
prompt Table is empty
prompt Enabling foreign key constraints for ACS_ESCALA_MENSUAL...
alter table ACS_ESCALA_MENSUAL enable constraint AEM_X_ACM;
prompt Enabling foreign key constraints for ACS_PROC_APLICADO...
alter table ACS_PROC_APLICADO enable constraint APA_X_ACM;
alter table ACS_PROC_APLICADO enable constraint APA_X_AME;
alter table ACS_PROC_APLICADO enable constraint APA_X_APD;
prompt Enabling foreign key constraints for ACS_PROCEDIMIENTOXCENTRO...
alter table ACS_PROCEDIMIENTOXCENTRO enable constraint APRC_X_ACM;
alter table ACS_PROCEDIMIENTOXCENTRO enable constraint APRC_X_APD;
prompt Enabling foreign key constraints for ACS_PUESTOXCENTRO...
alter table ACS_PUESTOXCENTRO enable constraint APC_X_ACM;
alter table ACS_PUESTOXCENTRO enable constraint APC_X_APM;
prompt Enabling foreign key constraints for ACS_TURNO...
alter table ACS_TURNO enable constraint ATU_X_AME;
alter table ACS_TURNO enable constraint ATU_X_APM;
prompt Enabling foreign key constraints for ACS_TURNO_PLANILLA...
alter table ACS_TURNO_PLANILLA enable constraint ATRP_X_ADM;
alter table ACS_TURNO_PLANILLA enable constraint ATRP_X_ADP;
prompt Enabling triggers for ACS_AUDITORIA_DETALLE_MENSUAL...
alter table ACS_AUDITORIA_DETALLE_MENSUAL enable all triggers;
prompt Enabling triggers for ACS_CENTRO_MEDICO...
alter table ACS_CENTRO_MEDICO enable all triggers;
prompt Enabling triggers for ACS_ESCALA_MENSUAL...
alter table ACS_ESCALA_MENSUAL enable all triggers;
prompt Enabling triggers for ACS_PROCEDIMIENTO...
alter table ACS_PROCEDIMIENTO enable all triggers;
prompt Enabling triggers for ACS_PROC_APLICADO...
alter table ACS_PROC_APLICADO enable all triggers;
prompt Enabling triggers for ACS_PROCEDIMIENTOXCENTRO...
alter table ACS_PROCEDIMIENTOXCENTRO enable all triggers;
prompt Enabling triggers for ACS_PUESTO_MEDICO...
alter table ACS_PUESTO_MEDICO enable all triggers;
prompt Enabling triggers for ACS_PUESTOXCENTRO...
alter table ACS_PUESTOXCENTRO enable all triggers;
prompt Enabling triggers for ACS_RESUMEN_FIN_MENSUAL...
alter table ACS_RESUMEN_FIN_MENSUAL enable all triggers;
prompt Enabling triggers for ACS_TURNO...
alter table ACS_TURNO enable all triggers;
prompt Enabling triggers for ACS_TURNO_PLANILLA...
alter table ACS_TURNO_PLANILLA enable all triggers;

set feedback on
set define on
prompt Done

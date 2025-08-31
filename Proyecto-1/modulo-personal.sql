-- Create sequence objects for IDs
create sequence asc_permiso_seq start with 1 increment by 1;
create sequence asc_accesos_seq start with 1 increment by 1;
create sequence asc_detalle_documento_seq start with 1 increment by 1;
create sequence asc_documento_seq start with 1 increment by 1;
create sequence asc_cuenta_bancaria_seq start with 1 increment by 1;
create sequence asc_prerregistro_seq start with 1 increment by 1;
create sequence asc_usuario_seq start with 1 increment by 1;
create sequence asc_medico_seq start with 1 increment by 1;
create sequence asc_administrativo_seq start with 1 increment by 1;

-- Create enum types as CHECK constraints

-- Create tables
create table asc_accesos (
   accesos_id   number primary key,
   tipo_usuario varchar2(20) check ( tipo_usuario in ( 'MEDICO',
                                                       'ADMINISTRATIVO' ) )
);

create table asc_permiso (
   permiso_id  number primary key,
   pantalla    varchar2(255) unique,
   lectura     number(1) default 0,
   escritura   number(1) default 0,
   eliminacion number(1) default 0,
   accesos_id  number,
   constraint fk_permiso_accesos foreign key ( accesos_id )
      references asc_accesos ( accesos_id )
);

create table asc_detalle_documento (
   detalle_documento_id  number primary key,
   tipo_usuario          varchar2(20) check ( tipo_usuario in ( 'MEDICO',
                                                       'ADMINISTRATIVO' ) ),
   documentos_requeridos varchar2(4000)
);

create table asc_usuario (
   usuario_id        number primary key,
   cedula            varchar2(20) unique,
   nombre            varchar2(100),
   apellidos         varchar2(100),
   fecha_nacimiento  date,
   sexo              varchar2(10),
   estado_civil      varchar2(20),
   tipo_nacionalidad varchar2(20) check ( tipo_nacionalidad in ( 'NACIONAL',
                                                                 'EXTRANJERO' ) ),
   tipo_usuario      varchar2(20) check ( tipo_usuario in ( 'MEDICO',
                                                       'ADMINISTRATIVO' ) ),
   email             varchar2(255) unique,
   telefono          varchar2(20),
   residencia        varchar2(255),
   direccion_casa    varchar2(255),
   direccion_trabajo varchar2(255)
);

create table asc_medico (
   medico_id  number primary key,
   estado     varchar2(20) default 'ACTIVO' check ( estado in ( 'ACTIVO',
                                                            'INACTIVO' ) ),
   usuario_id number unique,
   constraint fk_medico_usuario foreign key ( usuario_id )
      references asc_usuario ( usuario_id )
);

create table asc_administrativo (
   administrativo_id number primary key,
   estado            varchar2(20) default 'ACTIVO' check ( estado in ( 'ACTIVO',
                                                            'INACTIVO' ) ),
   usuario_id        number unique,
   constraint fk_administrativo_usuario foreign key ( usuario_id )
      references asc_usuario ( usuario_id )
);

create table asc_documento (
   documento_id      number primary key,
   url               varchar2(1000) unique,
   descripcion       varchar2(4000),
   medico_id         number,
   administrativo_id number,
   constraint fk_documento_medico foreign key ( medico_id )
      references asc_medico ( medico_id ),
   constraint fk_documento_administrativo foreign key ( administrativo_id )
      references asc_administrativo ( administrativo_id )
);

create table asc_cuenta_bancaria (
   cuentabancaria_id number primary key,
   banco             varchar2(100),
   numero            varchar2(50) unique,
   titular           varchar2(200),
   tipo_cuenta       varchar2(20) check ( tipo_cuenta in ( 'AHORROS',
                                                     'CORRIENTE' ) ),
   es_principal      number(1),
   usuario_id        number,
   constraint fk_cuentabancaria_usuario foreign key ( usuario_id )
      references asc_usuario ( usuario_id )
);

create table asc_prerregistro (
   prerregistro_id   number primary key,
   cedula            varchar2(20) unique,
   nombre            varchar2(100),
   apellidos         varchar2(100),
   fecha_nacimiento  date,
   sexo              varchar2(10),
   estado_civil      varchar2(20),
   nacionalidad      varchar2(20) check ( nacionalidad in ( 'NACIONAL',
                                                       'EXTRANJERO' ) ),
   residencia        varchar2(255),
   email             varchar2(255) unique,
   telefono          varchar2(20),
   direccion_casa    varchar2(255),
   direccion_trabajo varchar2(255),
   estado_registro   varchar2(20) default 'PENDIENTE' check ( estado_registro in ( 'PENDIENTE',
                                                                                 'APROBADO',
                                                                                 'RECHAZADO' ) )
);

-- Create triggers for auto-incrementing IDs
create or replace trigger asc_permiso_trg before
   insert on asc_permiso
   for each row
begin
   select asc_permiso_seq.nextval
     into :new.permiso_id
     from dual;
end;
/

create or replace trigger asc_accesos_trg before
   insert on asc_accesos
   for each row
begin
   select asc_accesos_seq.nextval
     into :new.accesos_id
     from dual;
end;
/

create or replace trigger asc_detalle_documento_trg before
   insert on asc_detalle_documento
   for each row
begin
   select asc_detalle_documento_seq.nextval
     into :new.detalle_documento_id
     from dual;
end;
/

create or replace trigger asc_documento_trg before
   insert on asc_documento
   for each row
begin
   select asc_documento_seq.nextval
     into :new.documento_id
     from dual;
end;
/

create or replace trigger asc_cuenta_bancaria_trg before
   insert on asc_cuenta_bancaria
   for each row
begin
   select asc_cuenta_bancaria_seq.nextval
     into :new.cuentabancaria_id
     from dual;
end;
/

create or replace trigger asc_prerregistro_trg before
   insert on asc_prerregistro
   for each row
begin
   select asc_prerregistro_seq.nextval
     into :new.prerregistro_id
     from dual;
end;
/

create or replace trigger asc_usuario_trg before
   insert on asc_usuario
   for each row
begin
   select asc_usuario_seq.nextval
     into :new.usuario_id
     from dual;
end;
/

create or replace trigger asc_medico_trg before
   insert on asc_medico
   for each row
begin
   select asc_medico_seq.nextval
     into :new.medico_id
     from dual;
end;
/

create or replace trigger asc_administrativo_trg before
   insert on asc_administrativo
   for each row
begin
   select asc_administrativo_seq.nextval
     into :new.administrativo_id
     from dual;
end;
/
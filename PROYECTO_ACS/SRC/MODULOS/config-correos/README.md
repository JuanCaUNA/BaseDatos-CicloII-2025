# Orden

Correr correos.sql. secciones:

en permisos_usuario.sql:

- Asignacion de permisos al usuario, con un usuario con privilegios de sysdba,

en correos.sql:

- Crear tablas parametros y clves, configurar metodos
- asignar los datos de las tablas de paremetros y claves
- Configurar ACL para envio de correos via SMTP
- Crear procedimiento almacenado para envio de correos via SMTP, sin TLS (no ocupa wallet)

en pruebas.sql:

- Algunos tests y ejemplos de uso.

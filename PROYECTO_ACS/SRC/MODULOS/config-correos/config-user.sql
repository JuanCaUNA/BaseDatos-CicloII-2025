/*
Como DBA con el usuario sys as sysdba, ejecutar este script para configurar los privilegios necesarios para el envío de correos desde Oracle.
opciones
1- asignar privilegios directamente al usuario que envía correos (ejemplo: JUAN)
2- Crear la configuracion con un usuario como sys y luego asignar los privilegios al usuario que envía correos (ejemplo: JUAN)
*/

GRANT EXECUTE ON SYS.UTL_SMTP TO JUAN;                 -- PARA ENVIO DE CORREOS
GRANT EXECUTE ON SYS.UTL_TCP TO JUAN;                  -- PARA CONEXIONES TCP
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO JUAN;              -- PARA ENCRIPTACION/DESENCRIPTACION
GRANT EXECUTE ON SYS.DBMS_NETWORK_ACL_ADMIN TO JUAN;   -- PARA GESTION DE ACLS, HACE QUE EL ROL PUEDA CONFIGURAR PERMISOS DE RED
/
-- ASIGNAR ROL AL USUARIO QUE ENVIA CORREOS
GRANT CONNECT TO JUAN;
GRANT RESOURCE TO JUAN;
/
-- ----
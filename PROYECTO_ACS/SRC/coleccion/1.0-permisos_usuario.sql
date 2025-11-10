/*
Mediante un usuario con privilegios de sysdba, asignar los permisos necesarios al usuario que enviará correos.
*/

-- Roles nesesarios para crear tablas, prc y similares.
GRANT CONNECT TO JUAN;
GRANT RESOURCE TO JUAN;
/
-- Permisos para envio de correo
GRANT EXECUTE ON SYS.UTL_SMTP TO JUAN;                 -- PARA ENVIO DE CORREOS
GRANT EXECUTE ON SYS.UTL_TCP TO JUAN;                  -- PARA CONEXIONES TCP
GRANT EXECUTE ON SYS.DBMS_NETWORK_ACL_ADMIN TO JUAN;   -- PARA GESTION DE ACLS, HACE QUE EL ROL PUEDA CONFIGURAR PERMISOS DE RED
/
-- gestion de encriptacion y desencriptacion
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO JUAN;              -- PARA ENCRIPTACION/DESENCRIPTACION
/
-- Para cargar archivos: Padron
GRANT CREATE ANY DIRECTORY TO JUAN;
/
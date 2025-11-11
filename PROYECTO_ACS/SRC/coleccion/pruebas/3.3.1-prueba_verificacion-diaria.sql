-- test generar invalidos, procedimeinto invalido
CREATE OR REPLACE PROCEDURE ACS_PRC_INVALIDO_TEST AS
BEGIN
    select * from non_existing_table;
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PROCEDURE PROC_INVALIDO AS BEGIN 1/0; END;';
END;


-- Probar el job manualmente
BEGIN
    DBMS_SCHEDULER.RUN_JOB('ACS_CHK_JOB_DIARIO');
END;
/
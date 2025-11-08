# Guía de Jobs en Oracle 19c

## ¿Qué es un Job en Oracle?

Un **Job** es una tarea automatizada que se ejecuta en segundo plano mediante el **Oracle Scheduler**. Permite programar tareas como consultas, procedimientos, backups, etc.

---

## 1. Creación de Jobs

### Usando PL/SQL

```sql
BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'mi_job_ejemplo',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN mi_procedimiento; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=2',
        enabled         => TRUE
    );
END;
/
```

- `job_name`: Nombre único del job.
- `job_type`: Tipo de tarea (`PLSQL_BLOCK`, `STORED_PROCEDURE`, `EXECUTABLE`).
- `job_action`: Código o procedimiento a ejecutar.
- `start_date`: Fecha/hora de inicio.
- `repeat_interval`: Frecuencia de ejecución.
- `enabled`: Si el job está activo.

---

## 2. Uso de Jobs

- Los jobs se ejecutan automáticamente según la programación.
- Se pueden ejecutar manualmente:

```sql
EXEC DBMS_SCHEDULER.run_job('mi_job_ejemplo');
```

---

## 3. Administración de Jobs

### Consultar Jobs

```sql
SELECT job_name, status, last_start_date, next_run_date
FROM dba_scheduler_jobs;
```

### Habilitar/Deshabilitar Jobs

```sql
EXEC DBMS_SCHEDULER.enable('mi_job_ejemplo');
EXEC DBMS_SCHEDULER.disable('mi_job_ejemplo');
```

### Eliminar Jobs

```sql
BEGIN
    DBMS_SCHEDULER.drop_job('mi_job_ejemplo');
END;
/
```

---

## 4. Buenas Prácticas

- Usar nombres descriptivos.
- Documentar la acción del job.
- Revisar logs y resultados periódicamente.
- Limitar privilegios de creación y administración.

---

## Referencias

- [Oracle Docs: DBMS_SCHEDULER](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_SCHEDULER.html)
- [Oracle Scheduler Concepts](https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/managing-scheduler-jobs-and-job-classes.html)

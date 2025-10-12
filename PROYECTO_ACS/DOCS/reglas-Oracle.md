# Reglas de Oracle para la Creación de Tablas, Atributos y 3FN

## 1. Reglas para la Creación de Tablas en Oracle

- **Nombre de la tabla**: Debe comenzar con una letra y puede contener letras, números y el carácter de subrayado (`_`). No puede exceder los 30 caracteres. se recomienda que maximo sea 25 caracteres
- **Único en el esquema**: El nombre de la tabla debe ser único dentro del esquema.
- **Palabras reservadas**: No se pueden usar palabras reservadas de Oracle como nombres de tablas.
- **Sintaxis básica**:

    ```sql
    CREATE TABLE nombre_tabla (
        columna1 tipo_dato [restricciones],
        columna2 tipo_dato [restricciones],
        ...
    );
    ```

- **Tipos de datos comunes**:
  - `VARCHAR2(n)`: Cadena de caracteres de longitud variable.
  - `NUMBER(p,s)`: Números con precisión y escala.
  - `DATE`: Fecha y hora.
  - `CHAR(n)`: Cadena de longitud fija.

## 2. Reglas para la Definición de Atributos (Columnas)

- **Nombre de columna**: Sigue las mismas reglas que los nombres de tablas.
- **Tipo de dato**: Debe ser compatible con los valores que almacenará.
- **Restricciones**:
  - `NOT NULL`: No permite valores nulos.
  - `UNIQUE`: El valor debe ser único en la columna.
  - `PRIMARY KEY`: Identifica de forma única cada fila.
  - `FOREIGN KEY`: Define una relación con otra tabla.
  - `CHECK`: Restringe los valores permitidos.
  - `DEFAULT`: Valor por defecto si no se especifica uno.

    Ejemplo:

    ```sql
    CREATE TABLE empleados (
        id_empleado NUMBER(6) PRIMARY KEY,
        nombre VARCHAR2(50) NOT NULL,
        salario NUMBER(8,2) CHECK (salario > 0),
        fecha_ingreso DATE DEFAULT SYSDATE
    );
    ```

## 3. Tercera Forma Normal (3FN)

La **Tercera Forma Normal (3FN)** es una regla de normalización para el diseño de bases de datos relacionales que busca eliminar la redundancia y asegurar la integridad de los datos.

### Reglas para cumplir 3FN

1. **Cumplir 1FN**: Todos los atributos deben ser atómicos (sin valores repetidos o conjuntos).
2. **Cumplir 2FN**: Todos los atributos no clave deben depender completamente de la clave primaria.
3. **Eliminar dependencias transitivas**: Ningún atributo no clave debe depender de otro atributo no clave.

### Ejemplo

Supongamos la siguiente tabla no normalizada:

| id_empleado | nombre   | id_departamento | nombre_departamento |
|-------------|----------|-----------------|--------------------|
| 1           | Ana      | 10              | Ventas             |
| 2           | Juan     | 20              | Compras            |

**Problema**: `nombre_departamento` depende de `id_departamento`, no de la clave primaria.

**Solución en 3FN**:

- Tabla `empleados`:

    | id_empleado | nombre   | id_departamento |
    |-------------|----------|-----------------|
    | 1           | Ana      | 10              |
    | 2           | Juan     | 20              |

- Tabla `departamentos`:

    | id_departamento | nombre_departamento |
    |-----------------|--------------------|
    | 10              | Ventas             |
    | 20              | Compras            |

Así, se eliminan las dependencias transitivas y se cumple la 3FN.

---

**Referencias**:

- [Documentación oficial de Oracle](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [Normalización de bases de datos](https://es.wikipedia.org/wiki/Normalizaci%C3%B3n_de_bases_de_datos)

## notas

las relaciones en prisma que se presentan como [] son en realidad tablas intermedias al memento de pasarlo a sql

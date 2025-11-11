# 🎯 CARPETA DE DEMOSTRACIÓN PARA DEFENSA DEL PROYECTO

## 📁 Contenido de Esta Carpeta

Esta carpeta contiene todos los archivos necesarios para realizar una **demostración profesional e impactante** del módulo de planillas del Sistema ACS durante la defensa del proyecto con el profesor.

---

## 📄 Archivos Incluidos

### 1. `config_sqlplus_profesional.sql` ⚙️

**Propósito:** Configurar el entorno SQL\*Plus para salidas visuales profesionales

**Qué hace:**

- Habilita `SERVEROUTPUT` para ver mensajes de procedimientos
- Configura formato de columnas (nombres, montos, fechas)
- Establece formato de fecha en español
- Configura símbolo de moneda costarricense (₡)
- Define variables de sustitución para mes/año de prueba

**Cuándo ejecutar:** PRIMERO, al iniciar SQL\*Plus

```sql
SQL> @SRC/modules/planillas/demo/config_sqlplus_profesional.sql
```

---

### 2. `demo_defensa_profesor.sql` 🎬

**Propósito:** Script maestro que ejecuta toda la demostración paso a paso

**Qué incluye:**

- ✅ Encabezado visual impactante con logo de la universidad
- ✅ Verificación de prerrequisitos (objetos compilados, datos cargados)
- ✅ Generación de planillas de médicos (Punto 3 - 12%)
- ✅ Generación de planillas administrativas (Punto 4 - 12%)
- ✅ Validaciones de integridad de datos
- ✅ Demostración de trazabilidad y auditoría
- ✅ Resumen final con estadísticas

**Duración estimada:** 15-20 minutos

**Cuándo ejecutar:** DESPUÉS de configurar SQL\*Plus

```sql
SQL> @SRC/modules/planillas/demo/demo_defensa_profesor.sql
```

**Características especiales:**

- Pausas interactivas (presionar ENTER entre secciones)
- Formato visual con cajas y líneas decorativas
- Símbolos Unicode (✓, ✗, ℹ, →)
- Montos en colones costarricenses (₡)
- Timing de ejecución de procesos
- Salidas tabulares profesionales

---

### 3. `GUIA_DEFENSA_PROFESOR.md` 📚

**Propósito:** Guía completa para preparar y ejecutar la defensa

**Qué incluye:**

- 📋 Checklist de preparación previa
- 🎯 Pasos detallados de ejecución
- 📸 Capturas de pantalla esperadas
- ❓ Respuestas a preguntas frecuentes del profesor
- 🔧 Resolución de problemas comunes
- 🎬 Guion sugerido para la defensa
- ✅ Puntos fuertes a destacar

**Cuándo leer:** ANTES de la defensa (idealmente la noche anterior)

**Formato:** Markdown (se ve mejor en VS Code o GitHub)

---

## 🚀 GUÍA RÁPIDA DE USO

### Paso 1: Preparación (30 minutos antes)

```bash
# 1. Conectarse a la base de datos
sqlplus mora/mora@localhost:1521/orclpdb

# 2. Configurar SQL*Plus
SQL> @SRC/modules/planillas/demo/config_sqlplus_profesional.sql

# 3. Verificar objetos compilados
SQL> SELECT object_name, status FROM user_objects
     WHERE object_name LIKE 'PRC_GENERAR%' OR object_name = 'FUN_CALCULAR_MOVIMIENTO';

# Deben aparecer todos con STATUS = 'VALID'
```

### Paso 2: Ejecución (durante la defensa)

```sql
-- Ejecutar script maestro
SQL> @SRC/modules/planillas/demo/demo_defensa_profesor.sql

-- El script hará pausas. Presione ENTER para continuar entre secciones.
```

### Paso 3: Responder preguntas

Consulte `GUIA_DEFENSA_PROFESOR.md` sección "Preguntas Frecuentes"

---

## 🎨 SALIDA VISUAL ESPERADA

### Encabezado

```
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║         SISTEMA DE ADMINISTRACIÓN DE CENTROS DE SALUD (ACS)               ║
║                                                                            ║
║                    DEMOSTRACIÓN DE FUNCIONALIDAD                          ║
║                         MÓDULO DE PLANILLAS                               ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

### Tablas Formateadas

```
Nombre Completo                    Salario Base      Bruto          Deducciones    Neto
────────────────────────────────── ───────────────── ────────────── ────────────── ──────────────
Juan Carlos Pérez González         ₡ 1,200,000.00    ₡ 1,200,000.00 ₡ 151,899.90   ₡ 1,048,100.10
María José González Rodríguez      ₡ 1,150,000.00    ₡ 1,150,000.00 ₡ 144,399.95   ₡ 1,005,600.05
```

### Validaciones

```
┌────────────────────────────────────────────────────────────────────────┐
│ 4.1 - Verificando consistencia: Totales de encabezado vs detalles     │
└────────────────────────────────────────────────────────────────────────┘

ID Planilla  Tipo              Validación Bruto  Validación Deducc  Validación Neto
──────────── ───────────────── ──────────────── ────────────────── ───────────────
          45 PLANILLA MEDICOS  ✓ OK              ✓ OK               ✓ OK
          46 PLANILLA ADMIN    ✓ OK              ✓ OK               ✓ OK
```

---

## 📊 PUNTOS DE LA RÚBRICA DEMOSTRADOS

| Punto     | Descripción               | Valor   | Archivo Demo       |
| --------- | ------------------------- | ------- | ------------------ |
| **3**     | Planillas de Médicos      | 12%     | Parte 2 del script |
| **4**     | Planillas Administrativas | 12%     | Parte 3 del script |
| **Total** |                           | **24%** |                    |

---

## 🎯 CARACTERÍSTICAS DESTACABLES

### 1. Formato Visual Profesional

- Uso de caracteres Unicode para cajas y símbolos
- Alineación perfecta de columnas
- Colores mediante símbolos (✓ verde, ✗ rojo)
- Separadores visuales entre secciones

### 2. Información Completa

- Verificación de prerrequisitos
- Ejecución de procesos con timing
- Validaciones de integridad
- Trazabilidad completa

### 3. Interactividad

- Pausas entre secciones (ENTER para continuar)
- Mensajes informativos durante ejecución
- Progress tracking en tiempo real

### 4. Cumplimiento de Rúbrica

- Cada sección está etiquetada con su punto de rúbrica
- Porcentajes claramente indicados
- Ejemplos específicos de cada funcionalidad

---

## 🔧 RESOLUCIÓN DE PROBLEMAS

### Problema: "No se ven las salidas bonitas"

**Solución:**

```sql
-- Ejecutar config_sqlplus_profesional.sql primero
SQL> @SRC/modules/planillas/demo/config_sqlplus_profesional.sql
```

### Problema: "ORA-00942: table or view does not exist"

**Solución:**

```sql
-- Verificar que las tablas existen
SQL> SELECT table_name FROM user_tables WHERE table_name LIKE 'ACS%';

-- Si faltan tablas, ejecutar script completo
SQL> @SRC/database/acs_script_completo.sql
```

### Problema: "PLS-00201: identifier must be declared"

**Solución:**

```sql
-- Compilar objetos
SQL> @SRC/modules/planillas/procedures/fun_calcular_movimiento.sql
SQL> @SRC/modules/planillas/procedures/prc_generar_planillas_medicos_v2.sql
SQL> @SRC/modules/planillas/procedures/prc_generar_planillas_admin_v2.sql
```

### Problema: "No data found"

**Solución:**

```sql
-- Cargar datos de prueba
SQL> @SRC/modules/planillas/seed_data/seed_simple.sql
```

---

## 📝 CHECKLIST PRE-DEFENSA

Imprima esta lista y márquela antes de la defensa:

```
□ Leer GUIA_DEFENSA_PROFESOR.md completamente
□ Verificar que Oracle 19c está corriendo
□ Conectar como usuario MORA
□ Ejecutar config_sqlplus_profesional.sql
□ Verificar objetos compilados (VALID)
□ Verificar datos de prueba cargados
□ Ejecutar demo_defensa_profesor.sql una vez (práctica)
□ Leer sección "Preguntas Frecuentes"
□ Tener esta guía disponible durante la defensa
□ Configurar segunda pantalla (opcional, recomendado)
```

---

## 🎬 FLUJO SUGERIDO DE LA DEFENSA

### 1. Introducción (2 minutos)

> "Profesor, vamos a demostrar el módulo de planillas. Hemos implementado los puntos 3 y 4 de la rúbrica (24%). El sistema genera automáticamente planillas de médicos y administrativos con cálculos de impuesto progresivo."

### 2. Configuración (1 minuto)

```sql
SQL> @SRC/modules/planillas/demo/config_sqlplus_profesional.sql
```

### 3. Demostración (12 minutos)

```sql
SQL> @SRC/modules/planillas/demo/demo_defensa_profesor.sql
-- Ir presionando ENTER en cada pausa
-- Explicar qué hace cada sección mientras se ejecuta
```

### 4. Preguntas (5 minutos)

Consultar GUIA_DEFENSA_PROFESOR.md para respuestas preparadas

---

## 💡 CONSEJOS PRO

1. **Practicar Antes:** Ejecute el demo completo al menos una vez antes de la defensa
2. **Segunda Pantalla:** Tenga la guía abierta en otra pantalla o impresa
3. **Velocidad de Lectura:** No corra. Deje que el profesor lea las salidas
4. **Explicar Mientras Ejecuta:** Comente qué está haciendo cada sección
5. **Mostrar el Código:** Si el profesor pregunta, muestre el código de los procedimientos
6. **Destacar Puntos Fuertes:** Mencione la reutilización de código, integridad, trazabilidad

---

## 🎓 PUNTOS FUERTES A MENCIONAR

Durante la defensa, destaque:

### Técnicos

- ✅ Uso de funciones genéricas reutilizables
- ✅ Manejo correcto de transacciones (COMMIT/ROLLBACK)
- ✅ Validaciones de integridad múltiples
- ✅ Trazabilidad completa con auditoría

### De Negocio

- ✅ Cálculo progresivo real de impuestos Costa Rica
- ✅ Diferenciación médicos vs administrativos
- ✅ Movimientos exclusivos por tipo de personal
- ✅ Manejo de turnos HORAS vs TURNO

### De Calidad

- ✅ Código comentado en español
- ✅ Nombres de variables descriptivos
- ✅ Mensajes de error informativos
- ✅ Documentación completa

---

## 📞 SOPORTE DURANTE LA DEFENSA

Si algo sale mal:

1. **Mantener la calma** 😌
2. **Consultar esta guía** 📚
3. **Verificar prerrequisitos** ✅
4. **Reiniciar desde compilación si es necesario** 🔄

**Recuerde:** El sistema está probado y funciona. Si sigue los pasos, saldrá perfecto.

---

## 🎉 DESPUÉS DE LA DEFENSA

Si el profesor pide:

### Ver el código fuente

```sql
-- Funciones
SQL> SELECT text FROM user_source
     WHERE name = 'FUN_CALCULAR_MOVIMIENTO' AND type = 'FUNCTION'
     ORDER BY line;

-- Procedimientos
SQL> SELECT text FROM user_source
     WHERE name = 'PRC_GENERAR_PLANILLAS_MEDICOS' AND type = 'PROCEDURE'
     ORDER BY line;
```

### Ejecutar con otros datos

```sql
-- Cambiar mes/año
SQL> EXECUTE PRC_GENERAR_PLANILLAS_MEDICOS(12, 2025);
SQL> EXECUTE PRC_GENERAR_PLANILLAS_ADMIN(12, 2025);
```

### Ver la base de datos completa

```sql
-- Listar todas las tablas
SQL> SELECT table_name FROM user_tables ORDER BY table_name;

-- Ver relaciones
SQL> SELECT constraint_name, table_name, r_constraint_name
     FROM user_constraints
     WHERE constraint_type = 'R';
```

---

## 📄 ESTRUCTURA DE ARCHIVOS

```
demo/
├── README.md                          ← Este archivo
├── config_sqlplus_profesional.sql     ← Configuración de SQL*Plus
├── demo_defensa_profesor.sql          ← Script principal de demostración
└── GUIA_DEFENSA_PROFESOR.md           ← Guía detallada con respuestas
```

---

## ✅ ESTADO DEL SISTEMA

```
Sistema: ✅ OPERATIVO
Objetos: ✅ COMPILADOS
Datos:   ✅ CARGADOS
Tests:   ✅ PASADOS
Demo:    ✅ LISTA
Documentación: ✅ COMPLETA
```

---

## 🎯 OBJETIVO FINAL

**Demostrar al profesor que:**

1. ✅ Entendemos los procesos de negocio (planillas, impuestos)
2. ✅ Dominamos Oracle PL/SQL (funciones, procedimientos, transacciones)
3. ✅ Escribimos código profesional (limpio, documentado, mantenible)
4. ✅ Cumplimos la rúbrica (puntos 3 y 4 = 24%)
5. ✅ Podemos defender y explicar nuestro trabajo

---

## 🎊 ¡BUENA SUERTE!

Siga esta guía y la defensa será un éxito.

**Recuerde:** Usted sabe lo que hizo. Solo necesita mostrarlo de forma clara y profesional.

---

**Universidad Nacional - Sede Región Brunca**  
**Administración de Bases de Datos - II Ciclo 2025**  
**Sistema ACS - Módulo de Planillas**

---

_Última actualización: 09-NOV-2025_

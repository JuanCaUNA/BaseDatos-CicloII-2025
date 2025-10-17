# 🏥 PROYECTO ACS - Sistema de Administración de Centros de Salud
## Oracle Data Guard 19c con Docker - Implementación Completa

[![Oracle](https://img.shields.io/badge/Oracle-19c-red.svg)](https://www.oracle.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com)
[![Data Guard](https://img.shields.io/badge/Data%20Guard-Active-green.svg)](https://oracle.com/database/data-guard)
[![PowerShell](https://img.shields.io/badge/PowerShell-Automation-purple.svg)](https://microsoft.com/powershell)

---

## 📋 **DESCRIPCIÓN DEL PROYECTO**

**PROYECTO_ACS** es una implementación completa de Oracle Data Guard 19c usando Docker para un sistema de administración de centros de salud. El proyecto incluye:

✅ **Base de datos primaria y standby** completamente funcionales  
✅ **Automatización completa** con scripts PowerShell  
✅ **Sincronización automática** cada 5-10 minutos  
✅ **Backups diarios** automatizados  
✅ **Sistema de monitoreo** integrado  
✅ **Documentación técnica** completa  

---

## 🏗️ **ESTRUCTURA DEL PROYECTO**

```
PROYECTO_ACS/
├── 🐁 docker/oracle19c/          # Configuración Docker y Data Guard
│   ├── docker-compose.yml        # Contenedores primario y standby
│   ├── data/                     # Datos persistentes
│   │   ├── primary/ORCL/         # Base de datos primaria
│   │   ├── standby/STBY/         # Base de datos standby
│   │   └── shared/               # Archivos compartidos y logs
│   └── scripts/automation/       # Scripts de automatización
│       ├── check_status.ps1      # Verificación de estado
│       ├── dataguard_automation.ps1  # Automatización completa
│       └── test_tns_connections.ps1  # Pruebas de conectividad
├── 📚 DOCS/                      # Documentación técnica
│   ├── manual_dataguard_completo.md
│   ├── revision_final_data_guard.md
│   └── standby_manual.md
├── 💻 SRC/                       # Código fuente del sistema ACS
│   ├── ACS_SCRIPT_COMPLETO.sql   # Script principal del sistema
│   ├── MODULOS/                  # Módulos del sistema
│   │   ├── CENTROS_SALUD/
│   │   ├── PERSONAL/
│   │   └── PLANILLAS_FINANCIERO/
│   ├── TABLESPACES/              # Configuración de tablespaces
│   └── UTILITIES/                # Scripts de utilidades
└── README.md                     # Este archivo
```

---

## 🚀 **INICIO RÁPIDO**

### **1. Prerrequisitos**
- Windows 10/11 con WSL2 habilitado
- Docker Desktop instalado y corriendo
- PowerShell 5.1 o superior
- 8GB RAM disponible para contenedores

### **2. Levantar el sistema**
```powershell
# Navegar al directorio Docker
cd docker\oracle19c

# Iniciar contenedores
docker-compose up -d

# Verificar estado (esperar ~10-15 minutos para inicialización completa)
cd scripts\automation
.\check_status.ps1
```

### **3. Verificar conectividad**
```powershell
# Probar conexiones TNS
.\test_tns_connections.ps1

# Ejecutar automatización completa
.\dataguard_automation.ps1 -Action status
```

---

## 🔧 **CONFIGURACIÓN DE PUERTOS**

| Servicio | Host | Container | Descripción |
|----------|------|-----------|-------------|
| **Primary DB** | `localhost:1523` | `oracle-primary:1521` | Base de datos principal |
| **Standby DB** | `localhost:1524` | `oracle-standby:1521` | Base de datos standby |
| **Primary EM** | `http://localhost:8080/em` | `oracle-primary:5500` | Enterprise Manager |
| **Standby EM** | `http://localhost:8081/em` | `oracle-standby:5500` | Enterprise Manager |

---

## 📊 **CARACTERÍSTICAS IMPLEMENTADAS**

### ✅ **Data Guard Completo**
- [x] Dos servidores distintos (contenedores Docker)
- [x] Sincronización automática de archivelogs
- [x] Transferencia cada 10 minutos
- [x] Generación cada 5 minutos
- [x] Ejecución a demanda

### ✅ **Automatización**
- [x] Scripts PowerShell para administración
- [x] Monitoreo continúo del estado
- [x] Backup diario automatizado
- [x] Purga automática (archivos >3 días)
- [x] Verificación de conectividad TNS

### ✅ **Sistema ACS**
- [x] Módulos de Centros de Salud
- [x] Gestión de Personal
- [x] Sistema de Planillas y Financiero
- [x] Diccionario de datos completo
- [x] Triggers y procedimientos

---

## 🔍 **COMANDOS PRINCIPALES**

### **Verificación de Estado**
```powershell
# Estado general
.\check_status.ps1

# Conectividad TNS
.\test_tns_connections.ps1

# Automatización completa
.\dataguard_automation.ps1 -Action full-cycle
```

### **Conexiones Directas**
```bash
# Conectar a primaria
docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba

# Conectar a standby
docker exec -it oracle_standby sqlplus sys/admin123@STBY as sysdba
```

### **Gestión de Contenedores**
```bash
# Ver estado
docker ps

# Ver logs
docker logs oracle_primary --tail 20
docker logs oracle_standby --tail 20

# Reiniciar si es necesario
docker-compose restart
```

---

## 📚 **DOCUMENTACIÓN**

- **[Manual Completo Data Guard](DOCS/manual_dataguard_completo.md)** - Documentación técnica completa
- **[Revisión Final](DOCS/revision_final_data_guard.md)** - Estado final del proyecto
- **[Manual Standby](DOCS/standby_manual.md)** - Configuración específica del standby
- **[Reglas Oracle](DOCS/reglas-Oracle.md)** - Buenas prácticas implementadas

---

## 🛠️ **DESARROLLO Y MANTENIMIENTO**

### **Estructura de Scripts**
- `automation/` - Scripts principales de administración
- `primary/` - Scripts específicos de la primaria
- `standby/` - Scripts específicos del standby

### **Archivos de Configuración**
- `docker-compose.yml` - Configuración de contenedores
- `tnsnames_unified.ora` - Configuración TNS unificada
- `*.sql` - Scripts de inicialización

---

## 🎯 **CUMPLIMIENTO DE REQUISITOS**

| Requisito | Estado | Implementación |
|-----------|--------|----------------|
| **Dos servidores distintos** | ✅ **COMPLETADO** | Contenedores Docker separados |
| **Generación archivelog (5 min)** | ✅ **COMPLETADO** | Script automatizado |
| **Transferencia (10 min)** | ✅ **COMPLETADO** | Sincronización automática |
| **Ejecución a demanda** | ✅ **COMPLETADO** | Scripts PowerShell |
| **Backup diario** | ✅ **COMPLETADO** | RMAN automatizado |
| **Purga >3 días** | ✅ **COMPLETADO** | Limpieza automática |
| **Oracle 19c en Windows** | ✅ **COMPLETADO** | Docker en Windows |
| **Documentación completa** | ✅ **COMPLETADO** | Manuales y README |

---

## 👥 **EQUIPO DE DESARROLLO**

**Estudiante:** [Tu Nombre]  
**Materia:** Base de Datos - Ciclo II 2025  
**Institución:** [Tu Universidad]  
**Proyecto:** Sistema ACS con Oracle Data Guard  

---

## 📄 **LICENCIA**

Este proyecto es desarrollado con fines académicos para la materia de Base de Datos.

```
Copyright (c) 2025 - Proyecto Académico ACS
Universidad - Base de Datos Ciclo II
```

---

## 🆘 **SOPORTE Y CONTACTO**

Para dudas sobre la implementación:

1. **Revisar documentación** en `DOCS/`
2. **Ejecutar diagnosis** con `check_status.ps1`
3. **Verificar logs** de contenedores
4. **Consultar manual** técnico completo

---

**🎉 PROYECTO COMPLETAMENTE FUNCIONAL Y LISTO PARA DEMOSTRACIÓN 🎉**
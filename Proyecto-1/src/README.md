# Proyecto-1 - Estructura de despliegue

Estructura de ejemplo para organizar scripts por módulos: `planillas_financiero`, `personal`, `medicos`, `tablespaces`, `utilities`.

Orden recomendado de despliegue:
1. `src/tablespaces` (si aplica)
2. `src/common` (objetos compartidos)
3. `src/<modulo>/procs` (procedimientos y packages)
4. `src/<modulo>/trgs` (triggers)

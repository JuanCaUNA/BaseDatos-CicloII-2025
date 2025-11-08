# Estructura de código

El repositorio agrupa el código SQL del proyecto en dos ejes principales:

- `src/database/`: objetos compartidos a nivel global (script maestro, exportación del proyecto, definiciones de tablespaces, utilitarios y diccionario de datos).
- `src/modules/<modulo>/`: componentes específicos por dominio funcional (`centros_salud`, `config_correos`, `financiero`, `general`, `personal`, `planillas`). Cada módulo conserva subcarpetas estandarizadas `procedures/`, `triggers/` y, cuando aplica, `tests/`.

## Orden sugerido de despliegue

1. `src/database/tablespaces` (creación de estructuras físicas).
2. `src/database/acs_script_completo.sql` u objetos comunes requeridos por todos los módulos.
3. `src/modules/<modulo>/procedures` para cargar lógica de negocio.
4. `src/modules/<modulo>/triggers` y `src/modules/<modulo>/tests` para activar validaciones y verificaciones.

> Ajusta el orden según dependencias particulares del módulo o del entorno en el que se despliega.

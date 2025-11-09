**Universidad Nacional Sede Región Brunca
Facultad de Ciencias Exactas y Naturales
Escuela de Informática
Curso: Administración de Bases de Datos
Profesor: Máster Carlos Carranza Blanco
II Ciclo del 20 25**

```
Proyecto.
```

**Objetivos**

Aplicar de manera práctica los conocimientos adquiridos sobre el diseño y
administración de las bases de datos, mediante la confección de modelos relacionales
y base de datos, de un sistema de administración de centros de salud.

Aplicar de manera práctica los conocimientos adquiridos sobre el diseño y
administración de las bases de datos, mediante la confección de soluciones reales para
administrar funcionalidad, seguridad y el manejo de notificaciones.

Aplicar de manera práctica los conocimientos adquiridos sobre la administración de
base de datos, mediante la implementación de un servidor de respaldo para una base
de datos.

**Descripción del proyecto**

El proyecto se dividirá en dos entregables los cuales se explicará a continuación:

# I Parte – Diseño Relacional – Entregable

Se debe de desarrollar una base de datos para un sistema de administración de
centros de salud. La base de datos debe de estar normalizada en 3FN como mínimo y
en FNBC como máximo. El motor de base de datos a utilizar será Oracle 19c.

**Servicios que se ofrecen**

La administración de centros de salud se limita a las siguientes funciones:

```
❖ Administración del Personal
o Auto registro de personal médico y administrativo
o Aprobación del auto registro por parte de un administrador
o Al personal aprobado se le genera un usuario del sistema.
o Modificar personal existente
o Creación y asignación de perfiles al personal.
o Registro de bancos y cuentas bancarias para pagos al personal.
```

```
o Registro de tipos de documentos solicitados al personal.
❖ Administración de los Centros de Salud
o Registro de los centros de salud
o Puestos de médicos contratados y turnos de dichas plazas
o Procedimientos médicos realizados en el centro de salud
o Control escalas bases y mensuales de atención de los médicos según
plazas y turnos.
o Control de cobro al centro de salud por servicios brindados
o Control de pago a médicos por trabajos realizados.
❖ Administración de Planillas de Pagos a personal
o Creación de tipos de planillas y asociación de personal
o Mantenimiento de tipos de movimientos a incluir en las planillas
o Generación de planillas de médicos según escalas mensuales
o Generación de planillas administrativas
o Generación de comprobantes de pago y envío por correo
❖ Administración Financiera
o Resumen mensual de ingresos y gastos del proceso de administración
de centros médicos, general y por centro de salud.
```

**Funcionamiento del sistema**

```
✓ Se requiere del personal los siguientes datos.
o Cedula, Nombre, Apellidos, Tipo de persona (Nacional, extranjero),
Estado Civil, Dirección (Casa, Trabajo), Teléfono, Nacionalidad,
Residencia, Email, Sexo, Fecha Nacimiento, estado (Activo, Inactivo),
Tipo Personal (Médico, Administrativo), adjuntar todos los documentos
solicitados según el tipo de personal.
o Si el auto registro es aprobado se debe generar un usuario y asignarle
un perfil que detalle que accesos tiene para cada pantalla del sistema.
En caso de rechazo se debe eliminar la información del auto registro
temporal.
o Se deben poder registrar n cuentas bancarias para cada persona, pero
debe existir una como principal, dicha cuenta se usará para la
generación de un reporte de depósitos bancarios por planillas de pago.
✓ Para la administración de centros de salud se requiere:
o Almacenar la información del centro de salud (nombre, ubicación,
contacto, ...)
```

o Los puestos semanales de médicos contratados y sus respectivos
turnos, donde se debe llevar el control de cuanto se va a cobrar por
cada turno y cuanto se va a pagar al médico, el pago puede ser por
horas o por turno completo.
o Llevar el control de procedimientos médicos realizados, cuanto se
cobra al centro de salud y cuanto se paga al médico, deben ser incluidos
dentro del detalle de la planilla de pago de los médicos y dentro del
resumen financiero.
o Con el control de puestos y turnos se debe generar una escala semanal
base, utilizada para posteriormente crear la escala mensual, donde se
pueda llevar el control de cual médico está asignado en cada turno de
cada puesto contratado por el centro de salud en cada día del mes, y se
pueda controlar si el médico trabajó o no, cual fue el horario real
trabajado y hacer ajustes como cambio de médico, modificación de
turnos y demás.
o La escala mensual debe contar con diferentes estados (Construcción,
Vigente, En Revisión, Lista para Pago y Procesada), solo cuando está en
lista para pago puede ser incluida en planillas de pago, luego de
procesar la planilla se cambia a procesada.
✓ Para la administración de planillas se requiere:
o Definir tipos de planillas para agrupar al personal, y posteriormente
gestionar la generación de dichas planillas y su respectivo pago, todo el
personal debe ser asociado a un tipo de planilla.
o Las planillas deben ser generadas de forma mensual tanto a médicos
como administrativos, tienen un encabezado con información general y
un detalle relacionado a cada persona.
o Las planillas de médicos se generan respecto a lo registrado en la escala
mensual y a los procedimientos médicos realizados en el mes.
o Las planillas administrativas se generan respecto al salario base de la
persona y a los tipos de movimientos de planilla automáticos
registrados para las planillas de administrativos, como por ejemplo
(Caja, renta que contempla rangos salariales, cuota banco popular y
cualquier otra registrada, sea porcentual, absoluta). Las planillas de
médicos podrían tener movimientos automáticos también.
o Luego de generada y aprobada la planilla se deben enviar los
comprobantes de pago a cada persona por correo electrónico en
formato HTML y con todo el detalle del pago, ingresos y deducciones.
o Se debe generar un informe de montos a depositar por cada persona y
su respectiva información de cuenta a depositar.

```
✓ Para la administración financiera se requiere:
o Poder generar un resumen mensual de todos los ingresos (Lo cobrado
por los turnos y procedimientos de médicos) y gastos registrados (Lo
pagado a médicos y administrativos) en el sistema.
o Lo relacionado a médicos se debe poder detallar por centro de salud.
✓ Si en el transcurso de la generación del modelo relacional, se necesitan más
datos, deberán incluirlos. (pude ser que necesiten datos específicos para
relacionar tablas o para que los procesos funcionen de mejor forma), los
requerimientos están redactados a nivel de usuario, pueden solicitar
ampliación o aclaración respectiva.
```

# II Parte – Programación en BD - Entregable

**Funcionalidad a Implementar**

```
✓ Se debe crear un proceso que a partir de la escala base se genere una escala
mensual.
✓ Se debe realizar un proceso que genera las planillas de administradores y
médicos con la información registrada en el sistema.
✓ Se debe realizar el proceso de generación y envío de comprobantes de pago a
los correos electrónicos.
✓ Se requiere que cuando se aplique una planilla automáticamente se marquen
como procesados turnos, escalas y procedimientos involucrados.
✓ Se requiere que cuando se envíen los comprobantes de pago, cada detalle de la
planilla se marque como notificado.
✓ Para agregarle un mayor valor agregado a la aplicación, es necesario cargar el
padrón nacional en la base de datos, se requiere adaptar el modelo y cargar el
padrón con la información actual en la base de datos.
✓ A la empresa le preocupa la integridad de la información, se solicita crear las
bitácoras para las tablas principales de planillas y escalas mensuales.
✓ Las notificaciones serán parametrizadas (Correo, Clave, Correo(s) al cual
notificar)
✓ La clave de correo debe de estar encriptado, para brindarle mayor seguridad al
envió de notificaciones.
✓ El envío de correo debe de realizarse directamente desde Oracle.
```

**Seguridad a Implementar**

```
✓ Se requiere implementar seguridad a nivel de base de datos, con perfiles, roles,
usuarios.
```

```
o Los roles deben de ser como mínimo: Administrador, Médico y
Administrativo.
✓ Los roles es necesario crearle seguridad por medio de clave, esta clave debe de
estar encriptada dentro de la base de datos en alguna tabla de parámetros.
o Al contar con seguridad por password en roles es necesario
implementar procedimientos que asignen la clave a los roles para poder
utilizar los permisos de forma correcta.
```

**Notificaciones a realizar**

```
✓ Realizar un proceso que inactive cuentas de usuarios que tengan más de 3
meses de inactividad en planillas, escalas o procedimiento, este proceso se
ejecutará una vez al mes y se notificara al DBA, cuales cuentas fueron
inactivadas.
✓ Verificar el tamaño de los tablespace, el cual no debe de exceder en un 85% su
tamaño. Este proceso se ejecutará todos los días, notificar en caso de que
exista inconsistencia
✓ Verifica si existen objetos inválidos. Este proceso se ejecutará todos los días,
notificar en caso de que exista inconsistencia
✓ En ocasiones los índices se dañan, verificar y notificar cuando esto sucede. Este
proceso se ejecutará todos los días, notificar en caso de que exista
inconsistencia
```

# III Parte – Respaldos - Entregable

Se debe de implementar una base de datos standby, previendo cualquier
inconveniente con la base de datos principal, así como la administración de la misma.

**Funcionalidad**

```
✓ Deben de ser dos servidores distintos, un servidor como principal y otro como
standby
✓ Deben de existir un archivo de actualización cada 5 minutos o bien cada 50 MB,
sin necesidad de la intervención del DBA.
✓ Se deben de trasladar la información de un servidor al otro cada 10 minutos.
Debe existir la forma de que, al realizar las revisiones, se pueda generar en el
momento que el profesor lo decida.
✓ Se utilizará base de datos Oracle 19c y sistema operativo Linux o Windows
```

```
✓ Eliminar los archivos de información que están en el servidor principal que ya
fueron pasados al standby, así como los archivos de información que ya fueron
aplicados en el servidor standby con un rango de 3 dias.
✓ Es requerido que la base de datos realice automáticamente un respaldo diario
de la base de datos principal, este respaldo también se debe de trasladar al
servidor de la base de datos standby. De igual manera, el proceso se ejecutará a
petición del profesor, al momento de la revisión.
```

**Notas Generales**

```
✓ Se debe de generar un documento con el paso a paso de la implementación
(Manual de instalación) así como la solución dada para solucionar todos los
requerimientos para la standby.
o Este manual debe de contar con una introducción, explicación de
conceptos a utilizar, recomendaciones y conclusiones.
o En caso de que la implementación sea defectuosa o tenga algún
problema, el manual también será castigado, ya que no es un manual
100% funcional.
✓ Se debe de tomar en cuenta que es necesario replicar todas las acciones de la
base de datos principal en la standby. En caso de que exista alguna acción que
genere inconvenientes. Brindar una solución y un manual de cómo actuar ante
tal situación.
✓ Se debe de presentar la implementación funcional.
```

**Grupo de trabajos**

Estarán formados por grupos de 3 personas, en caso de quedar un estudiante sin
grupo el profesor decidirá a que grupo se integra.

**Fecha de entrega**

Se realizará la entrega del proyecto según fecha indicada en el cronograma de curso.

**Notas**

```
➢ La base de datos debe de ser debidamente comentada.
➢ El código del programa debe de estar debidamente comentado.
➢ El día de la entrega se presentará al profesor el esquema relacional y se
procederá a la defensa de este.
➢ Se calificará de forma individual a cada miembro del grupo.
```

**Calificación 2 5 % - Primer Entregable**

**Rubro Valor Descripción Valor
Modelo** 75 % Modelo relacional 75 %
**Documentación** 15 % Diccionario de
Datos

## 10 %

Script BD 5%
**Defensa** 10 % Defensa del
proyecto

## 10 %

**Total** 100% 100%

**Calificación 2 2.5% II Parte – II Entregable**

**Rubro Valor Descripción Valor
Sistema** 87% Modelo relacional 5%
Funcionamiento 82%
**Documentación** 3% Documentación de
código

## 3%

**Defensa** 10% Defensa del
proyecto

## 10%

**Total** 100% 100%

**Escala Funcionamiento**

**Rubro Descripción Valor
Escalas** Se debe crear un proceso que a partir de la
escala base se genere una escala mensual.

## 8 %

**Planillas** Se debe realizar un proceso que genera las
planillas de administradores y médicos con
la información registrada en el sistema.

## 12 %

```
Se debe realizar el proceso de generación y
envío de comprobantes de pago a los
correos electrónicos.
```

## 12 %

```
Se requiere que cuando se aplique una
planilla automáticamente se marquen como
procesados turnos, escalas y
procedimientos involucrados.
```

## 4 %

```
Se requiere que cuando se envíen los
comprobantes de pago, cada detalle de la
planilla se marque como notificado.
```

## 3 %

**Padrón Nacional y
parámetros**

```
Cargar el padrón nacional y parámetros de
la aplicación
```

## 5 %

**Creación de bitácoras** Creación de bitácoras de planillas y escalas 4 %

**Encriptación y
desencriptación de
claves**

```
Procedimientos de encriptación y viceversa. 5 %
```

**Seguridad BD** Roles 3 %
Usuarios 3 %
Perfiles 3 %
**Notificaciones** Realizar un proceso que inactive cuentas de
usuarios que tengan más de 3 meses de
inactividad en planillas, escalas o
procedimiento, este proceso se ejecutará
una vez al mes y se notificara al DBA, cuales
cuentas fueron inactivadas.

## 5 %

```
Verificar el tamaño de los tablespace, el cual
no debe de exceder en un 85% su tamaño.
Este proceso se ejecutará todos los días,
notificar en caso de que exista
inconsistencia
```

## 5 %

```
Verifica si existen objetos invalido 5 %
En ocasiones los índices se dañan, verificar
y notificar cuando esto sucede.
```

## 5 %

**Total** 82 %

**Calificación 1 2.5% III Parte – II Entregable**

**Rubro Valor Descripción Valor
Implementación** 75% Funcionalidad 75%
**Documentación** 15% Manual de instalación y
soluciones brindadas

## 12%

```
Manual de administración
de la Standby
```

## 3%

**Defensa** 10% Defensa del proyecto 10%
**Total** 100% 100%

**Escala Funcionamiento**

**Rubro Descripción Valor
Instalación de Servidor y
base de datos principal**

```
Instalación del servidor principal, previendo
que va a existir una base de datos standby
```

## 18%

**Instalación del Servidor
y base de datos Standby**

```
Instalación de la base de datos Standby. 22 %
```

**Actualización de Standby** Actualización de la base de datos standby 15%

cada 5 minutos o 50 megas
**Eliminación de archivos
obsoletos.**

```
Eliminar archivos con una antigüedad de 3
días
```

## 9 %

**Respaldos** Realizar respaldos diarios 7 %
**Traslado de respaldos** Trasladar el respaldo a otro servidor. 4 %
**Total** 75 %

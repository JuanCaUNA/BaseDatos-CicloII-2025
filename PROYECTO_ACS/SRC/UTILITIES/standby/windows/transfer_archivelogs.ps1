|III Parte – Respaldos - Entregable #2
Se debe de implementar una base de datos standby, previendo cualquier
inconveniente con la base de datos principal, así como la administración de la misma.
Funcionalidad
✓ Deben de ser dos servidores distintos, un servidor como principal y otro como
standby
✓ Deben de existir un archivo de actualización cada 5 minutos o bien cada 50 MB,
sin necesidad de la intervención del DBA.
✓ Se deben de trasladar la información de un servidor al otro cada 10 minutos.
Debe existir la forma de que, al realizar las revisiones, se pueda generar en el
momento que el profesor lo decida.
✓ Se utilizará base de datos Oracle 19c y sistema operativo Linux o Windows

✓ Eliminar los archivos de información que están en el servidor principal que ya
fueron pasados al standby, así como los archivos de información que ya fueron
aplicados en el servidor standby con un rango de 3 dias.
✓ Es requerido que la base de datos realice automáticamente un respaldo diario
de la base de datos principal, este respaldo también se debe de trasladar al
servidor de la base de datos standby. De igual manera, el proceso se ejecutará a
petición del profesor, al momento de la revisión.
Notas Generales
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
✓ Se debe de presentar la implementación funcional.<# Transfer archivelogs to standby using WinSCP or scp (OpenSSH) #>

$sendDir = 'C:\standby\send'
$standbyUser = 'oracle'
$standbyHost = 'standby.example.com'
$standbyPath = '/home/oracle/standby/receive'
$sshKey = 'C:\Users\oracle\.ssh\id_rsa'

If (!(Test-Path $sendDir)) { New-Item -ItemType Directory -Path $sendDir | Out-Null }

# Using scp (OpenSSH) - requires scp available in PATH
Get-ChildItem -Path $sendDir -File | ForEach-Object {
  $file = $_.FullName
  & scp -i $sshKey -o StrictHostKeyChecking=no $file "$($standbyUser)@$($standbyHost):$standbyPath/"
  if ($LASTEXITCODE -eq 0) { Remove-Item $file -Force }
}

Exit 0

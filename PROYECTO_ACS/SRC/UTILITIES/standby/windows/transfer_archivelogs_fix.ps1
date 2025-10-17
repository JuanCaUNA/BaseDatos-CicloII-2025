<#
Transfer archivelogs to standby using scp (OpenSSH) - archivo de reemplazo limpio.
Configura las variables al inicio: $sendDir, $standbyHost, $standbyUser y $sshKey.
#>

# --- Configuración (editar según entorno) ---
$sendDir = 'C:\standby\send'
$standbyUser = 'oracle'
$standbyHost = '127.0.0.1'   # IP o hostname del standby (si usas docker y mapeas puertos, usar la IP del host/contener)
$standbyPath = '/home/oracle/standby/receive'
$sshKey = 'C:\Users\oracle\.ssh\id_rsa'

If (!(Test-Path $sendDir)) { New-Item -ItemType Directory -Path $sendDir | Out-Null }

Write-Host "Buscando archivos en: $sendDir"
Get-ChildItem -Path $sendDir -File | ForEach-Object {
    $file = $_.FullName
    Write-Host "Transfiriendo: $file -> $standbyUser@$standbyHost:$standbyPath"

    # Preparar comando SCP
    $scpArgs = @('-i', $sshKey, '-o', 'StrictHostKeyChecking=no', $file, "$($standbyUser)@$($standbyHost):$standbyPath/")
    $proc = Start-Process -FilePath 'scp' -ArgumentList $scpArgs -NoNewWindow -Wait -PassThru

    if ($proc.ExitCode -eq 0) {
        Write-Host "Transferencia correcta: $file"
        Remove-Item $file -Force
    } else {
        Write-Warning "Fallo al transferir $file (exit $($proc.ExitCode)). Se mantiene para reintento."
    }
}

Write-Host "Transferencias finalizadas."
Exit 0

<#
Despliega los scripts SQL en orden por módulos.

REQUIERE: tener sqlplus (o SQLcl) en PATH.

Uso (ejemplo):
.\deploy_all.ps1 -User scott -Password tiger -ConnectString "localhost/ORCLPDB"
#>

param(
    [string]$User,
    [string]$Password,
    [string]$ConnectString
)

if (-not $User -or -not $Password -or -not $ConnectString) {
    Write-Host "Por favor provee User, Password y ConnectString. Ej: .\deploy_all.ps1 -User scott -Password tiger -ConnectString 'localhost/ORCLPDB'"
    exit 1
}

$base = Join-Path $PSScriptRoot "..\Proyecto-1\src"

# Orden explícito
$order = @(
    "tablespaces",
    "common",
    "planillas_financiero",
    "medicos",
    "personal",
    "utilities"
)

foreach ($mod in $order) {
    $dir = Join-Path $base $mod
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -Filter *.sql | Sort-Object Name | ForEach-Object {
            $file = $_.FullName
            Write-Host "Ejecutando $file"
            & sqlplus "$User/$Password@$ConnectString" "@$file" | Out-Null
        }
    }
}

Write-Host "Despliegue finalizado."

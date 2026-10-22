param(
    [ValidateRange(1024,65535)][int]$Puerto = 51843,
    [switch]$SoloCompilar,
    [switch]$Configurar,
    [string]$Servidor = '(localdb)\MSSQLLocalDB'
)
$ErrorActionPreference = 'Stop'
if ($SoloCompilar -and $Configurar) { throw 'Use -SoloCompilar o -Configurar, no ambos.' }
$proyectoTecnova = Join-Path $PSScriptRoot 'Tecnova.HelpDesk\Tecnova.HelpDesk.csproj'
$vswhereTecnova = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (!(Test-Path -LiteralPath $vswhereTecnova)) { throw 'Instale Visual Studio con Desarrollo de ASP.NET y web y .NET Framework 4.8.' }
$msbuildTecnova = & $vswhereTecnova -latest -products '*' -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
if (!$msbuildTecnova) { throw 'No se encontro MSBuild.' }
& $msbuildTecnova $proyectoTecnova /restore /t:Build /p:Configuration=Debug /p:RestoreLockedMode=true /verbosity:minimal /nologo
if ($LASTEXITCODE -ne 0) { throw 'No se pudo restaurar o compilar.' }
if ($SoloCompilar) { return }
if ($Configurar) {
    Add-Type -AssemblyName System.Data
    $cadenaTecnova = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $cadenaTecnova['Data Source'] = $Servidor
    $cadenaTecnova['Initial Catalog'] = 'master'
    $cadenaTecnova['Integrated Security'] = $true
    $conexionTecnova = New-Object System.Data.SqlClient.SqlConnection $cadenaTecnova.ConnectionString
    try {
        $conexionTecnova.Open()
        $scriptTecnova = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Database/CrearBaseDatos.sql') -Raw
        foreach ($loteTecnova in [regex]::Split($scriptTecnova, '(?im)^\s*GO\s*$')) {
            if (!$loteTecnova.Trim()) { continue }
            $comandoTecnova = $conexionTecnova.CreateCommand()
            try {
                $comandoTecnova.CommandText = $loteTecnova
                $comandoTecnova.CommandTimeout = 60
                [void]$comandoTecnova.ExecuteNonQuery()
            } finally { $comandoTecnova.Dispose() }
        }
        Write-Host 'Base preparada. Las cuentas existentes se conservaron; una base vacia recibe las cuentas de demostracion.'
    } finally { $conexionTecnova.Dispose() }
    Write-Host 'Configuracion completada. Ejecute .\INICIAR.ps1 para abrir el servidor.'
    return
}
$iisTecnova = Join-Path $env:ProgramFiles 'IIS Express\iisexpress.exe'
if (!(Test-Path -LiteralPath $iisTecnova)) { throw 'No se encontro IIS Express.' }
if (Get-NetTCPConnection -State Listen -LocalPort $Puerto -ErrorAction SilentlyContinue) {
    throw "El puerto $Puerto ya esta ocupado. Elija otro con -Puerto."
}
Write-Host "Abra http://localhost:$Puerto/ . Ctrl+C detiene el servidor."
& $iisTecnova "/path:$(Join-Path $PSScriptRoot 'Tecnova.HelpDesk')" "/port:$Puerto" /systray:false
if ($LASTEXITCODE -ne 0) { throw 'IIS Express termino con un error.' }

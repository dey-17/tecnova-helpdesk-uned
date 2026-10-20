param([ValidateRange(1024,65535)][int]$Puerto = 51843, [switch]$SoloCompilar)
$ErrorActionPreference = 'Stop'
$proyectoTecnova = Join-Path $PSScriptRoot 'Tecnova.HelpDesk\Tecnova.HelpDesk.csproj'
$vswhereTecnova = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (!(Test-Path -LiteralPath $vswhereTecnova)) { throw 'Instale Visual Studio con Desarrollo de ASP.NET y web y .NET Framework 4.8.' }
$msbuildTecnova = & $vswhereTecnova -latest -products '*' -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
if (!$msbuildTecnova) { throw 'No se encontro MSBuild.' }
& $msbuildTecnova $proyectoTecnova /restore /t:Build /p:Configuration=Debug /p:RestoreLockedMode=true /verbosity:minimal /nologo
if ($LASTEXITCODE -ne 0) { throw 'No se pudo restaurar o compilar.' }
if ($SoloCompilar) { return }
$iisTecnova = Join-Path $env:ProgramFiles 'IIS Express\iisexpress.exe'
if (!(Test-Path -LiteralPath $iisTecnova)) { throw 'No se encontro IIS Express.' }
if (Get-NetTCPConnection -State Listen -LocalPort $Puerto -ErrorAction SilentlyContinue) {
    throw "El puerto $Puerto ya esta ocupado. Elija otro con -Puerto."
}
Write-Host "Abra http://localhost:$Puerto/ . Ctrl+C detiene el servidor."
& $iisTecnova "/path:$(Join-Path $PSScriptRoot 'Tecnova.HelpDesk')" "/port:$Puerto" /systray:false
if ($LASTEXITCODE -ne 0) { throw 'IIS Express termino con un error.' }

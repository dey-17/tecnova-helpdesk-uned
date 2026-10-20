param([string]$BaseUrl = 'http://localhost:51843')
$ErrorActionPreference = 'Stop'
$inicioTecnova = Invoke-WebRequest -Uri "$BaseUrl/" -UseBasicParsing
if ($inicioTecnova.StatusCode -ne 200) { throw 'La pagina inicial no responde correctamente.' }
foreach ($marcaTecnova in @('TECNOVA','panel-inicio','panel-servicio','aria-live="polite"','shell.js','site.css')) {
    if (!$inicioTecnova.Content.Contains($marcaTecnova)) { throw "No se encontro: $marcaTecnova" }
}
$cssTecnova = Invoke-WebRequest -Uri "$BaseUrl/Content/site.css" -UseBasicParsing
$jsTecnova = Invoke-WebRequest -Uri "$BaseUrl/Scripts/shell.js" -UseBasicParsing
if ($cssTecnova.StatusCode -ne 200 -or $jsTecnova.StatusCode -ne 200) { throw 'Faltan recursos de interfaz.' }
if ($jsTecnova.Content -match '\b(alert|confirm|prompt)\s*\(') { throw 'Se detecto un dialogo nativo.' }
Write-Host 'PASS: inicio MVC, paneles, avisos y recursos disponibles.'

param([string]$Servidor='(localdb)\MSSQLLocalDB')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Data
$cadenaTecnova = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$cadenaTecnova['Data Source']=$Servidor
$cadenaTecnova['Initial Catalog']='master'
$cadenaTecnova['Integrated Security']=$true
$cadenaTecnova['Connect Timeout']=30
$conexionTecnova=New-Object System.Data.SqlClient.SqlConnection $cadenaTecnova.ConnectionString
try {
    $conexionTecnova.Open()
    foreach($archivoTecnova in @('001_CrearBase.sql','003_PersonalSoporte.sql','002_Verificar.sql')) {
    $scriptTecnova=Get-Content (Join-Path $PSScriptRoot $archivoTecnova) -Raw
    foreach($loteTecnova in [regex]::Split($scriptTecnova,'(?im)^\s*GO\s*$')) {
        if(!$loteTecnova.Trim()){continue}
        $comandoTecnova=$conexionTecnova.CreateCommand()
        $comandoTecnova.CommandText=$loteTecnova
        $comandoTecnova.CommandTimeout=60
        [void]$comandoTecnova.ExecuteNonQuery()
        $comandoTecnova.Dispose()
    }
    }
    Write-Host 'Base TecnovaHelpDesk disponible. No se eliminaron datos existentes.'
} finally { $conexionTecnova.Dispose() }

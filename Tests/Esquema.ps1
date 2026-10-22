param([string]$Servidor='(localdb)\MSSQLLocalDB')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Data
$basePrueba='TecnovaPrueba_'+[Guid]::NewGuid().ToString('N')
$cadenaPrueba=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$cadenaPrueba['Data Source']=$Servidor
$cadenaPrueba['Initial Catalog']='master'
$cadenaPrueba['Integrated Security']=$true
$conexionPrueba=New-Object System.Data.SqlClient.SqlConnection $cadenaPrueba.ConnectionString
function ConsultaPrueba([string]$Sql) {
    $cmdPrueba=$conexionPrueba.CreateCommand()
    try {$cmdPrueba.CommandText=$Sql; $cmdPrueba.CommandTimeout=60; return $cmdPrueba.ExecuteScalar()}
    finally {$cmdPrueba.Dispose()}
}
function InstalaPrueba {
    $sqlPrueba=(Get-Content (Join-Path $PSScriptRoot '../Database/CrearBaseDatos.sql') -Raw).Replace('TecnovaHelpDesk',$basePrueba)
    foreach($lotePrueba in [regex]::Split($sqlPrueba,'(?im)^\s*GO\s*$')) {
        if($lotePrueba.Trim()){[void](ConsultaPrueba $lotePrueba)}
    }
}
try {
    $conexionPrueba.Open()
    InstalaPrueba
    if((ConsultaPrueba 'SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(''dbo'')') -ne 6){throw 'Cantidad incorrecta de tablas.'}
    if((ConsultaPrueba 'SELECT COUNT(*) FROM sys.foreign_keys') -ne 8){throw 'Cantidad incorrecta de relaciones.'}
    if((ConsultaPrueba 'SELECT COUNT(*) FROM Usuarios') -ne 2){throw 'Faltan cuentas de demostracion.'}
    if((ConsultaPrueba "SELECT COUNT(*) FROM Usuarios WHERE Rol='Administrador' AND Email='admin.demo@tecnova.local' AND PasswordHash LIKE 'v1`$600000`$%'") -ne 1){throw 'Administrador de demostracion invalido.'}
    if((ConsultaPrueba "SELECT COUNT(*) FROM Usuarios WHERE Rol='Usuario' AND Email='empleado.demo@tecnova.local' AND PasswordHash LIKE 'v1`$600000`$%'") -ne 1){throw 'Empleado de demostracion invalido.'}
    if((ConsultaPrueba 'SELECT COUNT(*) FROM Tecnicos') -ne 1){throw 'Falta tecnico de demostracion.'}
    [void](ConsultaPrueba "UPDATE Usuarios SET Nombre='Nombre conservado',PasswordHash='Hash conservado',Estado=0 WHERE Rol='Usuario'; INSERT Tickets(Titulo,Descripcion,Categoria,IdUsuarioSolicitante) SELECT 'Ticket conservado','Descripcion de prueba','Otro',Id FROM Usuarios WHERE Rol='Administrador';")
    InstalaPrueba
    if((ConsultaPrueba 'SELECT COUNT(*) FROM Usuarios') -ne 2){throw 'La repeticion duplico cuentas.'}
    if((ConsultaPrueba "SELECT COUNT(*) FROM Usuarios WHERE Nombre='Nombre conservado' AND PasswordHash='Hash conservado' AND Estado=0") -ne 1){throw 'La repeticion altero un usuario.'}
    if((ConsultaPrueba 'SELECT COUNT(*) FROM Tickets') -ne 1){throw 'La repeticion altero tickets.'}
    if((ConsultaPrueba 'SELECT COUNT(*) FROM Tecnicos') -ne 1){throw 'La repeticion duplico tecnicos.'}
    Write-Host 'PASS: instalacion limpia, seis tablas, ocho relaciones, cuentas demo y repeticion sin alterar datos.'
} finally {
    if($conexionPrueba.State -eq 'Open') {
        $conexionPrueba.ChangeDatabase('master')
        if($basePrueba -notmatch '^TecnovaPrueba_[a-f0-9]{32}$'){throw 'Nombre temporal no valido; no se elimina.'}
        [void](ConsultaPrueba "IF DB_ID('$basePrueba') IS NOT NULL BEGIN ALTER DATABASE [$basePrueba] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$basePrueba]; END")
    }
    $conexionPrueba.Dispose()
}

param([string]$BaseUrl='http://localhost:51843')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'Ejecute estas pruebas con PowerShell 7 (pwsh).'}
Add-Type -Path (Join-Path $PSScriptRoot '../Tecnova.HelpDesk/bin/Tecnova.HelpDesk.dll')
$sufijoTecnova=[Guid]::NewGuid().ToString('N')
$passwordTecnova='Prueba-'+[Guid]::NewGuid().ToString('N')
$hashTecnova=[Tecnova.HelpDesk.Security.Passwords]::Hash($passwordTecnova)
$conexionTecnova=New-Object System.Data.SqlClient.SqlConnection 'Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=TecnovaHelpDesk;Integrated Security=True'
$conexionTecnova.Open()
function SqlPrueba($sql,$params=@{}){
    $cmd=$conexionTecnova.CreateCommand();$cmd.CommandText=$sql
    foreach($k in $params.Keys){[void]$cmd.Parameters.AddWithValue($k,$params[$k])}
    try{return $cmd.ExecuteScalar()}finally{$cmd.Dispose()}
}
function Sesion($email){
    $s=New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $page=Invoke-WebRequest "$BaseUrl/Cuenta/Login" -WebSession $s
    $token=[regex]::Match($page.Content,'name="__RequestVerificationToken"[^>]*value="([^"]+)"').Groups[1].Value
    $response=Invoke-WebRequest "$BaseUrl/Cuenta/Entrar" -Method Post -WebSession $s -Headers @{'X-Requested-With'='XMLHttpRequest'} -Body @{email=$email;password=$passwordTecnova;__RequestVerificationToken=$token} -SkipHttpErrorCheck
    if($response.StatusCode -ne 200){throw "Login falló: $($response.Content)"}
    $page=Invoke-WebRequest "$BaseUrl/Inicio/Panel" -WebSession $s
    $token=[regex]::Match($page.Content,'name="__RequestVerificationToken"[^>]*value="([^"]+)"').Groups[1].Value
    if(!$token){throw 'Panel sin token'}
    return @{session=$s;token=$token}
}
function Api($s,$path,$data=$null,$status=200){
    $args=@{Uri="$BaseUrl/$path";WebSession=$s.session;Headers=@{'X-Requested-With'='XMLHttpRequest'};SkipHttpErrorCheck=$true}
    if($null -ne $data){$args.Method='Post';$data.__RequestVerificationToken=$s.token;$args.Body=$data}
    $r=Invoke-WebRequest @args
    if([int]$r.StatusCode -ne $status){throw "$path esperaba $status y recibió $($r.StatusCode): $($r.Content)"}
    return ($r.Content|ConvertFrom-Json)
}
$idsTecnova=New-Object 'System.Collections.Generic.List[int]'
try{
    foreach($rolTecnova in @('Administrador','Usuario','Usuario')){
        $emailTecnova="test-$($idsTecnova.Count)-$sufijoTecnova@example.invalid"
        $idTecnova=SqlPrueba "INSERT Usuarios(Nombre,Email,PasswordHash,Rol) OUTPUT INSERTED.Id VALUES(@n,@e,@p,@r)" @{'@n'='Prueba automatizada';'@e'=$emailTecnova;'@p'=$hashTecnova;'@r'=$rolTecnova}
        $idsTecnova.Add([int]$idTecnova)
    }
    $adminTecnova=Sesion "test-0-$sufijoTecnova@example.invalid"
    $empleadoTecnova=Sesion "test-1-$sufijoTecnova@example.invalid"
    $otroTecnova=Sesion "test-2-$sufijoTecnova@example.invalid"
    $r=Api $adminTecnova 'Empleados/Listar'
    $nuevo=Api $empleadoTecnova 'Tickets/Crear' @{Titulo='Incidencia de prueba';Descripcion='Descripcion de prueba';Categoria='Hardware'}
    $ticketIdTecnova=$nuevo.id
    $detalle=(Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
    [void](Api $otroTecnova "Tickets/Detalle?id=$ticketIdTecnova" $null 404)
    [void](Api $empleadoTecnova 'Tickets/Editar' @{id=$ticketIdTecnova;version=$detalle.Version;Titulo='Incidencia editada';Descripcion='Descripcion corregida';Categoria='Software'})
    [void](Api $empleadoTecnova 'Tickets/Editar' @{id=$ticketIdTecnova;version=$detalle.Version;Titulo='Antiguo';Descripcion='No debe guardar';Categoria='Software'} 409)
    [void](Api $empleadoTecnova 'Tickets/Crear' @{Titulo=' ';Descripcion='Prueba';Categoria='Hardware'} 400)
    [void](Api $otroTecnova "Comentarios/Listar?id=$ticketIdTecnova" $null 404)
    [void](Api $otroTecnova 'Comentarios/Agregar' @{id=$ticketIdTecnova;texto='No autorizado'} 409)
    [void](Api $empleadoTecnova 'Comentarios/Agregar' @{id=$ticketIdTecnova;texto='Comentario del solicitante'})
    [void](Api $adminTecnova 'Comentarios/Agregar' @{id=$ticketIdTecnova;texto='Respuesta de soporte'})
    $comentarios=Api $empleadoTecnova "Comentarios/Listar?id=$ticketIdTecnova"
    if($comentarios.datos.Count -ne 2){throw 'Comentarios no persistidos'}
    Write-Host 'PASS: comentarios persistentes y acceso restringido.'
    $detalle=(Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
    [void](Api $empleadoTecnova 'Tickets/Eliminar' @{id=$ticketIdTecnova;version=$detalle.Version})
    [void](Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova" $null 404)
    Write-Host 'PASS: CRUD de tickets, validaciones, propiedad y version concurrente.'
    [void](Api $empleadoTecnova 'Empleados/Listar' $null 403)
    $u=$r.datos|Where-Object Id -eq $idsTecnova[2]
    [void](Api $adminTecnova 'Empleados/Estado' @{id=$u.Id;activo='false';version=$u.Version})
    [void](Api $otroTecnova 'Empleados/Listar' $null 401)
    Write-Host 'PASS: login, permisos de administrador y revocacion de cuenta inactiva.'
}finally{
    foreach($idTecnova in $idsTecnova){[void](SqlPrueba 'DELETE Comentarios WHERE IdTicket IN (SELECT Id FROM Tickets WHERE IdUsuarioSolicitante=@id); DELETE Tickets WHERE IdUsuarioSolicitante=@id; DELETE Usuarios WHERE Id=@id' @{'@id'=$idTecnova})}
    $conexionTecnova.Dispose()
}

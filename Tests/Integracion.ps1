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
    $botonCrear=[regex]::Match($page.Content,'<button[^>]*data-section="crear"[^>]*>').Value
    $esAdmin=$email.StartsWith('test-0-')
    if($esAdmin -ne $botonCrear.Contains('hidden=')){throw 'Visibilidad incorrecta del menu Crear ticket'}

    foreach($marca in @('data-section="crear"','Historial de solicitudes','Configuración','id="historial-listado"','Volver al historial')){
        if(!$page.Content.Contains($marca)){throw "Panel sin navegación esperada: $marca"}
    }
    if([regex]::Matches($page.Content,'id="ticket-form"').Count -ne 1){throw 'Formulario de ticket duplicado'}
    if($page.Content.Contains('id="actualizar-tickets"')){throw 'El historial no debe incluir actualización manual'}
    return @{session=$s;token=$token}
}
function Api($s,$path,$data=$null,$status=200){
    $args=@{Uri="$BaseUrl/$path";WebSession=$s.session;Headers=@{'X-Requested-With'='XMLHttpRequest'};SkipHttpErrorCheck=$true}
    if($null -ne $data){$args.Method='Post';$data.__RequestVerificationToken=$s.token;$args.Body=$data}
    $r=Invoke-WebRequest @args
    if([int]$r.StatusCode -ne $status){throw "$path esperaba $status y recibió $($r.StatusCode): $($r.Content)"}
    return ($r.Content|ConvertFrom-Json)
}
$idTecnicoPrueba=0
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
    $correoNuevoTecnova="test-alta-$sufijoTecnova@example.invalid"
    [void](Api $adminTecnova 'Empleados/Guardar' @{nombre='Empleado de prueba';email=$correoNuevoTecnova;password=$passwordTecnova})
    $idNuevoTecnova=SqlPrueba 'SELECT Id FROM Usuarios WHERE Email=@e' @{'@e'=$correoNuevoTecnova}
    $idsTecnova.Add([int]$idNuevoTecnova)
    [void](Api $adminTecnova 'Empleados/Guardar' @{nombre='Duplicado';email=$correoNuevoTecnova;password=$passwordTecnova} 409)
    $nuevoEmpleadoTecnova=(Api $adminTecnova 'Empleados/Listar').datos|Where-Object Id -eq $idNuevoTecnova
    [void](Api $adminTecnova 'Empleados/Guardar' @{id=$idNuevoTecnova;version=$nuevoEmpleadoTecnova.Version;nombre='Nombre actualizado';email=$correoNuevoTecnova;password=''})
    [void](Api $empleadoTecnova 'Empleados/Guardar' @{nombre='No permitido';email='no@example.invalid';password=$passwordTecnova} 403)
    $sinTokenTecnova=Invoke-WebRequest "$BaseUrl/Tickets/Crear" -Method Post -WebSession $empleadoTecnova.session -Headers @{'X-Requested-With'='XMLHttpRequest'} -Body @{Titulo='Sin token';Descripcion='Rechazar';Categoria='Hardware'} -SkipHttpErrorCheck
    if([int]$sinTokenTecnova.StatusCode -ne 400){throw 'Fallo proteccion antifalsificacion'}
    Write-Host 'PASS: alta/edicion de empleados, duplicados y antifalsificacion.'
    $nuevo=Api $empleadoTecnova 'Tickets/Crear' @{Titulo='Incidencia de prueba';Descripcion='Descripcion de prueba';Categoria='Hardware'}
    $ticketIdTecnova=$nuevo.id
    $detalle=(Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
    [void](Api $otroTecnova "Tickets/Detalle?id=$ticketIdTecnova" $null 404)
    $empleadoTecnova=Sesion "test-1-$sufijoTecnova@example.invalid"
    if((Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos.Id -ne $ticketIdTecnova){throw 'Fallo persistencia entre sesiones'}
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
    [void](Api $empleadoTecnova 'Soporte/Estado' @{id=$ticketIdTecnova;estado=2;version=$detalle.Version} 403)
    [void](Api $adminTecnova 'Soporte/Estado' @{id=$ticketIdTecnova;estado=2;version=$detalle.Version} 409)
    [void](Api $adminTecnova 'Soporte/Asignar' @{id=$ticketIdTecnova;responsable=$idsTecnova[0];version=$detalle.Version})

    $correoTecnico="tecnico-$sufijoTecnova@example.invalid"
    [void](Api $empleadoTecnova 'Tecnicos/Listar' $null 403)
    [void](Api $adminTecnova 'Tecnicos/Guardar' @{nombre='Tecnico original';email=$correoTecnico})
    $tecnico=(Api $adminTecnova 'Tecnicos/Listar').datos|Where-Object Email -eq $correoTecnico
    $idTecnicoPrueba=$tecnico.Id
    [void](Api $adminTecnova 'Tecnicos/Guardar' @{nombre='Duplicado';email=$correoTecnico} 409)
    if((SqlPrueba 'SELECT COUNT(*) FROM Usuarios WHERE Email=@e' @{'@e'=$correoTecnico}) -ne 0){throw 'Tecnico no debe tener cuenta'}
    $detalle=(Api $adminTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
    [void](Api $adminTecnova 'Soporte/Asignar' @{id=$ticketIdTecnova;responsable=$idTecnicoPrueba;tipo='tecnico';version=$detalle.Version})
    [void](Api $adminTecnova 'Tecnicos/Estado' @{id=$idTecnicoPrueba;activo='false';version=$tecnico.Version} 409)
    [void](Api $otroTecnova "Tickets/Historial?id=$ticketIdTecnova" $null 404)
    $detalle=(Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
    [void](Api $empleadoTecnova 'Tickets/Editar' @{id=$ticketIdTecnova;version=$detalle.Version;Titulo='No permitido';Descripcion='Asignado';Categoria='Hardware'} 409)
    foreach($estadoTecnova in @(2,3,4)){
        $detalle=(Api $adminTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
        [void](Api $adminTecnova 'Soporte/Estado' @{id=$ticketIdTecnova;estado=$estadoTecnova;version=$detalle.Version;solucion='Se corrigio la configuracion y se verifico el funcionamiento.'})
        if($estadoTecnova -eq 3){
            $d=(Api $adminTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
            $c=(Api $adminTecnova "Comentarios/Listar?id=$ticketIdTecnova").datos|Where-Object Propio|Select-Object -Last 1
            [void](Api $adminTecnova 'Comentarios/Agregar' @{id=$ticketIdTecnova;texto='No permitido en resuelto'} 409)
            [void](Api $empleadoTecnova 'Comentarios/Editar' @{id=$ticketIdTecnova;comentario=$c.Id;version=$d.Version;texto='Ajeno'} 409)
            [void](Api $adminTecnova 'Comentarios/Editar' @{id=$ticketIdTecnova;comentario=$c.Id;version=$d.Version;texto='Solucion corregida y verificada correctamente.'})
            [void](Api $adminTecnova 'Comentarios/Editar' @{id=$ticketIdTecnova;comentario=$c.Id;version=$d.Version;texto='Version antigua'} 409)
        }
        if($estadoTecnova -eq 4){
            $d=(Api $adminTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
            [void](Api $adminTecnova 'Comentarios/Editar' @{id=$ticketIdTecnova;comentario=$c.Id;version=$d.Version;texto='Cerrado'} 409)
            Write-Host 'PASS: comentarios propios editables, resueltos sin altas y cierre de solo lectura.'
        }
    }

    [void](Api $adminTecnova 'Tecnicos/Guardar' @{id=$idTecnicoPrueba;version=$tecnico.Version;nombre='Tecnico renombrado';email=$correoTecnico})
    $historial=(Api $empleadoTecnova "Tickets/Historial?id=$ticketIdTecnova").datos
    if(($historial|Where-Object Accion -eq 'Ticket resuelto').Responsable -ne 'Tecnico original'){throw 'El historial perdió el nombre original'}
    if($historial.Count -ne 5){throw 'Historial incompleto'}
    $tecnico=(Api $adminTecnova 'Tecnicos/Listar').datos|Where-Object Id -eq $idTecnicoPrueba
    [void](Api $adminTecnova 'Tecnicos/Estado' @{id=$idTecnicoPrueba;activo='false';version=$tecnico.Version})
    Write-Host 'PASS: tecnicos sin cuenta, asignacion, baja y trazabilidad inmutable.'
    [void](Api $empleadoTecnova 'Comentarios/Agregar' @{id=$ticketIdTecnova;texto='Cerrado'} 409)
    $resultadoBusqueda=Api $adminTecnova "Tickets/Listar?q=$ticketIdTecnova&estado=4"
    if($ticketIdTecnova -notin $resultadoBusqueda.datos.Id){throw 'Busqueda no encontro el ticket cerrado'}
    Write-Host 'PASS: asignacion, secuencia de estados, cierre y busqueda.'
    $hoyTecnova=[DateTime]::UtcNow.ToString('yyyy-MM-dd')
    [void](Api $empleadoTecnova "Reportes/Resumen?desde=$hoyTecnova&hasta=$hoyTecnova" $null 403)
    $reporteTecnova=Api $adminTecnova "Reportes/Resumen?desde=$hoyTecnova&hasta=$hoyTecnova&estado=4"
    if($reporteTecnova.resumen.Total -lt 1 -or $reporteTecnova.resumen.Resueltos -lt 1){throw 'Reporte no incluye ticket resuelto'}
    [void](Api $adminTecnova 'Reportes/Resumen?desde=2026-10-30&hasta=2026-10-01' $null 400)
    Write-Host 'PASS: reportes, fechas y permisos.'
    $nuevo=Api $empleadoTecnova 'Tickets/Crear' @{Titulo='Eliminar prueba';Descripcion='Ticket temporal para eliminar';Categoria='Hardware'}
    $ticketIdTecnova=$nuevo.id
    $detalle=(Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova").datos
    [void](Api $adminTecnova 'Soporte/Asignar' @{id=$ticketIdTecnova;responsable=$idTecnicoPrueba;tipo='tecnico';version=$detalle.Version} 409)
    [void](Api $empleadoTecnova 'Tickets/Eliminar' @{id=$ticketIdTecnova;version=$detalle.Version})
    [void](Api $empleadoTecnova "Tickets/Detalle?id=$ticketIdTecnova" $null 404)
    Write-Host 'PASS: CRUD de tickets, validaciones, propiedad y version concurrente.'
    [void](Api $empleadoTecnova 'Empleados/Listar' $null 403)
    $u=$r.datos|Where-Object Id -eq $idsTecnova[2]
    [void](Api $adminTecnova 'Empleados/Estado' @{id=$u.Id;activo='false';version=$u.Version})
    [void](Api $otroTecnova 'Empleados/Listar' $null 401)
    Write-Host 'PASS: login, permisos de administrador y revocacion de cuenta inactiva.'
}finally{
    foreach($idTecnova in $idsTecnova){[void](SqlPrueba 'DELETE HistorialAtencion WHERE IdTicket IN (SELECT Id FROM Tickets WHERE IdUsuarioSolicitante=@id); DELETE Comentarios WHERE IdTicket IN (SELECT Id FROM Tickets WHERE IdUsuarioSolicitante=@id); DELETE Tickets WHERE IdUsuarioSolicitante=@id;' @{'@id'=$idTecnova})}
    foreach($idTecnova in $idsTecnova){[void](SqlPrueba 'DELETE Usuarios WHERE Id=@id' @{'@id'=$idTecnova})}
    if($idTecnicoPrueba){[void](SqlPrueba 'DELETE Tecnicos WHERE Id=@id' @{'@id'=$idTecnicoPrueba})}
    $conexionTecnova.Dispose()
}

# Tecnova Help Desk

 Proyecto 1 Sistema interno de soporte con ASP.NET MVC 5.3.0, .NET Framework 4.8, SQL Server y JavaScript/Ajax mediante Fetch. 

## Requisitos

- Windows, Visual Studio 2022 o herramientas de compilación con Desarrollo de ASP.NET y web, .NET Framework 4.8 e IIS Express.
- SQL Server 2022 Express LocalDB (predeterminado), o una instancia SQL Server compatible. 
- PowerShell; las pruebas automatizadas requieren PowerShell 7 (`pwsh`).
- Acceso a NuGet en la primera restauración. Dependencias fijadas en `packages.lock.json`.


## Instalación desde una descarga limpia

La carpeta `Database` contiene un solo archivo: **CrearBaseDatos.sql**, con todas las tablas, relaciones, índices, estados iniciales y comprobaciones. No hace falta ejecutar otros archivos SQL.

Desde la carpeta que contiene la solución, después de instalar LocalDB desde Microsoft, preparar la aplicación:

```powershell
& 'C:\Program Files\Microsoft SQL Server\160\Tools\Binn\SqlLocalDB.exe' start MSSQLLocalDB
.\INICIAR.ps1 -Configurar
.\INICIAR.ps1
```

`-Configurar` compila el proyecto y ejecuta el unico SQL. En una base sin usuarios se crean un administrador y un empleado de demostracion, ademas de un tecnico sin acceso al sistema. .

Abrir **http://localhost:51843/Cuenta/Login**. Ctrl+C detiene IIS Express si se inició desde la terminal. Para reiniciar: `./INICIAR.ps1`. Para otro puerto: `./INICIAR.ps1 -Puerto 51844`.


Para SQL Server completo: `INICIAR.ps1 -Configurar -Servidor 'SERVIDOR\INSTANCIA'` y ajustar `connectionStrings/Tecnova` en Web.config a esa instancia. Se recomienda autenticación integrada de Windows. 

## Roles y funcionamiento

El menú separa **Crear ticket** (formulario) e **Historial de solicitudes** (lista con filtros por estado y acceso al detalle). Al guardar se abre el historial; al editar se abre el formulario con los datos del ticket. **Volver al historial** regresa a la lista sin recargar la página. **Configuración** permite cambiar la contraseña. Para el administrador, **Agregar empleados** conserva las operaciones de alta, edición y activación de cuentas.

- **Administrador:** crea, edita, activa y desactiva empleados; ve todos los tickets; asigna responsables; cambia estados; consulta reportes y descarga conteos en CSV.
- **Usuario:** crea tickets, consulta únicamente los propios y agrega comentarios a sus tickets no cerrados. No hay registro público.
- Desactivar conserva registros, pero bloquea el login y las solicitudes con cookies previas. Reactivar no revive sesiones antiguas.
- La asignación es a un técnico activo o al propio administrador. No se introduce un tercer rol de técnico ni se permite que un empleado consulte tickets ajenos por una asignación.
- Estados: **Abierto → En Proceso → Resuelto → Cerrado**. Requieren responsable activo. Resolver exige describir la solución (10–2000 caracteres), guardada como comentario. Resolver y cerrar son acciones separadas; no hay reapertura.
- El administrador puede editar/eliminar tickets abiertos; el solicitante puede hacerlo mientras no estén asignados. Los otros estados conservan el historial. Eliminar un ticket abierto retira sus comentarios, con confirmación personalizada.
- Título 1–150, descripción 1–3000, categoría Hardware/Software/Red/Accesos/Otro y comentarios 1–2000. No se aceptan solo espacios ni etiquetas HTML.
- CRUD, comentarios, asignación, estados, búsqueda y reportes usan Ajax. Login/logout cambian de página. Listado limitado a 200 coincidencias; filtrar por número, título o estado. No hay paginación.
- Fechas guardadas en UTC; tickets mostrados en la zona del navegador. Reportes por fecha UTC de creación, incluyendo ambos días. El promedio es tiempo transcurrido hasta resolución, no horas activas de trabajo ni SLA.

## Seguridad y concurrencia

PBKDF2-HMAC-SHA256 con salt aleatorio y 600.000 iteraciones. Cookies HttpOnly/SameSite=Lax, vencimiento de 30 minutos sin renovación deslizante. Cinco fallos bloquean la cuenta 15 minutos. Autorización por rol/propiedad en servidor, tokens antifalsificación en POST, SQL parametrizado, salida textual segura y rowversion para rechazar versiones antiguas. Cambiar/restablecer contraseña invalida cookies previas.


## Pruebas

Con IIS Express iniciado:

```powershell
pwsh -File .\Tests\Esquema.ps1
pwsh -File .\Tests\Integracion.ps1
.\Tests\Inicio.ps1
```

Esquema crea una base temporal con nombre unico, verifica las seis tablas, ocho relaciones y datos de demostracion, repite la instalacion para comprobar que conserva los cambios y elimina unicamente esa base temporal. No modifica TecnovaHelpDesk.

Integracion crea cuentas temporales y tickets, comprueba autenticación, roles, baja, CRUD, propiedad, concurrencia, comentarios, estados, búsqueda y reportes; elimina solamente sus registros al terminar. Usa LocalDB y la base predeterminada: adaptar su conexión si se cambia Web.config. Es normal que aumenten los identificadores tras las pruebas. No sustituye una auditoría de seguridad/carga ni revisión visual.

## Organización

- `Models/TicketInput.cs`: modelo de entrada y validación.
- `Controllers`: solicitudes MVC y reglas.
- `Data/Db.cs`: acceso ADO.NET parametrizado.
- `Security`: hashes y verificación de cuenta/rol por solicitud.
- `Views`: vistas y parciales Razor.
- `Scripts`: Ajax y actualización textual del DOM.
- `Database/CrearBaseDatos.sql`: creación y verificación de todo el esquema.
- `INICIAR.ps1`: compilación, configuración inicial y arranque de IIS Express.

Limitaciones: sin adjuntos, correo, recuperación automática de contraseña, auditoría de cambios generales fuera de la atención, notificaciones en tiempo real ni alta de administradores desde la interfaz. El administrador restablece contraseñas de empleados; una base vacia recibe las cuentas de demostracion. La persistencia no depende de mantener la sesión ni el navegador abiertos.
### Personal de soporte y atención

El administrador registra técnicos (nombre y correo) desde **Personal de soporte**. No son cuentas de acceso ni un tercer rol. Puede asignar un técnico activo o asignarse a sí mismo. Asignar no inicia la atención: se utiliza después **Iniciar atención**, luego se registra la solución y finalmente se cierra el ticket.

El historial conserva el nombre del responsable y del administrador que registró cada asignación o cambio de estado. No se reconstruyen acciones anteriores a esta actualización. Para dar de baja a un técnico con tickets abiertos o en proceso, primero hay que reasignarlos. Los registros resueltos y cerrados se conservan.

El único SQL incluye personal de soporte e historial y puede repetirse sin eliminar datos del esquema existente. Se mantiene `IdUsuarioAsignado` para la autoasignación del administrador y `IdTecnicoAsignado` para técnicos; no pueden coexistir ambos responsables en un ticket.

El administrador inicia en el historial y no muestra la opción Crear ticket en su menú. En tickets resueltos no se agregan comentarios nuevos: cada autor puede corregir sus propios comentarios antes del cierre. Los tickets cerrados son de solo lectura. La edición valida la versión del ticket para evitar sobrescribir cambios concurrentes.


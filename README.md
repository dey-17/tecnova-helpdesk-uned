# Tecnova Help Desk

Sistema interno de soporte con ASP.NET MVC 5.3.0, .NET Framework 4.8, SQL Server y JavaScript/Ajax mediante Fetch. Interfaz gris y negra con acentos rojos, menú izquierdo y mensajes/confirmaciones propios. Sin servicios externos de fuentes o imágenes.

## Requisitos

- Windows, Visual Studio 2022 o herramientas de compilación con Desarrollo de ASP.NET y web, .NET Framework 4.8 e IIS Express.
- SQL Server 2022 Express LocalDB (predeterminado), o una instancia SQL Server compatible. LocalDB tiene persistencia real, no guarda los tickets en Session.
- PowerShell; las pruebas automatizadas requieren PowerShell 7 (`pwsh`).
- Acceso a NuGet en la primera restauración. Dependencias fijadas en `packages.lock.json`.

VS Code puede utilizarse como editor y terminal. No se ejecuta con Live Server ni `dotnet run`.

## Instalación desde una descarga limpia

Desde la carpeta que contiene la solución, después de instalar LocalDB desde Microsoft:

```powershell
& 'C:\Program Files\Microsoft SQL Server\160\Tools\Binn\SqlLocalDB.exe' start MSSQLLocalDB
.\Database\Instalar.ps1
.\INICIAR.ps1 -SoloCompilar
.\Database\CrearAdministrador.ps1 -Nombre 'Administrador' -Email 'admin@empresa.local'
.\INICIAR.ps1
```

El script de administrador pide una contraseña sin mostrarla; exige 12–128 caracteres y no modifica un administrador existente. No hay contraseña predeterminada. Después del primer acceso se puede cambiar desde **Configuración**.

Abrir **http://localhost:51843/Cuenta/Login**. Ctrl+C detiene IIS Express si se inició desde la terminal. Para reiniciar: `./INICIAR.ps1`. Para otro puerto: `./INICIAR.ps1 -Puerto 51844`.

`Database/001_CrearBase.sql` también puede ejecutarse en SQL Server Management Studio. Crea `TecnovaHelpDesk` y Usuarios, Tickets, Comentarios y EstadosTicket con claves primarias/foráneas, restricciones e índices. No elimina ni reinicializa datos existentes. No es un migrador de cualquier esquema previo: usar una base nueva con ese nombre o el esquema de este proyecto. Ejecuta después `003_PersonalSoporte.sql` para incorporar técnicos e historial. `002_Verificar.sql` comprueba estados y relaciones del esquema actualizado.

Para SQL Server completo: `Database/Instalar.ps1 -Servidor 'SERVIDOR\INSTANCIA'` y ajustar `connectionStrings/Tecnova` en Web.config. Se recomienda autenticación integrada de Windows. No publicar credenciales de SQL en Git. El proceso de IIS debe tener acceso a la base; LocalDB se usa desde IIS Express bajo el usuario que la creó. No se incluyen MDF/LDF ni copias de seguridad.

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

HTTP es exclusivo de pruebas locales. Publicar requiere HTTPS/cookies Secure, secretos protegidos, permisos mínimos SQL, respaldos, auditoría y controles adicionales de acceso/limitación de solicitudes. No ingresar datos sensibles. No se garantiza idempotencia de reintentos de red: ante una respuesta incierta, consultar antes de repetir una creación.

## Pruebas

Con IIS Express iniciado:

```powershell
pwsh -File .\Tests\Integracion.ps1
.\Tests\Inicio.ps1
```

Integracion crea cuentas temporales y tickets, comprueba autenticación, roles, baja, CRUD, propiedad, concurrencia, comentarios, estados, búsqueda y reportes; elimina solamente sus registros al terminar. Usa LocalDB y la base predeterminada: adaptar su conexión si se cambia Web.config. Es normal que aumenten los identificadores tras las pruebas. No sustituye una auditoría de seguridad/carga ni revisión visual.

## Organización

- `Models/TicketInput.cs`: modelo de entrada y validación.
- `Controllers`: solicitudes MVC y reglas.
- `Data/Db.cs`: acceso ADO.NET parametrizado.
- `Security`: hashes y verificación de cuenta/rol por solicitud.
- `Views`: vistas y parciales Razor.
- `Scripts`: Ajax y actualización textual del DOM.
- `Database`: creación/verificación de esquema y administrador inicial.

Limitaciones: sin adjuntos, correo, recuperación automática de contraseña, auditoría de cambios generales fuera de la atención, notificaciones en tiempo real ni alta de administradores desde la interfaz. El administrador restablece contraseñas de empleados; el primero se configura localmente. La persistencia no depende de mantener la sesión ni el navegador abiertos.
### Personal de soporte y atención

El administrador registra técnicos (nombre y correo) desde **Personal de soporte**. No son cuentas de acceso ni un tercer rol. Puede asignar un técnico activo o asignarse a sí mismo. Asignar no inicia la atención: se utiliza después **Iniciar atención**, luego se registra la solución y finalmente se cierra el ticket.

El historial conserva el nombre del responsable y del administrador que registró cada asignación o cambio de estado. No se reconstruyen acciones anteriores a esta actualización. Para dar de baja a un técnico con tickets abiertos o en proceso, primero hay que reasignarlos. Los registros resueltos y cerrados se conservan.

Ejecuta `Database/Instalar.ps1` para instalar o actualizar una base existente: aplica también `003_PersonalSoporte.sql`, de forma idempotente y sin eliminar datos. Se mantiene `IdUsuarioAsignado` para la autoasignación del administrador y se añade `IdTecnicoAsignado`; no pueden coexistir ambos responsables en un ticket.

El administrador inicia en el historial y no muestra la opción Crear ticket en su menú. En tickets resueltos no se agregan comentarios nuevos: cada autor puede corregir sus propios comentarios antes del cierre. Los tickets cerrados son de solo lectura. La edición valida la versión del ticket para evitar sobrescribir cambios concurrentes.


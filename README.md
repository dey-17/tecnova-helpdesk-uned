# Tecnova Help Desk

 Proyecto 1 Sistema interno de soporte con ASP.NET MVC 5.3.0, .NET Framework 4.8, SQL Server y JavaScript/Ajax mediante Fetch. 
 
## Requisitos

- Windows, Visual Studio 2022 o herramientas de compilación con Desarrollo de ASP.NET y web, .NET Framework 4.8 e IIS Express.
- SQL Server 2022 Express LocalDB (predeterminado), o una instancia SQL Server compatible. 
- PowerShell; las pruebas automatizadas requieren PowerShell 7 (`pwsh`).
- Acceso a NuGet en la primera restauración. Dependencias fijadas en `packages.lock.json`.
- Los usuarios y contraseñas se entregan en el trabajo escrito exactamente en la pagina 05.


## Instalación desde una descarga limpia

La carpeta `Database` contiene un solo archivo: **CrearBaseDatos.sql**, con todas las tablas, relaciones, índices, estados iniciales y comprobaciones. No hace falta ejecutar otros archivos SQL.

### 1. Descargar y abrir el proyecto

En GitHub seleccionar **Code → Download ZIP** y descomprimir el archivo. En VS Code seleccionar **Archivo → Abrir carpeta** y abrir la carpeta que contiene `INICIAR.ps1`, `Tecnova.HelpDesk.sln` y `README.md`, no la carpeta superior ni el ZIP. Abrir **Terminal → Nueva terminal** con PowerShell.

El ZIP contiene el código y el script de la base, **no instala SQL Server, Visual Studio ni las herramientas de compilación**. Comprobar primero los requisitos anteriores. La extensión de C# de VS Code no sustituye esas herramientas.

### 2. Iniciar LocalDB

Si se utiliza SQL Server 2022 Express LocalDB, ejecutar:

```powershell
& 'C:\Program Files\Microsoft SQL Server\160\Tools\Binn\SqlLocalDB.exe' start MSSQLLocalDB
```

La ruta corresponde a LocalDB 2022. Si no existe, comprobar la instalación y su ruta; no significa que falte el archivo SQL del proyecto. Para otra instancia SQL Server, consultar la alternativa indicada más abajo.

### 3. Preparar la aplicación y la base

Desde la carpeta del proyecto, ejecutar y esperar a que termine sin errores:

```powershell
.\INICIAR.ps1 -Configurar
```

Este paso restaura las dependencias desde NuGet, compila y ejecuta `Database/CrearBaseDatos.sql`. Si falla, resolver el error antes de continuar con el inicio.

### 4. Iniciar el servidor y acceder

```powershell
.\INICIAR.ps1
```

`-Configurar` compila el proyecto y ejecuta el unico SQL. En una base sin usuarios se crean un administrador y un empleado de demostracion, ademas de un tecnico sin acceso al sistema. .

Abrir **http://localhost:51843/Cuenta/Login**. Ctrl+C detiene IIS Express si se inició desde la terminal. Para reiniciar: `./INICIAR.ps1`. Para otro puerto: `./INICIAR.ps1 -Puerto 51844`.

Mantener la terminal abierta mientras se utiliza el sistema. Ingresar con los accesos de demostración entregados por separado si se preparó una base sin usuarios. El administrador puede registrar empleados desde **Agregar empleados**. Los nuevos usuarios y tickets se guardan en la instancia SQL configurada, no en GitHub.

Descargar el código en otra carpeta o cambiar el puerto **no crea una base independiente**: si la cadena de conexión apunta a la misma instancia y a `TecnovaHelpDesk`, las copias utilizan los mismos datos y cuentas existentes.


Para SQL Server completo: `INICIAR.ps1 -Configurar -Servidor 'SERVIDOR\INSTANCIA'` y ajustar `connectionStrings/Tecnova` en Web.config a esa instancia. Se recomienda autenticación integrada de Windows. 

## Solución de problemas de instalación

### No se puede cargar el índice de servicio de NuGet

Si el mensaje menciona `https://api.nuget.org/v3/index.json`, la restauración no pudo acceder al origen de dependencias. No es un error de SQL Server ni demuestra que falte una extensión de VS Code. Comprobar el acceso a esa dirección desde el navegador y la conexión a Internet. Si el acceso está bloqueado por la red, revisar con su administrador la configuración de proxy o firewall; no desactivar las protecciones del equipo.

Cuando la conexión funcione, repetir `./INICIAR.ps1 -Configurar`. Si persiste, conservar el mensaje completo: que la URL abra en el navegador no garantiza que NuGet utilice la misma configuración de red.

### El puerto 51843 ya está ocupado

Puede haber otra ejecución del sistema u otro servicio utilizando ese puerto. Detener la ejecución anterior con **Ctrl+C en su propia terminal**, si se identifica, o iniciar esta copia en otro puerto libre:

```powershell
.\INICIAR.ps1 -Puerto 51844
```

En ese caso abrir **http://localhost:51844/Cuenta/Login**. No terminar procesos desconocidos. Cambiar el puerto no cambia ni repara la base de datos.

### Cannot create file porque TecnovaHelpDesk.mdf ya existe

El archivo físico existe, pero la instancia puede no tener registrada la base con ese nombre. También puede pertenecer a otra instancia. **No borrar ni sobrescribir archivos MDF o LDF**: podrían contener datos anteriores.

En SQL Server Management Studio, conectarse a la misma instancia configurada por la aplicación y revisar **Bases de datos**. Identificar a qué base e instancia pertenecen los archivos. Si corresponde recuperar una base desconectada, conservar primero una copia válida de sus archivos y realizar la operación de adjuntar con asistencia de quien administra SQL Server. No intentar adjuntar archivos que otra instancia esté utilizando. El script no elimina ni reconecta automáticamente archivos existentes.

### No se puede conectar a LocalDB o abrir TecnovaHelpDesk

Comprobar que LocalDB esté instalado, que `MSSQLLocalDB` pueda iniciarse y que `INICIAR.ps1 -Configurar` haya terminado correctamente. Ejecutar IIS Express con el mismo usuario de Windows que preparó LocalDB. Para SQL Server completo, comprobar que el servidor usado al configurar coincida con `connectionStrings/Tecnova` en `Tecnova.HelpDesk/Web.config` y que ese usuario tenga acceso a la base.

### No se encuentra MSBuild, IIS Express o .NET Framework

Completar los componentes indicados en **Requisitos** desde el instalador de Visual Studio. VS Code es el editor, no el compilador ni el servidor. No sustituir este proyecto por Live Server o `dotnet run`. Después comprobar la compilación con `./INICIAR.ps1 -SoloCompilar`.

### Las cuentas de demostración no permiten ingresar

Las cuentas se insertan solo cuando `Usuarios` está vacía. Si se reutiliza una base que ya tiene usuarios, utilizar sus credenciales actuales: ejecutar el SQL de nuevo no cambia contraseñas ni agrega las cuentas demo. Si se necesita probar desde cero, preparar un entorno separado; no borrar la base existente sin respaldo.

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


# Tecnova Help Desk

Aplicación de soporte técnico con ASP.NET MVC 5.3.0 y .NET Framework 4.8.

## Funcionalidad disponible

Base MVC compilable, página de inicio, menú lateral izquierdo, navegación local de paneles sin recarga y avisos personalizados accesibles. Diseño adaptable en gris y negro con acentos rojos.

Todavía no permite iniciar sesión ni guardar tickets. La persistencia SQL Server, los roles y las operaciones de soporte se incorporarán en cambios posteriores. La interfaz indica explícitamente lo que no está disponible; no muestra datos simulados como resultados reales.

## Requisitos

- Windows y Visual Studio 2022 con Desarrollo de ASP.NET y web.
- Paquete de destino de .NET Framework 4.8 e IIS Express.
- Acceso a NuGet para la restauración inicial.

## Ejecutar

Abrir `Tecnova.HelpDesk.sln` en Visual Studio y compilar. También puede utilizarse PowerShell:

```powershell
.\INICIAR.ps1
```

Abrir http://localhost:51843/. Ctrl+C detiene el servidor. Para compilar sin iniciar:

```powershell
.\INICIAR.ps1 -SoloCompilar
```

Para utilizar otro puerto:

```powershell
.\INICIAR.ps1 -Puerto 51844
```

Este es un proyecto clásico de .NET Framework; no se inicia con Live Server ni `dotnet run`.

## Estructura

- `Tecnova.HelpDesk/Controllers`: controladores MVC.
- `Tecnova.HelpDesk/Views`: interfaz Razor.
- `Tecnova.HelpDesk/Content`: estilos locales.
- `Tecnova.HelpDesk/Scripts`: interacción del navegador.
- `Tests`: comprobaciones HTTP de la base disponible.

Los scripts de SQL Server se incorporarán con el almacenamiento relacional. No hay credenciales ni datos reales en el repositorio.

## Comprobar la página inicial

Con el servidor iniciado:

```powershell
.\Tests\Inicio.ps1
```

La configuración HTTP es para ejecución local, no para publicación de datos confidenciales en Internet.

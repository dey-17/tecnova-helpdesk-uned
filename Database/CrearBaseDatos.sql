-- Tecnova Help Desk: esquema completo para SQL Server.
-- Ejecutar todo el archivo. Conserva los datos del esquema de Tecnova existente.
-- Incluye cuentas de demostracion SOLO si Usuarios esta vacia.
-- No usar estas cuentas preconfiguradas en produccion ni exponer el servicio a Internet.

IF DB_ID(N'TecnovaHelpDesk') IS NULL
    CREATE DATABASE TecnovaHelpDesk;
GO
USE TecnovaHelpDesk;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Usuarios (
        Id int IDENTITY PRIMARY KEY,
        Nombre nvarchar(100) NOT NULL,
        Email nvarchar(254) NOT NULL UNIQUE,
        PasswordHash varchar(300) NOT NULL,
        Rol varchar(20) NOT NULL CHECK (Rol IN ('Usuario','Administrador')),
        FechaRegistro datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        Estado bit NOT NULL DEFAULT 1,
        SecurityStamp uniqueidentifier NOT NULL DEFAULT NEWID(),
        IntentosFallidos int NOT NULL DEFAULT 0,
        BloqueadoHasta datetime2 NULL,
        Version rowversion NOT NULL
    );
    CREATE TABLE dbo.EstadosTicket (
        Id int PRIMARY KEY,
        Nombre nvarchar(30) NOT NULL UNIQUE
    );
    INSERT dbo.EstadosTicket VALUES (1,N'Abierto'),(2,N'En Proceso'),(3,N'Resuelto'),(4,N'Cerrado');
    CREATE TABLE dbo.Tickets (
        Id int IDENTITY PRIMARY KEY,
        Titulo nvarchar(150) NOT NULL,
        Descripcion nvarchar(3000) NOT NULL,
        Categoria nvarchar(50) NOT NULL,
        IdUsuarioSolicitante int NOT NULL REFERENCES dbo.Usuarios(Id),
        IdUsuarioAsignado int NULL REFERENCES dbo.Usuarios(Id),
        IdEstado int NOT NULL DEFAULT 1 REFERENCES dbo.EstadosTicket(Id),
        FechaCreacion datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        FechaActualizacion datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        FechaResolucion datetime2 NULL,
        FechaCierre datetime2 NULL,
        Version rowversion NOT NULL,
        CHECK (LEN(LTRIM(RTRIM(Titulo)))>0),
        CHECK (LEN(LTRIM(RTRIM(Descripcion)))>0),
        CHECK (Categoria IN (N'Hardware',N'Software',N'Red',N'Accesos',N'Otro'))
    );
    CREATE TABLE dbo.Comentarios (
        Id int IDENTITY PRIMARY KEY,
        IdTicket int NOT NULL REFERENCES dbo.Tickets(Id),
        IdUsuario int NOT NULL REFERENCES dbo.Usuarios(Id),
        Texto nvarchar(2000) NOT NULL CHECK (LEN(LTRIM(RTRIM(Texto)))>0),
        Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_Tickets_Solicitante ON dbo.Tickets(IdUsuarioSolicitante,FechaCreacion);
    CREATE INDEX IX_Tickets_EstadoFecha ON dbo.Tickets(IdEstado,FechaCreacion);
    CREATE INDEX IX_Comentarios_Ticket ON dbo.Comentarios(IdTicket,Fecha);
END;
COMMIT;
GO

USE TecnovaHelpDesk;
GO
SET XACT_ABORT ON;
BEGIN TRAN;
IF OBJECT_ID('dbo.Tecnicos') IS NULL
CREATE TABLE dbo.Tecnicos (
 Id int IDENTITY PRIMARY KEY, Nombre nvarchar(100) NOT NULL,
 Email nvarchar(254) NOT NULL UNIQUE, Estado bit NOT NULL DEFAULT 1,
 FechaRegistro datetime2 NOT NULL DEFAULT SYSUTCDATETIME(), Version rowversion,
 CONSTRAINT CK_Tecnicos_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre)))>=2)
);
IF COL_LENGTH('dbo.Tickets','IdTecnicoAsignado') IS NULL
BEGIN
 ALTER TABLE dbo.Tickets ADD IdTecnicoAsignado int NULL REFERENCES dbo.Tecnicos(Id);
END;
COMMIT;
GO
SET XACT_ABORT ON;
BEGIN TRAN;
IF OBJECT_ID('dbo.CK_Tickets_ResponsableUnico') IS NULL
 ALTER TABLE dbo.Tickets ADD CONSTRAINT CK_Tickets_ResponsableUnico CHECK (IdUsuarioAsignado IS NULL OR IdTecnicoAsignado IS NULL);
IF OBJECT_ID('dbo.HistorialAtencion') IS NULL
BEGIN
 CREATE TABLE dbo.HistorialAtencion (
  Id int IDENTITY PRIMARY KEY, IdTicket int NOT NULL REFERENCES dbo.Tickets(Id),
  IdAdministrador int NOT NULL REFERENCES dbo.Usuarios(Id),
  Administrador nvarchar(100) NOT NULL, Responsable nvarchar(100) NOT NULL,
  Accion nvarchar(40) NOT NULL, Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
 );
 CREATE INDEX IX_HistorialAtencion_Ticket ON dbo.HistorialAtencion(IdTicket,Id);
END;
COMMIT;
GO

USE TecnovaHelpDesk;
GO
IF (SELECT COUNT(*) FROM dbo.EstadosTicket WHERE Id IN (1,2,3,4)) <> 4
    THROW 51000, 'Faltan estados iniciales', 1;
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id IN (OBJECT_ID('dbo.Tickets'),OBJECT_ID('dbo.Comentarios'))) <> 6
    THROW 51000, 'Faltan relaciones', 1;
IF OBJECT_ID('dbo.Tecnicos') IS NULL OR OBJECT_ID('dbo.HistorialAtencion') IS NULL
    THROW 51000, 'Falta personal de soporte o historial de atencion', 1;
IF COL_LENGTH('dbo.Tickets','IdTecnicoAsignado') IS NULL
    THROW 51000, 'Falta la asignacion de tecnico', 1;

IF (SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID('dbo') AND name IN
    ('Usuarios','Tickets','Comentarios','EstadosTicket','Tecnicos','HistorialAtencion')) <> 6
    THROW 51000, 'Faltan tablas del esquema Tecnova', 1;
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('dbo.HistorialAtencion')) <> 2
    THROW 51000, 'Faltan relaciones del historial', 1;
SET XACT_ABORT ON;
BEGIN TRAN;
IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WITH (UPDLOCK,HOLDLOCK))
BEGIN
    INSERT dbo.Usuarios (Nombre,Email,PasswordHash,Rol) VALUES
    (N'Administrador de demostracion','admin.demo@tecnova.local','v1$600000$S9ui+p9XI+7s9Agu0CLu4w==$eVSgOu9vpXIlR0mZwfaJuowX8cFrxvwwO9bDwzdHkv4=','Administrador'),
    (N'Empleado de demostracion','empleado.demo@tecnova.local','v1$600000$jNytKoBahnBF+mLbEMEpiw==$aI55U1rWK5hQdN2Fw5ecmwBTGxVM3pc4qeY4QTTkWcI=','Usuario');
    IF NOT EXISTS (SELECT 1 FROM dbo.Tecnicos WHERE Email='tecnico.demo@tecnova.local')
        INSERT dbo.Tecnicos(Nombre,Email) VALUES (N'Tecnico de demostracion','tecnico.demo@tecnova.local');
END;
COMMIT;
SELECT 'Base TecnovaHelpDesk preparada: seis tablas y relaciones disponibles.' AS Resultado;
GO


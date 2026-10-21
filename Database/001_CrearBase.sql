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

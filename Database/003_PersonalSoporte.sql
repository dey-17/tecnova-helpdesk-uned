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

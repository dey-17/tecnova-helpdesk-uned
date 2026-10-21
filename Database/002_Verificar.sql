USE TecnovaHelpDesk;
GO
IF (SELECT COUNT(*) FROM dbo.EstadosTicket WHERE Id IN (1,2,3,4)) <> 4
    THROW 51000, 'Faltan estados iniciales', 1;
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id IN (OBJECT_ID('dbo.Tickets'),OBJECT_ID('dbo.Comentarios'))) <> 6
    THROW 51000, 'Faltan relaciones', 1;
SELECT 'PASS: tablas, estados y relaciones' AS Resultado;
IF OBJECT_ID('dbo.Tecnicos') IS NULL OR OBJECT_ID('dbo.HistorialAtencion') IS NULL
    THROW 51000, 'Falta personal de soporte o historial de atencion', 1;
IF COL_LENGTH('dbo.Tickets','IdTecnicoAsignado') IS NULL
    THROW 51000, 'Falta la asignacion de tecnico', 1;

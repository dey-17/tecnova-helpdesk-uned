using System;
using System.Web.Mvc;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;
namespace Tecnova.HelpDesk.Controllers
{
    [Access(Admin=true)]
    public class SoporteController : ApiController
    {
        private const string Audit=@"INSERT HistorialAtencion(IdTicket,IdAdministrador,Administrador,Responsable,Accion)
SELECT t.Id,@uid,u.Nombre,COALESCE(k.Nombre,a.Nombre),@accion
FROM Tickets t JOIN Usuarios u ON u.Id=@uid
LEFT JOIN Usuarios a ON a.Id=t.IdUsuarioAsignado
LEFT JOIN Tecnicos k ON k.Id=t.IdTecnicoAsignado WHERE t.Id=@id;";
        [HttpGet] public ActionResult Responsables()
        {return Json(new {ok=true,datos=Db.Rows(Db.Query(@"SELECT Id,Nombre,'tecnico' Tipo FROM Tecnicos WHERE Estado=1
UNION ALL SELECT Id,Nombre,'usuario' Tipo FROM Usuarios WHERE Id=@uid AND Rol='Administrador' AND Estado=1",Db.P("@uid",Actual.Id)))},JsonRequestBehavior.AllowGet);}
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Asignar(int id,int responsable,string version,string tipo="usuario")
        {
            if(tipo!="usuario"&&tipo!="tecnico")return Fail("Tipo de responsable inválido.");
            if(tipo=="usuario"&&responsable!=Actual.Id)return Fail("Solo puedes asignarte a ti mismo o seleccionar un técnico.",403);
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            var result=Db.Query(@"SET XACT_ABORT ON; BEGIN TRAN;
UPDATE Tickets SET IdUsuarioAsignado=CASE WHEN @tipo='usuario' THEN @r END,
IdTecnicoAsignado=CASE WHEN @tipo='tecnico' THEN @r END,FechaActualizacion=SYSUTCDATETIME()
WHERE Id=@id AND Version=@v AND IdEstado IN (1,2) AND
((@tipo='usuario' AND EXISTS(SELECT 1 FROM Usuarios WITH (HOLDLOCK) WHERE Id=@r AND Rol='Administrador' AND Estado=1))
OR (@tipo='tecnico' AND EXISTS(SELECT 1 FROM Tecnicos WITH (HOLDLOCK) WHERE Id=@r AND Estado=1)));
IF @@ROWCOUNT=0 BEGIN ROLLBACK; SELECT 0 Ok; RETURN; END;
"+Audit+@" COMMIT; SELECT 1 Ok;",Db.P("@id",id),Db.P("@v",v),Db.P("@r",responsable),Db.P("@tipo",tipo),Db.P("@uid",Actual.Id),Db.P("@accion","Responsable asignado"));
            if((int)result.Rows[0]["Ok"]==0)return Fail("No se asignó: verifica el estado, la versión y el responsable activo.",409);
            return Json(new {ok=true,mensaje="Responsable asignado. Inicia la atención cuando comience el trabajo."});
        }
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Estado(int id,int estado,string version,string solucion)
        {
            if(estado<2||estado>4)return Fail("Estado inválido.");
            solucion=(solucion??"").Trim();if(estado==3&&(solucion.Length<10||solucion.Length>2000))return Fail("Describe la solución con entre 10 y 2000 caracteres.");
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            var result=Db.Query(@"SET XACT_ABORT ON; BEGIN TRAN;
UPDATE Tickets SET IdEstado=@estado,FechaActualizacion=SYSUTCDATETIME(),FechaResolucion=CASE WHEN @estado=3 THEN SYSUTCDATETIME() ELSE FechaResolucion END,FechaCierre=CASE WHEN @estado=4 THEN SYSUTCDATETIME() ELSE FechaCierre END
WHERE Id=@id AND Version=@v AND IdEstado=@estado-1 AND
(@estado=4 OR EXISTS(SELECT 1 FROM Usuarios WITH (HOLDLOCK) WHERE Id=Tickets.IdUsuarioAsignado AND Rol='Administrador' AND Estado=1)
OR EXISTS(SELECT 1 FROM Tecnicos WITH (HOLDLOCK) WHERE Id=Tickets.IdTecnicoAsignado AND Estado=1));
IF @@ROWCOUNT=0 BEGIN ROLLBACK; SELECT 0 Ok; RETURN; END;
IF @estado=3 INSERT Comentarios(IdTicket,IdUsuario,Texto) VALUES(@id,@uid,@solucion);
"+Audit+@" COMMIT; SELECT 1 Ok;",Db.P("@id",id),Db.P("@v",v),Db.P("@estado",estado),Db.P("@uid",Actual.Id),Db.P("@solucion",solucion),Db.P("@accion",estado==2?"Atención iniciada":estado==3?"Ticket resuelto":"Ticket cerrado"));
            if((int)result.Rows[0]["Ok"]==0)return Fail("No cambió el estado. Asigna un responsable activo y respeta el orden de atención.",409);
            return Json(new {ok=true,mensaje="Estado actualizado."});
        }
    }
}

using System;
using System.Web.Mvc;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;
namespace Tecnova.HelpDesk.Controllers
{
    [Access(Admin=true)]
    public class SoporteController : ApiController
    {
        [HttpGet] public ActionResult Responsables()
        {return Json(new {ok=true,datos=Db.Rows(Db.Query("SELECT Id,Nombre FROM Usuarios WHERE Rol='Administrador' AND Estado=1 ORDER BY Nombre"))},JsonRequestBehavior.AllowGet);}
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Asignar(int id,int responsable,string version)
        {
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            int changed=Db.Execute("UPDATE Tickets SET IdUsuarioAsignado=@r,FechaActualizacion=SYSUTCDATETIME() WHERE Id=@id AND Version=@v AND IdEstado IN (1,2) AND EXISTS(SELECT 1 FROM Usuarios WHERE Id=@r AND Rol='Administrador' AND Estado=1)",Db.P("@id",id),Db.P("@v",v),Db.P("@r",responsable));
            if(changed==0)return Fail("No se asignó: verifica el estado, la versión y el responsable activo.",409);
            return Json(new {ok=true,mensaje="Responsable asignado."});
        }
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Estado(int id,int estado,string version,string solucion)
        {
            if(estado<2||estado>4)return Fail("Estado inválido.");
            solucion=(solucion??"").Trim();if(estado==3&&(solucion.Length<10||solucion.Length>2000))return Fail("Describe la solución con entre 10 y 2000 caracteres.");
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            var result=Db.Query(@"SET XACT_ABORT ON; BEGIN TRAN;
UPDATE Tickets SET IdEstado=@estado,FechaActualizacion=SYSUTCDATETIME(),FechaResolucion=CASE WHEN @estado=3 THEN SYSUTCDATETIME() ELSE FechaResolucion END,FechaCierre=CASE WHEN @estado=4 THEN SYSUTCDATETIME() ELSE FechaCierre END
WHERE Id=@id AND Version=@v AND IdEstado=@estado-1 AND EXISTS(SELECT 1 FROM Usuarios WHERE Id=Tickets.IdUsuarioAsignado AND Rol='Administrador' AND Estado=1);
IF @@ROWCOUNT=0 BEGIN ROLLBACK; SELECT 0 Ok; RETURN; END;
IF @estado=3 INSERT Comentarios(IdTicket,IdUsuario,Texto) VALUES(@id,@uid,@solucion);
COMMIT; SELECT 1 Ok;",Db.P("@id",id),Db.P("@v",v),Db.P("@estado",estado),Db.P("@uid",Actual.Id),Db.P("@solucion",solucion));
            if((int)result.Rows[0]["Ok"]==0)return Fail("No cambió el estado. Asigna un responsable, respeta el orden de atención y actualiza el detalle.",409);
            return Json(new {ok=true,mensaje="Estado actualizado."});
        }
    }
}

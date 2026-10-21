using System;
using System.Web.Mvc;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;
namespace Tecnova.HelpDesk.Controllers
{
    [Access]
    public class ComentariosController : ApiController
    {
        [HttpGet] public ActionResult Listar(int id)
        {
            if(Db.Query("SELECT Id FROM Tickets WHERE Id=@id AND (@admin=1 OR IdUsuarioSolicitante=@uid)",Db.P("@id",id),Db.P("@admin",Actual.Admin),Db.P("@uid",Actual.Id)).Rows.Count==0)return Fail("Ticket no disponible.",404);
            var rows=Db.Query("SELECT c.Id,c.Texto,c.Fecha,u.Nombre Autor FROM Comentarios c JOIN Usuarios u ON u.Id=c.IdUsuario WHERE c.IdTicket=@id ORDER BY c.Id",Db.P("@id",id));
            return Json(new {ok=true,datos=Db.Rows(rows)},JsonRequestBehavior.AllowGet);
        }
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Agregar(int id,string texto)
        {
            texto=(texto??"").Trim();if(texto.Length==0||texto.Length>2000)return Fail("Escribe un comentario de 1 a 2000 caracteres.");
            var result=Db.Query(@"SET XACT_ABORT ON; BEGIN TRAN;
IF NOT EXISTS(SELECT Id FROM Tickets WITH(UPDLOCK,HOLDLOCK) WHERE Id=@id AND IdEstado<>4 AND (@admin=1 OR IdUsuarioSolicitante=@uid))
BEGIN ROLLBACK; SELECT 0 Ok; RETURN; END;
INSERT Comentarios(IdTicket,IdUsuario,Texto) VALUES(@id,@uid,@texto);
UPDATE Tickets SET FechaActualizacion=SYSUTCDATETIME() WHERE Id=@id;
COMMIT; SELECT 1 Ok;",Db.P("@id",id),Db.P("@uid",Actual.Id),Db.P("@admin",Actual.Admin),Db.P("@texto",texto));
            if((int)result.Rows[0]["Ok"]==0)return Fail("No se agregó: ticket cerrado o no disponible.",409);
            return Json(new {ok=true,mensaje="Comentario agregado."});
        }
    }
}

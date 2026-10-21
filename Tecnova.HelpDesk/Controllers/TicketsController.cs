using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Models;
using Tecnova.HelpDesk.Security;

namespace Tecnova.HelpDesk.Controllers
{
    [Access]
    public class TicketsController : ApiController
    {
        internal const string SelectTicket="SELECT t.Id,t.Titulo,t.Descripcion,t.Categoria,t.IdEstado,e.Nombre Estado,t.IdUsuarioSolicitante,t.IdUsuarioAsignado,u.Nombre Solicitante,a.Nombre Asignado,t.FechaCreacion,t.FechaActualizacion,t.FechaResolucion,t.FechaCierre,t.Version FROM Tickets t JOIN EstadosTicket e ON e.Id=t.IdEstado JOIN Usuarios u ON u.Id=t.IdUsuarioSolicitante LEFT JOIN Usuarios a ON a.Id=t.IdUsuarioAsignado ";
        [HttpGet] public ActionResult Listar(string q="",int estado=0)
        {
            q=(q??"").Trim();if(q.Length>150||estado<0||estado>4)return Fail("Filtro inválido.");
            int number;int.TryParse(q.TrimStart('#'),out number);
            string pattern="%"+q.Replace("[","[[]").Replace("%","[%]").Replace("_","[_]")+"%";
            var data=Db.Query(SelectTicket+"WHERE (@admin=1 OR t.IdUsuarioSolicitante=@uid) AND (@estado=0 OR t.IdEstado=@estado) AND (@q='' OR t.Titulo LIKE @pattern OR t.Id=@numero OR e.Nombre LIKE @pattern) ORDER BY t.Id DESC OFFSET 0 ROWS FETCH NEXT 200 ROWS ONLY",Db.P("@admin",Actual.Admin),Db.P("@uid",Actual.Id),Db.P("@estado",estado),Db.P("@q",q),Db.P("@pattern",pattern),Db.P("@numero",number));
            return Json(new {ok=true,datos=Db.Rows(data)},JsonRequestBehavior.AllowGet);
        }
        [HttpGet] public ActionResult Detalle(int id)
        {
            var data=Db.Query(SelectTicket+"WHERE t.Id=@id AND (@admin=1 OR t.IdUsuarioSolicitante=@uid)",Db.P("@id",id),Db.P("@admin",Actual.Admin),Db.P("@uid",Actual.Id));
            if(data.Rows.Count==0)return Fail("Ticket no disponible.",404);
            return Json(new {ok=true,datos=Db.Rows(data)[0]},JsonRequestBehavior.AllowGet);
        }
        private bool Valid(TicketInput input)
        {
            input.Titulo=(input.Titulo??"").Trim();input.Descripcion=(input.Descripcion??"").Trim();
            return ModelState.IsValid && input.Titulo.Length>0 && input.Descripcion.Length>0;
        }
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Crear(TicketInput input)
        {
            if(!Valid(input))return Fail("Completa título (hasta 150 caracteres), descripción (hasta 3000) y una categoría válida.");
            var data=Db.Query("INSERT Tickets(Titulo,Descripcion,Categoria,IdUsuarioSolicitante) OUTPUT INSERTED.Id VALUES(@t,@d,@c,@u)",Db.P("@t",input.Titulo),Db.P("@d",input.Descripcion),Db.P("@c",input.Categoria),Db.P("@u",Actual.Id));
            return Json(new {ok=true,id=data.Rows[0]["Id"],mensaje="Ticket registrado."});
        }
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Editar(int id,string version,TicketInput input)
        {
            if(!Valid(input))return Fail("Revisa título, descripción y categoría.");
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            int changed=Db.Execute("UPDATE Tickets SET Titulo=@t,Descripcion=@d,Categoria=@c,FechaActualizacion=SYSUTCDATETIME() WHERE Id=@id AND Version=@v AND IdEstado=1 AND (@admin=1 OR (IdUsuarioSolicitante=@uid AND IdUsuarioAsignado IS NULL))",Db.P("@t",input.Titulo),Db.P("@d",input.Descripcion),Db.P("@c",input.Categoria),Db.P("@id",id),Db.P("@v",v),Db.P("@admin",Actual.Admin),Db.P("@uid",Actual.Id));
            if(changed==0)return Fail("No se guardó: el ticket cambió o no admite edición. Actualiza el detalle.",409);
            return Json(new {ok=true,mensaje="Ticket actualizado."});
        }
        [HttpPost,ValidateAntiForgeryToken] public ActionResult Eliminar(int id,string version)
        {
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            using(var connection=Db.Open())using(var tx=connection.BeginTransaction())
            {
                using(var cmd=new SqlCommand("SELECT Id FROM Tickets WITH (UPDLOCK,HOLDLOCK) WHERE Id=@id AND Version=@v AND IdEstado=1 AND (@admin=1 OR (IdUsuarioSolicitante=@uid AND IdUsuarioAsignado IS NULL))",connection,tx))
                {
                    cmd.Parameters.AddRange(new[]{Db.P("@id",id),Db.P("@v",v),Db.P("@admin",Actual.Admin),Db.P("@uid",Actual.Id)});
                    if(cmd.ExecuteScalar()==null)return Fail("No se eliminó: el ticket cambió o no admite eliminación.",409);
                }
                using(var cmd=new SqlCommand("DELETE Comentarios WHERE IdTicket=@id; DELETE Tickets WHERE Id=@id;",connection,tx))
                {cmd.Parameters.Add(Db.P("@id",id));cmd.ExecuteNonQuery();}
                tx.Commit();
            }
            return Json(new {ok=true,mensaje="Ticket y sus comentarios eliminados."});
        }
    }
}

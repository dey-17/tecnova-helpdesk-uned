using System;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Web.Mvc;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;

namespace Tecnova.HelpDesk.Controllers
{
    [Access(Admin=true)]
    public class TecnicosController : ApiController
    {
        [HttpGet] public ActionResult Listar()
        { return Json(new {ok=true,datos=Db.Rows(Db.Query("SELECT Id,Nombre,Email,Estado,Version FROM Tecnicos ORDER BY Nombre"))},JsonRequestBehavior.AllowGet); }

        [HttpPost,ValidateAntiForgeryToken]
        public ActionResult Guardar(string nombre,string email,int id=0,string version=null)
        {
            nombre=(nombre??"").Trim(); email=(email??"").Trim().ToLowerInvariant();
            if(nombre.Length<2||nombre.Length>100||email.Length>254||!new EmailAddressAttribute().IsValid(email)||email.Length==0)
                return Fail("Revisa el nombre (2–100 caracteres) y el correo del técnico.");
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            try {
                int changed=Db.Execute(id==0
                    ? "INSERT Tecnicos(Nombre,Email) VALUES(@n,@e)"
                    : "UPDATE Tecnicos SET Nombre=@n,Email=@e WHERE Id=@id AND Version=@v",
                    Db.P("@n",nombre),Db.P("@e",email),Db.P("@id",id),Db.P("@v",v));
                if(changed==0)return Fail("El registro cambió. Vuelve a seleccionarlo.",409);
            }catch(SqlException ex){if(ex.Number==2601||ex.Number==2627)return Fail("Ya existe un técnico con ese correo.",409);throw;}
            return Json(new {ok=true,mensaje="Personal de soporte guardado. No se creó una cuenta de acceso."});
        }
        [HttpPost,ValidateAntiForgeryToken]
        public ActionResult Estado(int id,bool activo,string version)
        {
            byte[] v;try{v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            int changed=Db.Execute(@"UPDATE Tecnicos SET Estado=@activo WHERE Id=@id AND Version=@v
AND (@activo=1 OR NOT EXISTS(SELECT 1 FROM Tickets WHERE IdTecnicoAsignado=@id AND IdEstado IN (1,2)))",
                Db.P("@id",id),Db.P("@activo",activo),Db.P("@v",v));
            if(changed==0)return Fail("No se cambió: revisa la versión o reasigna sus tickets pendientes antes de darlo de baja.",409);
            return Json(new {ok=true,mensaje=activo?"Técnico activado.":"Técnico dado de baja. Su historial se conserva."});
        }
    }
}

using System;
using System.Net.Mail;
using System.Web.Mvc;
using System.Data.SqlClient;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;

namespace Tecnova.HelpDesk.Controllers
{
    [Access(Admin=true)]
    public class EmpleadosController : ApiController
    {
        [HttpGet] public ActionResult Listar()
        { return Json(new {ok=true,datos=Db.Rows(Db.Query("SELECT Id,Nombre,Email,Rol,Estado,Version FROM Usuarios ORDER BY Nombre"))},JsonRequestBehavior.AllowGet); }
        [HttpPost,ValidateAntiForgeryToken]
        public ActionResult Guardar(int? id,string nombre,string email,string password,string version)
        {
            nombre=(nombre??"").Trim(); email=(email??"").Trim().ToLowerInvariant();
            if(nombre.Length<2 || nombre.Length>100 || email.Length>254) return Fail("Nombre de 2 a 100 caracteres y correo válido obligatorios.");
            try { var address=new MailAddress(email); if(address.Address!=email) return Fail("El correo no es válido."); } catch(FormatException) { return Fail("El correo no es válido."); }
            if((!id.HasValue || !String.IsNullOrEmpty(password)) && (password==null || password.Length<12 || password.Length>128 || String.IsNullOrWhiteSpace(password))) return Fail("La contraseña debe tener entre 12 y 128 caracteres.");
            try
            {
                if(!id.HasValue) Db.Execute("INSERT Usuarios(Nombre,Email,PasswordHash,Rol) VALUES(@n,@e,@p,'Usuario')",Db.P("@n",nombre),Db.P("@e",email),Db.P("@p",Passwords.Hash(password)));
                else
                {
                    byte[] v; try {v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
                    string hash=String.IsNullOrEmpty(password)?null:Passwords.Hash(password);
                    int changed=Db.Execute("UPDATE Usuarios SET Nombre=@n,Email=@e,PasswordHash=COALESCE(@p,PasswordHash),SecurityStamp=CASE WHEN @p IS NULL THEN SecurityStamp ELSE NEWID() END,IntentosFallidos=CASE WHEN @p IS NULL THEN IntentosFallidos ELSE 0 END,BloqueadoHasta=CASE WHEN @p IS NULL THEN BloqueadoHasta ELSE NULL END WHERE Id=@id AND Rol='Usuario' AND Version=@v",Db.P("@n",nombre),Db.P("@e",email),Db.P("@p",hash),Db.P("@id",id.Value),Db.P("@v",v));
                    if(changed==0)return Fail("El empleado cambió o no se puede editar. Actualiza la lista.",409);
                }
            } catch(SqlException ex) { if(ex.Number==2601 || ex.Number==2627)return Fail("Ya existe una cuenta con ese correo.",409); throw; }
            return Json(new {ok=true,mensaje="Empleado guardado."});
        }
        [HttpPost,ValidateAntiForgeryToken]
        public ActionResult Estado(int id,bool activo,string version)
        {
            byte[] v; try {v=Convert.FromBase64String(version??"");}catch(FormatException){return Fail("Versión inválida.");}
            int changed=Db.Execute("UPDATE Usuarios SET Estado=@a,SecurityStamp=NEWID() WHERE Id=@id AND Rol='Usuario' AND Version=@v",Db.P("@a",activo),Db.P("@id",id),Db.P("@v",v));
            if(changed==0)return Fail("El empleado cambió o no se puede modificar. Actualiza la lista.",409);
            return Json(new {ok=true,mensaje=activo?"Empleado activado. Puede iniciar sesión.":"Empleado desactivado. Sus registros se conservan."});
        }
    }
}

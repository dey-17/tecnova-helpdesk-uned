using System;
using System.Web.Mvc;
using System.Web.Security;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;

namespace Tecnova.HelpDesk.Controllers
{
    public class CuentaController : ApiController
    {
        [HttpGet] public ActionResult Login() { return View(); }
        [HttpPost,ValidateAntiForgeryToken]
        public ActionResult Entrar(string email,string password)
        {
            if (String.IsNullOrWhiteSpace(email) || email.Length>254 || password==null || password.Length>128) return Fail("Revisa el correo y la contraseña.");
            var table=Db.Query("SELECT Id,PasswordHash,SecurityStamp,Estado,BloqueadoHasta FROM Usuarios WHERE Email=@email",Db.P("@email",email.Trim().ToLowerInvariant()));
            if(table.Rows.Count==0) return Fail("Correo o contraseña incorrectos, o cuenta no disponible.",401);
            var row=table.Rows[0];
            if(!(bool)row["Estado"] || (row["BloqueadoHasta"]!=DBNull.Value && (DateTime)row["BloqueadoHasta"]>DateTime.UtcNow)) return Fail("Correo o contraseña incorrectos, o cuenta no disponible.",401);
            if(!Passwords.Verify(password,(string)row["PasswordHash"]))
            {
                Db.Execute("UPDATE Usuarios SET IntentosFallidos=IntentosFallidos+1,BloqueadoHasta=CASE WHEN IntentosFallidos+1>=5 THEN DATEADD(minute,15,SYSUTCDATETIME()) ELSE NULL END WHERE Id=@id",Db.P("@id",row["Id"]));
                return Fail("Correo o contraseña incorrectos, o cuenta no disponible.",401);
            }
            Db.Execute("UPDATE Usuarios SET IntentosFallidos=0,BloqueadoHasta=NULL WHERE Id=@id",Db.P("@id",row["Id"]));
            FormsAuthentication.SetAuthCookie(row["Id"]+"|"+row["SecurityStamp"],false);
            return Json(new {ok=true,url=Url.Action("Panel","Inicio")});
        }
        [HttpPost,ValidateAntiForgeryToken]
        public ActionResult Salir() { FormsAuthentication.SignOut(); Session.Abandon(); return Json(new {ok=true,url=Url.Action("Login")}); }
    }
}

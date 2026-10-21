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
        [Access,HttpPost,ValidateAntiForgeryToken]
        public ActionResult CambiarClave(string actual,string nueva)
        {
            if(actual==null || actual.Length>128 || nueva==null || nueva.Length<12 || nueva.Length>128 || String.IsNullOrWhiteSpace(nueva))return Fail("La nueva contraseña debe tener entre 12 y 128 caracteres.");
            var table=Db.Query("SELECT PasswordHash FROM Usuarios WHERE Id=@id",Db.P("@id",Actual.Id));
            string previous=(string)table.Rows[0]["PasswordHash"];
            if(!Passwords.Verify(actual,previous))return Fail("La contraseña actual no es correcta.");
            int changed=Db.Execute("UPDATE Usuarios SET PasswordHash=@hash,SecurityStamp=NEWID() WHERE Id=@id AND PasswordHash=@anterior",Db.P("@hash",Passwords.Hash(nueva)),Db.P("@id",Actual.Id),Db.P("@anterior",previous));
            if(changed==0)return Fail("La cuenta cambió. Inicia sesión de nuevo.",409);
            FormsAuthentication.SignOut();return Json(new {ok=true,url=Url.Action("Login")});
        }
    }
}

using System;
using System.Web;
using System.Web.Mvc;
using System.Web.Security;
using Tecnova.HelpDesk.Data;

namespace Tecnova.HelpDesk.Security
{
    public sealed class Actor
    {
        public int Id { get; set; }
        public string Nombre { get; set; }
        public string Rol { get; set; }
        public bool Admin { get { return Rol == "Administrador"; } }
    }
    public sealed class AccessAttribute : AuthorizeAttribute
    {
        public bool Admin { get; set; }
        protected override bool AuthorizeCore(HttpContextBase context)
        {
            if (!context.Request.IsAuthenticated) return false;
            var parts = context.User.Identity.Name.Split('|'); int id; Guid stamp;
            if (parts.Length != 2 || !int.TryParse(parts[0], out id) || !Guid.TryParse(parts[1], out stamp)) return false;
            var table = Db.Query("SELECT Id,Nombre,Rol FROM Usuarios WHERE Id=@id AND SecurityStamp=@stamp AND Estado=1", Db.P("@id",id),Db.P("@stamp",stamp));
            if (table.Rows.Count == 0) { FormsAuthentication.SignOut(); return false; }
            var row = table.Rows[0];
            var actor = new Actor { Id=id, Nombre=(string)row["Nombre"], Rol=(string)row["Rol"] };
            context.Items["Actor"]=actor;
            return !Admin || actor.Admin;
        }
        protected override void HandleUnauthorizedRequest(AuthorizationContext filter)
        {
            var actor=filter.HttpContext.Items["Actor"] as Actor;
            if (!filter.HttpContext.Request.IsAjaxRequest() && actor == null)
            { filter.Result = new RedirectResult(VirtualPathUtility.ToAbsolute("~/Cuenta/Login")); return; }
            filter.HttpContext.Response.StatusCode = actor == null ? 401 : 403;
            filter.HttpContext.Response.SuppressFormsAuthenticationRedirect=true;
            filter.Result = new JsonResult { Data=new { ok=false, mensaje=actor == null ? "La sesión venció o la cuenta fue desactivada. Inicia sesión de nuevo." : "No tienes permiso para esta acción." }, JsonRequestBehavior=JsonRequestBehavior.AllowGet };
        }
    }
}

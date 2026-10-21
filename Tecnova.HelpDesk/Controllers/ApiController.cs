using System;
using System.Web.Mvc;
using System.Data.SqlClient;
using Tecnova.HelpDesk.Security;

namespace Tecnova.HelpDesk.Controllers
{
    public abstract class ApiController : Controller
    {
        protected Actor Actual { get { return HttpContext.Items["Actor"] as Actor; } }
        protected JsonResult Fail(string message, int status=400)
        { Response.StatusCode=status; Response.TrySkipIisCustomErrors=true; Response.SuppressFormsAuthenticationRedirect=true; return Json(new {ok=false,mensaje=message},JsonRequestBehavior.AllowGet); }
        protected override void OnException(ExceptionContext context)
        {
            if (context.Exception is System.Web.Mvc.HttpAntiForgeryException)
                context.Result=Fail("La página expiró. Recarga e intenta de nuevo.",400);
            else if (context.Exception is System.Web.HttpRequestValidationException)
                context.Result=Fail("Escribe texto sin etiquetas HTML ni código ejecutable.",400);
            else if (context.Exception is SqlException)
                context.Result=Fail("No se pudo completar la operación de datos. Verifica la conexión e intenta de nuevo.",503);
            else { base.OnException(context); return; }
            context.ExceptionHandled=true;
        }
        protected override void OnActionExecuted(ActionExecutedContext context)
        { Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache); Response.Cache.SetNoStore(); base.OnActionExecuted(context); }
    }
}

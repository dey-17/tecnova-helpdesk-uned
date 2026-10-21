using System.Web.Mvc;

namespace Tecnova.HelpDesk.Controllers
{
    public class InicioController : Controller
    {
        [Tecnova.HelpDesk.Security.Access]
        public ActionResult Panel()
        {
            return View(HttpContext.Items["Actor"]);
        }
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }
    }
}

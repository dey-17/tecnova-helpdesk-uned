using System.Web.Mvc;

namespace Tecnova.HelpDesk.Controllers
{
    public class InicioController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }
    }
}

using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace Tecnova.HelpDesk
{
    public class MvcApplication : HttpApplication
    {
        protected void Application_Start()
        {
            MvcHandler.DisableMvcResponseHeader = true;
            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
        }
    }
}

using System;
using System.Globalization;
using System.Web.Mvc;
using Tecnova.HelpDesk.Data;
using Tecnova.HelpDesk.Security;
namespace Tecnova.HelpDesk.Controllers
{
    [Access(Admin=true)]
    public class ReportesController : ApiController
    {
        [HttpGet] public ActionResult Resumen(string desde,string hasta,int estado=0)
        {
            DateTime start,end;
            if(!DateTime.TryParseExact(desde,"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out start)||!DateTime.TryParseExact(hasta,"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out end)||end<start||end.Year>9998||estado<0||estado>4)return Fail("Selecciona un periodo válido y un estado.");
            var grouped=Db.Query(@"SELECT e.Id,e.Nombre Estado,COUNT(t.Id) Cantidad FROM EstadosTicket e LEFT JOIN Tickets t ON t.IdEstado=e.Id AND t.FechaCreacion>=@desde AND t.FechaCreacion<@hasta WHERE (@estado=0 OR e.Id=@estado) GROUP BY e.Id,e.Nombre ORDER BY e.Id",Db.P("@desde",start),Db.P("@hasta",end.AddDays(1)),Db.P("@estado",estado));
            var summary=Db.Query(@"SELECT COUNT(*) Total,COUNT(FechaResolucion) Resueltos,AVG(CASE WHEN FechaResolucion IS NOT NULL THEN DATEDIFF_BIG(second,FechaCreacion,FechaResolucion)/3600.0 END) PromedioHoras FROM Tickets WHERE FechaCreacion>=@desde AND FechaCreacion<@hasta AND (@estado=0 OR IdEstado=@estado)",Db.P("@desde",start),Db.P("@hasta",end.AddDays(1)),Db.P("@estado",estado));
            return Json(new {ok=true,estados=Db.Rows(grouped),resumen=Db.Rows(summary)[0]},JsonRequestBehavior.AllowGet);
        }
    }
}

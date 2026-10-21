using System.ComponentModel.DataAnnotations;
namespace Tecnova.HelpDesk.Models
{
    public class TicketInput
    {
        [Required, StringLength(150)] public string Titulo { get; set; }
        [Required, StringLength(3000)] public string Descripcion { get; set; }
        [Required, RegularExpression("^(Hardware|Software|Red|Accesos|Otro)$")] public string Categoria { get; set; }
    }
}

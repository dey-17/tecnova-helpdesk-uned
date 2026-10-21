(function(){
    'use strict';const api=window.tecnova;if(!api)return;const {request,busy,message,el,confirmAction,navigate}=api;
    const form=document.getElementById('ticket-form'),list=document.getElementById('tickets-lista'),detail=document.getElementById('detalle-ticket');let current=null,sequence=0,detailSequence=0;
    const admin=document.body.dataset.admin==='true';
    const history=document.getElementById('historial-listado');
    function showHistory(){detailSequence++;detail.hidden=true;history.hidden=false;}
    const date=value=>new Date(value).toLocaleString('es-CR');
    async function load(){const order=++sequence;const filter=window.tecnovaFilter?window.tecnovaFilter():'';const r=await request('Tickets/Listar'+filter);if(order!==sequence)return;list.replaceChildren();r.datos.forEach(ticket=>{const card=el('article',undefined,'record');card.append(el('span','#'+ticket.Id+' · '+ticket.Estado,'badge state-'+ticket.IdEstado),el('h2',ticket.Titulo),el('p',ticket.Categoria+' · '+ticket.Solicitante,'muted'),el('p','Creado: '+date(ticket.FechaCreacion),'muted'));const button=el('button','Ver detalle →','button-secondary');button.onclick=()=>busy(card,()=>open(ticket.Id));const actions=el('div',undefined,'actions');actions.append(button);
        if(admin&&ticket.IdEstado===3){
            const finish=el('button','Finalizar ticket','button-primary');finish.type='button';
            finish.onclick=()=>busy(card,async()=>{
                if(!await confirmAction('Finalizar el ticket #'+ticket.Id+'? Quedará cerrado y solo se podrá consultar.'))return;
                const result=await request('Soporte/Estado',{id:ticket.Id,estado:4,version:ticket.Version,solucion:''});
                await load();message(result.mensaje);
            });actions.append(finish);
        }
        card.append(actions);list.append(card);});}
    function reset(){form.reset();form.elements.id.value='';form.elements.version.value='';document.getElementById('titulo-form-ticket').textContent='Crear ticket';}
    async function open(id){const order=++detailSequence;const r=await request('Tickets/Detalle?id='+encodeURIComponent(id));if(order!==detailSequence)return;current=r.datos;const ticket=current,content=document.getElementById('detalle-contenido');document.getElementById('gestion-ticket').replaceChildren();document.getElementById('comentarios-ticket').replaceChildren();content.replaceChildren();content.append(el('span','#'+ticket.Id+' · '+ticket.Estado,'badge state-'+ticket.IdEstado),el('h2',ticket.Titulo),el('p',ticket.Descripcion),el('p','Solicitante: '+ticket.Solicitante+' · Responsable: '+(ticket.Asignado||'Sin asignar'),'muted'),el('p','Categoría: '+ticket.Categoria+' · Actualizado: '+date(ticket.FechaActualizacion),'muted'));
        if(ticket.IdEstado===1&&(admin||(!ticket.IdUsuarioAsignado&&!ticket.IdTecnicoAsignado))){const actions=el('div',undefined,'actions');const edit=el('button','Editar','button-secondary');edit.onclick=()=>{form.elements.id.value=ticket.Id;form.elements.version.value=ticket.Version;['Titulo','Descripcion','Categoria'].forEach(k=>form.elements[k].value=ticket[k]);document.getElementById('titulo-form-ticket').textContent='Editar ticket #'+ticket.Id;navigate('crear');form.elements.Titulo.focus();};const remove=el('button','Eliminar','button-secondary');remove.onclick=()=>busy(content,async()=>{if(!await confirmAction('Eliminar el ticket #'+ticket.Id+' y sus comentarios? Esta acción no se puede deshacer.'))return;const result=await request('Tickets/Eliminar',{id:ticket.Id,version:ticket.Version});showHistory();reset();message(result.mensaje);await load();});actions.append(edit,remove);content.append(actions);}
        history.hidden=true;detail.hidden=false;
        const events=await request('Tickets/Historial?id='+ticket.Id);if(order!==detailSequence)return;
        const resolved=events.datos.filter(x=>x.Accion==='Ticket resuelto').pop();
        const phrase=ticket.IdEstado===2?'Está siendo atendido por: ':ticket.IdEstado>=3?(resolved?'Resuelto por: ':'Responsable registrado: '):'Responsable asignado: ';
        content.append(el('p',phrase+(resolved?resolved.Responsable:ticket.Asignado||'Pendiente de asignación'),'attention-status'));
        const timeline=el('div',undefined,'attention-timeline');timeline.append(el('h3','Historial de atención'));
        if(!events.datos.length)timeline.append(el('p','No hay movimientos registrados. Los tickets anteriores conservan sus datos originales.','muted'));
        events.datos.forEach(event=>{const item=el('p');item.append(el('strong',event.Accion+' · '+event.Responsable),el('br'),document.createTextNode('Registrado por '+event.Administrador+' · '+date(event.Fecha)));timeline.append(item);});content.append(timeline);
        if(window.tecnovaDetails)await window.tecnovaDetails(ticket);if(order!==detailSequence)return;if(window.tecnovaComments)await window.tecnovaComments(ticket);if(order!==detailSequence)return;detail.scrollIntoView({block:'start'});
    }
    form.onsubmit=e=>{e.preventDefault();busy(form,async()=>{const editing=!!form.elements.id.value;const result=await request('Tickets/'+(editing?'Editar':'Crear'),new FormData(form));reset();showHistory();await navigate('tickets');message(result.mensaje);});};
    document.getElementById('cancelar-ticket').onclick=()=>{const editing=!!form.elements.id.value;reset();if(editing)navigate('tickets').catch(e=>message(e.message,true));};
    document.getElementById('cerrar-detalle').onclick=()=>{showHistory();document.getElementById('titulo-historial').focus();load().catch(e=>message(e.message,true));};
    window.tecnovaTickets={load,open,current:()=>current};window.tecnovaSections=window.tecnovaSections||{};window.tecnovaSections.tickets=()=>{showHistory();return load();};
    document.addEventListener('DOMContentLoaded',()=>navigate(admin?'tickets':'crear').catch(e=>message(e.message,true)));
}());

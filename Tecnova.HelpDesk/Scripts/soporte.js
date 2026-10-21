(function(){
    'use strict';const {request,busy,message,el}=window.tecnova;const host=document.getElementById('busqueda-tickets');const filters=el('div',undefined,'filters');const label=el('label','Buscar por número, título o estado'),query=el('input');query.maxLength=150;query.type='search';label.append(query);const stateLabel=el('label','Estado'),state=el('select');['Todos','Abierto','En Proceso','Resuelto','Cerrado'].forEach((name,i)=>{const op=el('option',name);op.value=i;state.append(op);});stateLabel.append(state);filters.append(label,stateLabel);host.append(filters);let timer;
    window.tecnovaFilter=()=>'?'+new URLSearchParams({q:query.value,estado:state.value});
    query.oninput=()=>{clearTimeout(timer);timer=setTimeout(()=>window.tecnovaTickets.load().catch(e=>message(e.message,true)),300);};state.onchange=()=>window.tecnovaTickets.load().catch(e=>message(e.message,true));
    if(document.body.dataset.admin!=='true')return;
    let sequence=0;
    window.tecnovaDetails=async function(ticket){
        const order=++sequence;const box=document.getElementById('gestion-ticket');box.replaceChildren(el('h2','Atención de soporte'));
        if(ticket.IdEstado===4){box.append(el('p','El ticket está cerrado. Se conserva para consulta y reportes.'));return;}
        if(ticket.IdEstado<=2){const result=await request('Soporte/Responsables');if(order!==sequence)return;const form=el('form'),label=el('label','Responsable de soporte'),select=el('select');select.required=true;result.datos.forEach(user=>{const op=el('option',user.Nombre);op.value=user.Id;op.selected=ticket.IdUsuarioAsignado===user.Id;select.append(op);});label.append(select);const button=el('button','Asignar responsable','button-secondary');form.append(label,button);form.onsubmit=e=>{e.preventDefault();busy(form,async()=>{const r=await request('Soporte/Asignar',{id:ticket.Id,responsable:select.value,version:ticket.Version});message(r.mensaje);await window.tecnovaTickets.open(ticket.Id);await window.tecnovaTickets.load();});};box.append(form);}
        const form=el('form');let solution;
        if(ticket.IdEstado===2){const label=el('label','Cómo se solucionó el problema');solution=el('textarea');solution.required=true;solution.minLength=10;solution.maxLength=2000;label.append(solution);form.append(label);}
        const labels={1:'Iniciar atención',2:'Marcar como resuelto',3:'Cerrar ticket'};const button=el('button',labels[ticket.IdEstado],'button-primary');form.append(button);form.onsubmit=e=>{e.preventDefault();busy(form,async()=>{if(!await window.tecnova.confirmAction(labels[ticket.IdEstado]+' #'+ticket.Id+'?'))return;const r=await request('Soporte/Estado',{id:ticket.Id,estado:ticket.IdEstado+1,version:ticket.Version,solucion:solution?solution.value:''});message(r.mensaje);await window.tecnovaTickets.open(ticket.Id);await window.tecnovaTickets.load();});};box.append(form);
    };
}());

(function(){
    'use strict';const {request,busy,message,el}=window.tecnova;const drafts=new Map();let sequence=0;
    window.tecnovaComments=async function(ticket){
        const order=++sequence;const box=document.getElementById('comentarios-ticket');box.replaceChildren(el('h2','Comentarios'),el('p','Cargando comentarios…','muted'));
        const r=await request('Comentarios/Listar?id='+ticket.Id);if(order!==sequence)return;
        box.replaceChildren(el('h2','Comentarios'));
        if(!r.datos.length)box.append(el('p','Todavía no hay comentarios.','muted'));
        r.datos.forEach(comment=>{const card=el('article',undefined,'record');card.append(el('strong',comment.Autor),el('p',new Date(comment.Fecha).toLocaleString('es-CR'),'muted'),el('p',comment.Texto));box.append(card);});
        if(ticket.IdEstado===4){box.append(el('p','Ticket cerrado: no se admiten comentarios nuevos.'));return;}
        const form=el('form'),label=el('label','Agregar comentario'),input=el('textarea');input.required=true;input.maxLength=2000;input.value=drafts.get(ticket.Id)||'';input.oninput=()=>drafts.set(ticket.Id,input.value);label.append(input);const button=el('button','Enviar comentario','button-primary');button.type='submit';form.append(label,button);box.append(form);
        form.onsubmit=e=>{e.preventDefault();busy(form,async()=>{const result=await request('Comentarios/Agregar',{id:ticket.Id,texto:input.value});drafts.delete(ticket.Id);message(result.mensaje);await window.tecnovaTickets.open(ticket.Id);await window.tecnovaTickets.load();});};
    };
}());

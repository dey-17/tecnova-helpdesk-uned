(function(){
    'use strict';const {request,busy,message,el}=window.tecnova;const drafts=new Map();let sequence=0;
    window.tecnovaComments=async function(ticket){
        const order=++sequence;const box=document.getElementById('comentarios-ticket');box.replaceChildren(el('h2','Comentarios'),el('p','Cargando comentarios…','muted'));
        const r=await request('Comentarios/Listar?id='+ticket.Id);if(order!==sequence)return;
        box.replaceChildren(el('h2','Comentarios'));
        if(!r.datos.length)box.append(el('p','Todavía no hay comentarios.','muted'));
        r.datos.forEach(comment=>{const card=el('article',undefined,'record');card.append(el('strong',comment.Autor),el('p',new Date(comment.Fecha).toLocaleString('es-CR'),'muted'),el('p',comment.Texto));if(comment.Propio&&ticket.IdEstado!==4){
            const edit=el('button','Editar comentario','button-secondary');edit.type='button';
            edit.onclick=()=>{edit.hidden=true;const f=el('form'),label=el('label','Editar tu comentario'),input=el('textarea');input.required=true;input.maxLength=2000;input.value=comment.Texto;label.append(input);
            const save=el('button','Guardar cambios','button-primary'),cancel=el('button','Cancelar','button-secondary');cancel.type='button';cancel.onclick=()=>{f.remove();edit.hidden=false;};f.append(label,save,cancel);card.append(f);input.focus();
            f.onsubmit=e=>{e.preventDefault();busy(f,async()=>{const r=await request('Comentarios/Editar',{id:ticket.Id,comentario:comment.Id,texto:input.value,version:ticket.Version});await window.tecnovaTickets.open(ticket.Id);message(r.mensaje);});};};card.append(edit);
        }box.append(card);});
        const yaComento=r.datos.some(comment=>comment.Propio);
        if(ticket.IdEstado>=3||yaComento)return;
        const form=el('form'),label=el('label','Agregar comentario'),input=el('textarea');input.required=true;input.maxLength=2000;input.value=drafts.get(ticket.Id)||'';input.oninput=()=>drafts.set(ticket.Id,input.value);label.append(input);const button=el('button','Enviar comentario','button-primary');button.type='submit';form.append(label,button);box.append(form);
        form.onsubmit=e=>{e.preventDefault();busy(form,async()=>{const result=await request('Comentarios/Agregar',{id:ticket.Id,texto:input.value});drafts.delete(ticket.Id);message(result.mensaje);await window.tecnovaTickets.open(ticket.Id);await window.tecnovaTickets.load();});};
    };
}());

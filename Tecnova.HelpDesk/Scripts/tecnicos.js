(function(){
    'use strict';
    const form=document.getElementById('tecnico-form');if(!form)return;
    const {request,busy,message,el,confirmAction}=window.tecnova,list=document.getElementById('tecnicos-lista');
    function reset(){form.reset();form.elements.id.value='0';form.elements.version.value='';}
    async function load(){
        const r=await request('Tecnicos/Listar');list.replaceChildren();
        r.datos.forEach(t=>{
            const card=el('article',undefined,'record');
            card.append(el('span',t.Estado?'Activo':'Inactivo','badge'),el('h2',t.Nombre),el('p',t.Email));
            const actions=el('div',undefined,'actions'),edit=el('button','Editar','button-secondary'),toggle=el('button',t.Estado?'Dar de baja':'Activar','button-secondary');
            edit.onclick=()=>{form.elements.id.value=t.Id;form.elements.version.value=t.Version;form.elements.nombre.value=t.Nombre;form.elements.email.value=t.Email;form.elements.nombre.focus();};
            toggle.onclick=()=>busy(card,async()=>{if(!await confirmAction((t.Estado?'Dar de baja a ':'Activar a ')+t.Nombre+'?'))return;const r=await request('Tecnicos/Estado',{id:t.Id,activo:!t.Estado,version:t.Version});message(r.mensaje);reset();await load();});
            actions.append(edit,toggle);card.append(actions);list.append(card);
        });
    }
    form.onsubmit=e=>{e.preventDefault();busy(form,async()=>{const r=await request('Tecnicos/Guardar',new FormData(form));reset();await load();message(r.mensaje);});};
    document.getElementById('cancelar-tecnico').onclick=reset;
    window.tecnovaSections.tecnicos=load;
}());


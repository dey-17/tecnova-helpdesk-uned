(function(){
    'use strict';
    const root=document.body.dataset.root||'';
    const token=()=>document.querySelector('[name="__RequestVerificationToken"]').value;
    const el=(tag,text,cls)=>{const n=document.createElement(tag);if(tag==='form')n.noValidate=true;if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
    const message=(text,error=false)=>{const n=document.getElementById('mensaje')||document.getElementById('mensaje-login');n.textContent=text;n.hidden=false;n.dataset.error=error;};
    document.querySelectorAll('form').forEach(form=>form.noValidate=true);
    document.addEventListener('submit',event=>{const form=event.target;if(!form.checkValidity()){event.preventDefault();event.stopImmediatePropagation();const invalid=form.querySelector(':invalid');message('Revisa los campos obligatorios y sus límites. '+(invalid?invalid.validationMessage:''),true);if(invalid)invalid.focus();}},true);
    async function request(path,data){
        const options={headers:{'X-Requested-With':'XMLHttpRequest'},credentials:'same-origin',cache:'no-store'};
        if(data){options.method='POST';const body=new URLSearchParams(data);body.set('__RequestVerificationToken',token());options.body=body;}
        let response;try{response=await fetch(root+path,options);}catch(e){throw new Error('No se confirmó la operación. Revisa la conexión y consulta antes de repetir.');}
        let result;try{result=await response.json();}catch(e){throw new Error('No se pudo interpretar la respuesta. Recarga la página.');}
        if(!response.ok||!result.ok)throw new Error(result.mensaje||'No se pudo completar la operación.');
        return result;
    }
    async function busy(form,action){const controls=Array.from(form.querySelectorAll('button'));controls.forEach(b=>b.disabled=true);try{await action();}catch(e){message(e.message,true);}finally{controls.forEach(b=>b.disabled=false);}}
    function confirmAction(text){return new Promise(resolve=>{const d=document.getElementById('confirmacion');document.getElementById('confirmacion-texto').textContent=text;const finish=value=>{d.close();resolve(value);};document.getElementById('confirmar-si').onclick=()=>finish(true);document.getElementById('confirmar-no').onclick=()=>finish(false);d.oncancel=e=>{e.preventDefault();finish(false);};d.showModal();document.getElementById('confirmar-no').focus();});}
    const login=document.getElementById('login-form');
    if(login){login.addEventListener('submit',e=>{e.preventDefault();busy(login,async()=>{const r=await request(login.getAttribute('action'),new FormData(login));location.assign(r.url);});});return;}
    document.getElementById('salir').onclick=()=>busy(document.querySelector('nav'),async()=>{const r=await request('Cuenta/Salir',{});location.assign(r.url);});
    async function navigate(name){
        const button=document.querySelector('[data-section="'+name+'"]');if(!button)return;
        document.getElementById('mensaje').hidden=true;
        document.querySelectorAll('[id^="seccion-"]').forEach(section=>section.hidden=section.id!=='seccion-'+button.dataset.section);
        document.querySelectorAll('[data-section]').forEach(b=>b.removeAttribute('aria-current'));button.setAttribute('aria-current','page');
        if(button.dataset.section==='empleados')loadEmployees().catch(e=>message(e.message,true));
        if(window.tecnovaSections&&window.tecnovaSections[button.dataset.section])await window.tecnovaSections[button.dataset.section]();
    }
    document.querySelectorAll('[data-section]').forEach(button=>button.onclick=()=>navigate(button.dataset.section).catch(e=>message(e.message,true)));
    const employeeForm=document.getElementById('empleado-form');
    async function loadEmployees(){
        const r=await request('Empleados/Listar');const list=document.getElementById('empleados-lista');list.replaceChildren();
        r.datos.forEach(user=>{const card=el('article',undefined,'record');card.append(el('h3',user.Nombre),el('p',user.Email),el('span',user.Rol+' · '+(user.Estado?'Activo':'Inactivo'),'badge'));
            if(user.Rol==='Usuario'){const actions=el('div',undefined,'actions');const edit=el('button','Editar','button-secondary');edit.onclick=()=>{['id','nombre','email','version'].forEach(k=>employeeForm.elements[k].value=user[{id:'Id',nombre:'Nombre',email:'Email',version:'Version'}[k]]);employeeForm.elements.password.value='';employeeForm.elements.nombre.focus();};
            const state=el('button',user.Estado?'Dar de baja':'Dar de alta','button-secondary');state.onclick=()=>busy(card,async()=>{if(!await confirmAction((user.Estado?'Desactivar':'Activar')+' a '+user.Nombre+'?'))return;const result=await request('Empleados/Estado',{id:user.Id,activo:!user.Estado,version:user.Version});message(result.mensaje);await loadEmployees();});actions.append(edit,state);card.append(actions);}list.append(card);});
    }
    if(employeeForm){employeeForm.onsubmit=e=>{e.preventDefault();busy(employeeForm,async()=>{const result=await request('Empleados/Guardar',new FormData(employeeForm));employeeForm.reset();message(result.mensaje);await loadEmployees();});};document.getElementById('cancelar-empleado').onclick=()=>employeeForm.reset();}
    window.tecnova={request,busy,message,el,confirmAction,navigate};
    const passwordForm=document.getElementById('clave-form');
    passwordForm.onsubmit=e=>{e.preventDefault();busy(passwordForm,async()=>{const r=await request('Cuenta/CambiarClave',new FormData(passwordForm));location.assign(r.url);});};
}());

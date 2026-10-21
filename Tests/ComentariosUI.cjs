const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../Tecnova.HelpDesk/Scripts/comentarios.js'), 'utf8');
function element(tag, text) {
    return {tag, text, children: [], append(...items) { this.children.push(...items); },
        replaceChildren(...items) { this.children = items; }};
}
async function check(admin, state, comments, add, edit) {
    const box = element('div');
    const context = {window: {tecnova: {el: element, request: async () => ({datos: comments}), busy() {}, message() {}}},
        document: {body: {dataset: {admin: String(admin)}}, getElementById: () => box}};
    vm.runInNewContext(source, context);
    await context.window.tecnovaComments({Id: 1, IdEstado: state});
    const texts = [];
    function walk(node) { texts.push(node.text); node.children.forEach(walk); }
    walk(box);
    assert.equal(texts.includes('Agregar comentario'), add);
    assert.equal(texts.includes('Editar comentario'), edit);
}
(async () => {
    const own = {Propio: true, Autor: 'Empleado', Texto: 'Prueba', Fecha: '2026-10-21T12:00:00Z'};
    const other = {...own, Propio: false};
    await check(false, 1, [], true, false);
    await check(false, 1, [other], true, false);
    await check(false, 1, [own], false, true);
    await check(false, 2, [own, other], false, true);
    await check(false, 3, [own], false, true);
    await check(false, 4, [own], false, false);
    await check(true, 1, [], true, false);
    await check(true, 1, [other], true, false);
    await check(true, 1, [own], false, true);
    await check(true, 2, [own], false, true);
    await check(true, 3, [own], false, true);
    await check(true, 4, [own], false, false);
    console.log('PASS: empleados y administradores: primera publicación, edición propia y cierre de solo lectura.');
})().catch(error => { console.error(error); process.exitCode = 1; });

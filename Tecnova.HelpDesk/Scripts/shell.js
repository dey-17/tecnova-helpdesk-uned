(function () {
    "use strict";
    var panels = document.querySelectorAll("[data-panel]");
    var links = document.querySelectorAll(".nav-link");
    var notice = document.getElementById("aviso");
    var noticeText = document.getElementById("aviso-texto");
    var closeNotice = document.getElementById("cerrar-aviso");
    function showNotice(message) {
        noticeText.textContent = message;
        notice.hidden = false;
    }
    function navigate(moveFocus) {
        var name = window.location.hash.slice(1) || "inicio";
        if (name === "contenido") { return; }
        if (name !== "inicio" && name !== "servicio") {
            name = "inicio";
            window.history.replaceState(null, "", "#inicio");
            showNotice("Esta sección no está disponible. Te mostramos el inicio.");
        } else {
            notice.hidden = true;
        }
        Array.prototype.forEach.call(panels, function (panel) {
            panel.hidden = panel.getAttribute("data-panel") !== name;
        });
        Array.prototype.forEach.call(links, function (link) {
            if (link.getAttribute("href") === "#" + name) { link.setAttribute("aria-current", "page"); }
            else { link.removeAttribute("aria-current"); }
        });
        document.title = (name === "inicio" ? "Inicio" : "Ruta de atención") + " · Tecnova Help Desk";
        if (moveFocus) { document.getElementById("titulo-" + name).focus(); }
    }
    closeNotice.addEventListener("click", function () {
        notice.hidden = true;
        var active = document.querySelector('.nav-link[aria-current="page"]');
        if (active) { active.focus(); }
    });
    window.addEventListener("hashchange", function () { navigate(true); });
    navigate(false);
}());

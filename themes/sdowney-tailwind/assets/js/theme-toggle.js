// theme-toggle.js — dark/light mode toggle for sdowney-tailwind
// The anti-FOUC script in base_helper.tmpl sets the initial html.dark class
// synchronously. This script handles the user toggle and Modus stylesheet swap.

function applyTheme(dark) {
    document.documentElement.classList.toggle('dark', dark);

    var light = document.getElementById('modus-light');
    var vivendi = document.getElementById('modus-dark');
    if (light)   light.media   = dark ? 'not all' : 'all';
    if (vivendi) vivendi.media = dark ? 'all'     : 'not all';

    localStorage.setItem('theme', dark ? 'dark' : 'light');
}

// Sync Modus stylesheets with the class already set by the anti-FOUC script.
(function () {
    var dark = document.documentElement.classList.contains('dark');
    var light = document.getElementById('modus-light');
    var vivendi = document.getElementById('modus-dark');
    if (light)   light.media   = dark ? 'not all' : 'all';
    if (vivendi) vivendi.media = dark ? 'all'     : 'not all';
})();

document.addEventListener('DOMContentLoaded', function () {
    var btn = document.getElementById('theme-toggle');
    if (!btn) return;
    btn.addEventListener('click', function () {
        applyTheme(!document.documentElement.classList.contains('dark'));
    });
});

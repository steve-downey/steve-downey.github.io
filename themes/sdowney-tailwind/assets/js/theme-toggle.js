// theme-toggle.js — dark/light mode toggle for sdowney-tailwind
// The anti-FOUC script in base_helper.tmpl sets the initial html.dark class
// synchronously. This script handles the user toggle and keeps the configured
// syntax highlighting stylesheet pair aligned with the current light/dark mode.

function syncModusStylesheets(dark) {
    var lightTheme = document.getElementById('modus-light');
    var darkTheme = document.getElementById('modus-dark');
    if (lightTheme) lightTheme.media = dark ? 'not all' : 'all';
    if (darkTheme) darkTheme.media = dark ? 'all' : 'not all';
}

function applyTheme(dark) {
    document.documentElement.classList.toggle('dark', dark);
    syncModusStylesheets(dark);
    localStorage.setItem('theme', dark ? 'dark' : 'light');
}

// Sync Modus stylesheets with the class already set by the anti-FOUC script.
(function () {
    syncModusStylesheets(document.documentElement.classList.contains('dark'));
})();

document.addEventListener('DOMContentLoaded', function () {
    var btn = document.getElementById('theme-toggle');
    if (!btn) return;
    btn.addEventListener('click', function () {
        applyTheme(!document.documentElement.classList.contains('dark'));
    });
});

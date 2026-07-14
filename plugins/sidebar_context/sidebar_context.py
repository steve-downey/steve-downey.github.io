import blinker
from nikola.plugin_categories import SignalHandler


class SidebarContext(SignalHandler):
    """Inject all_posts into the global template context after scanning."""

    def set_site(self, site):
        super().set_site(site)
        blinker.signal("scanned").connect(self._inject)

    def _inject(self, site):
        site._GLOBAL_CONTEXT["all_posts"] = site.all_posts

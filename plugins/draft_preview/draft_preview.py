"""Preview draft posts locally without publishing them.

Set the ``NIKOLA_SHOW_DRAFTS`` environment variable (see the ``serve-drafts``
Makefile target) to have posts with ``status: draft`` rendered as though they
were published: they appear in the blog index, tag and archive pages, feeds,
and the Recent Posts sidebar. Without the variable, drafts behave normally --
their page still renders at its own URL for a quick content preview, but they
stay out of every listing, and ``DEPLOY_DRAFTS = False`` keeps them off the
deployed site entirely.

The mechanism: ``Post.__init__`` computes ``use_in_feeds`` immediately after
calling ``_set_tags`` (which is where ``status: draft`` sets ``is_draft``). By
wrapping ``_set_tags`` to clear ``is_draft`` before ``use_in_feeds`` is
derived, the draft flows through Nikola's normal classification with no other
changes needed.
"""

import os
import sys

from nikola.plugin_categories import SignalHandler
from nikola.post import Post
from nikola.utils import LOGGER

# Commands that publish output. If drafts were un-drafted here, they would be
# treated as live posts and shipped, so refuse to activate under any of them
# even if the environment variable leaked in.
_DEPLOY_COMMANDS = {"deploy", "github_deploy"}


class DraftPreview(SignalHandler):
    """Un-draft posts for local preview when NIKOLA_SHOW_DRAFTS is set."""

    def set_site(self, site):
        super().set_site(site)

        if not os.environ.get("NIKOLA_SHOW_DRAFTS"):
            return

        if _DEPLOY_COMMANDS.intersection(sys.argv):
            LOGGER.error(
                "NIKOLA_SHOW_DRAFTS is set during a deploy command; "
                "ignoring it so drafts are not published."
            )
            return

        if getattr(Post, "_draft_preview_patched", False):
            return

        _orig_set_tags = Post._set_tags

        def _set_tags(self):
            _orig_set_tags(self)
            if self.is_draft:
                self.is_draft = False
                self.post_status = "published"

        Post._set_tags = _set_tags
        Post._draft_preview_patched = True
        LOGGER.warning(
            "NIKOLA_SHOW_DRAFTS is set: drafts are rendered as published. "
            "Do not deploy this build."
        )

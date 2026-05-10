#!/usr/bin/env python3
"""Strip bare element CSS rules (body, a, a:hover) from htmlize output.

These rules conflict with site CSS frameworks.  Only .org-* face class
rules should remain.  Handles both commented-out rules (/* body { */ ...
/* } */) and uncommented ones (a { ... }).
"""

import re
import sys


def strip_base_rules(text: str) -> str:
    # Commented-out rules: /* body { */ ... /* } */
    text = re.sub(
        r"(?m)^[ \t]*/\*\s*(?:body|a(?::hover|:visited|:link|:active)?)\s*\{\s*\*/.*?/\*\s*\}\s*\*/\s*\n",
        "",
        text,
        flags=re.DOTALL,
    )
    # Uncommented rules: a { ... }
    text = re.sub(
        r"(?m)^[ \t]*(?:body|a(?::hover|:visited|:link|:active)?)\s*\{[^}]*\}\s*\n?",
        "",
        text,
    )
    # Collapse runs of blank lines
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


if __name__ == "__main__":
    for path in sys.argv[1:]:
        text = open(path).read()
        cleaned = strip_base_rules(text)
        if text != cleaned:
            open(path, "w").write(cleaned)

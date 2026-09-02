# Orgit Link Integration Patch

This patch enables `orgit` link formatting in the WCTM blog via Nikola's org-mode export hooks.

## What is addressed:
When utilizing `orgit` references in blog posts (such as `[[orgit:~/src/steve-downey/schemepoc/schemepoc/::src/smd/...]]`), the standard `ox-html` and `ox-gfm` exporters will fail with an "Unable to resolve link" error, as the `orgit` scheme is not natively handled.

## How it works:
The patch registers an `orgit` link parameter into `plugins/orgmode/init.el` using `org-link-set-parameters`.
When an `orgit` link is processed:
1. It splits the internal path by the `::` separator to extract the target filepath (e.g. `src/smd/smdscheme/parser/cursor.hpp`).
2. It concatenates the filepath against a configurable base URL (`orgit-base-url`), currently pointing to the `schemepoc` GitHub blob endpoint.
3. For `.md` or `.gfm` targets, it exports standard inline Markdown links wrapping inline code. For `html`, it emits an anchor tag surrounding a `<code>` element, preserving styling when Nikola processes the org buffer.

## Instructions:
Apply the patch directly inside your `~/src/steve-downey/wctm/src` environment:
```sh
git am 0001-Add-orgit-link-export-support-for-orgmode.patch
```
After application, adjust the base URL if needed for sub-blogs, or consider hooking it to dynamic variables depending on the WCTM structure.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"What Comes to Mind" — a personal blog by Steve Downey at sdowney.org. Built with [Nikola](https://getnikola.com/), a static site generator. The `src` branch holds source content; the `main` branch holds the generated HTML output deployed to GitHub Pages.

## Commands

All commands use `uv` for environment management. `make` targets are the primary interface.

```sh
make compile          # Build the site (uv run nikola build)
make test             # Build + check file integrity (default)
make test-files       # Check generated file integrity only
make test-local-links # Check local links in output
make test-links       # Check remote links (slow)
make lint             # Run all pre-commit hooks
make clean            # Remove output via nikola clean
make realclean        # rm -rf output/ cache/ and delete .venv
make github-deploy    # Build, test, commit source, push output to main
make prod-deploy      # rsync output/ to panix3.panix.com (sdowney.org)
```

Direct nikola commands (via `uv run nikola`):
```sh
uv run nikola new_post    # Create a new post (prompts for title/format)
uv run nikola new_page    # Create a new page
uv run nikola serve       # Serve the site locally for preview
uv run nikola check -f    # Check file integrity
```

## Architecture

### Content pipeline

Nikola reads source files from `posts/` and `pages/`, compiles them to HTML fragments in `cache/`, then renders them using Mako templates into `output/`. The `output/` directory is what gets deployed.

Supported post formats (configured in `conf.py` `COMPILERS`):
- `.md` / `.mdown` — Markdown
- `.rst` / `.txt` — reStructuredText
- `.org` — Emacs Org-mode (via custom plugin)
- `.html` — raw HTML passthrough

Each post has a paired `.meta` file for metadata (title, slug, date, tags) when using two-file format.

Teaser delimiter: add `<!-- TEASER_END -->` in Markdown/HTML posts, or the `{{{TEASER_END}}}` org macro in `.org` posts (defined in `init.el` as `#+HTML:<!-- TEASER_END -->`), to split index previews from full content.

### Org-mode plugin

`plugins/orgmode/orgmode.py` implements a Nikola `PageCompiler` that shells out to `emacs --batch` to export `.org` files to HTML. The Emacs init is at `plugins/orgmode/init.el`, which loads `org-mode` and `htmlize` from MELPA (cached in `plugins/orgmode/elpa-<version>/`). Emacs must be installed on the system for `.org` posts to build.

### Branch strategy

- `src` — source branch (posts, pages, conf.py, themes, plugins)
- `main` — generated output branch (GitHub Pages deployment target)

`nikola github-deploy` (i.e. `make github-deploy`) commits the `src` branch, builds, then force-pushes `output/` to `main`.

### Themes

Active theme: `sdowney-tailwind` (in `themes/sdowney-tailwind/`). The inheritance chain is:

```
sdowney-tailwind  →  nikola-tailwind-blog  →  nikola-tailwind-base  →  nikola base
```

- `nikola-tailwind-base` — Nikola's Mako base templates rewritten with Tailwind CSS utility classes. `theme.css` is intentionally empty (overrides Nikola's conflicting default stylesheet).
- `nikola-tailwind-blog` — blog-specific templates (index, post, tags, lists) built on the base.
- `sdowney-tailwind` — personal overrides. The only template override is `base_helper.tmpl`, which redefines `html_stylesheets()` to load Tailwind CSS via CDN (`https://cdn.tailwindcss.com?plugins=typography`), configure the Tailwind theme (fonts: Source Sans 3, Source Code Pro), and load Font Awesome and Google Fonts.

Styling notes:
- Tailwind is loaded from CDN with the `typography` plugin; post content sits inside `prose prose-lg prose-indigo` classes.
- Code block layout (org-mode `.org-src-container`, `pre.example`) is handled by `themes/nikola-tailwind-base/assets/css/tailwind-base.css` using CSS custom properties for colors.
- Dark-mode code colors come from `/assets/css/modus-vivendi-tinted.css` (loaded unconditionally).
- The JS in `base.tmpl` injects language labels and copy buttons on all code blocks at runtime.

Other themes in `themes/` (foundation6, sdowney-foundation6, sdowney-bootblog4, bootstrap variants) are inactive.

### Key configuration

`conf.py` is the Nikola configuration file. Important non-default settings:
- `PRETTY_URLS = True` — posts at `/posts/slug/` not `/posts/slug.html`
- `STRIP_INDEXES = True` — `/posts/slug/index.html` served as `/posts/slug/`
- `INDEX_TEASERS = True` — index pages show teasers, not full posts
- `USE_KATEX = True` — math rendering
- `GITHUB_SOURCE_BRANCH = 'src'`, `GITHUB_DEPLOY_BRANCH = 'main'`

### Linting

Pre-commit hooks (`make lint`):
- `trailing-whitespace`, `end-of-file-fixer` — excluded from `pages/`, `posts/`, `themes/`
- `check-yaml` — YAML validation
- `clang-format` — C/C++ formatting
- `gersemi` — CMake formatting
- `markdownlint` — Markdown linting (MD013 line-length disabled)
- `codespell` — spell checking (ignore list: `.codespell_ignore`)
- `checkmake` — Makefile linting

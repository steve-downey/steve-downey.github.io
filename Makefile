#! /usr/bin/make -f
# Makefile                                                       -*-makefile-*-
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

export
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

PYEXECPATH := $(shell which python3.14 || which python3.13 || which python3.12 || which python3.11 || which python3.10 || which python3.9 || which python3.8 || which python3)
PYTHON := $(notdir $(PYEXECPATH))
VENV := .venv
UV := $(shell command -v uv 2> /dev/null)
ACTIVATE := $(UV) run
PYEXEC := $(UV) run python
MARKER=.initialized.venv.stamp

PRE_COMMIT := $(UV) run pre-commit
NIKOLA := $(UV) run nikola

_output_path := ./output/
_cache_path := ./cache/

# Tailwind config must be defined before any target that lists
# $(TAILWIND_OUTPUT) as a prerequisite (e.g. `compile`). Make expands a
# rule's prerequisites when the rule is read, so a later definition would
# expand to empty and silently drop the CSS build from the graph.
TAILWIND_THEME ?= 4

ifeq ($(TAILWIND_THEME),3)
TAILWIND_VERSION := 3.4.17
TAILWIND_INPUT := themes/nikola-tailwind3-base/tailwind.input.css
TAILWIND_EXTRA := --config themes/nikola-tailwind3-base/tailwind.config.js
TAILWIND_OUTPUT := themes/nikola-tailwind3-base/assets/css/tailwind.css
else
TAILWIND_VERSION := 4.3.0
TAILWIND_INPUT := themes/nikola-tailwind4-base/tailwind.input.css
TAILWIND_EXTRA :=
TAILWIND_OUTPUT := themes/nikola-tailwind4-base/assets/css/tailwind.css
endif

TAILWIND := .tools/tailwindcss-$(TAILWIND_VERSION)
TAILWIND_URL := https://github.com/tailwindlabs/tailwindcss/releases/download/v$(TAILWIND_VERSION)/tailwindcss-linux-x64

_tmpl_files := $(shell find themes -name '*.tmpl' 2>/dev/null)


.update-submodules:
	git submodule update --init --recursive
	touch .update-submodules

.gitmodules: .update-submodules

default: test
.PHONY: default

wg21.bib:
	curl https://wg21.link/index.bib > wg21.bib

.PHONY: nikola
nikola: venv wg21.bib

.PHONY: compile
compile:  ## Compile the project
compile: nikola $(TAILWIND_OUTPUT)
	$(NIKOLA) build

.PHONY: test
test: compile ## Rebuild and run tests
	$(NIKOLA) check -f # too many broken links today to test with -l :sad:

.PHONY: nikola-check
nikola-check:
	$(NIKOLA) check $(_NIKOLA_CHECK_ARGS)

.PHONY: test-files
test-files: compile ## Test files in output
test-files: _NIKOLA_CHECK_ARGS:=-f
test-files: nikola-check

.PHONY: test-links
test-links: compile ## Test remote Links in output
test-links: _NIKOLA_CHECK_ARGS:=-l -r
test-links: nikola-check

.PHONY: test-local-links
test-local-links: compile ## Test local links in output
test-local-links: _NIKOLA_CHECK_ARGS:=-l
test-local-links: nikola-check


.PHONY: github-deploy
github-deploy: ## Deploy to github ghpages
github-deploy: compile test
	$(NIKOLA) github_deploy

.PHONY: prod-deploy
prod-deploy: ## Deploy TO sdowney.org hosted at panix
	rsync -avl output/ sdowney@panix3.panix.com:~/public_html/

.PHONY: clean
clean:  ## Clean the build artifacts
	$(NIKOLA) clean

.PHONY: realclean
realclean: ## Delete all produced artifacts
	rm -rf $(_output_path)
	rm -rf $(_cache_path)
	rm -rf .tools
	rm -f $(TAILWIND_OUTPUT)

.PHONY: env
env:
	$(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))

.PHONY: all
all: compile

.PHONY: venv
venv: ## Create python virtual env
venv: $(VENV)/$(MARKER)

.PHONY: clean-venv
clean-venv:
clean-venv: ## Delete python virtual env
	-rm -rf $(VENV)

realclean: clean-venv

.PHONY: show-venv
show-venv: venv
show-venv: ## Debugging target - show venv details
	$(PYEXEC) -c "import sys; print('Python ' + sys.version.replace('\n',''))"
	@echo venv: $(VENV)

uv.lock: pyproject.toml
	$(UV) lock

$(VENV):
	$(UV) venv --python $(PYTHON)

$(VENV)/$(MARKER): uv.lock | $(VENV)
	$(UV) sync
	touch $(VENV)/$(MARKER)

.PHONY: dev-shell
dev-shell: venv
dev-shell: ## Shell with the venv activated
	$(ACTIVATE) $(notdir $(SHELL))

.PHONY: bash zsh
bash zsh: venv
bash zsh: ## Run bash or zsh with the venv activated
	$(ACTIVATE) $@

# TAILWIND_* variables are defined near the top of this file (before the
# `compile` target) so $(TAILWIND_OUTPUT) is in scope when that rule is read.

$(TAILWIND):
	mkdir -p .tools
	curl -sL $(TAILWIND_URL) -o $@
	chmod +x $@

.PHONY: build-css
build-css: $(TAILWIND_OUTPUT)  ## Build Tailwind CSS from source

$(TAILWIND_OUTPUT): $(TAILWIND) $(TAILWIND_INPUT) $(_tmpl_files)
	$(TAILWIND) $(TAILWIND_EXTRA) -i $(TAILWIND_INPUT) -o $@ --minify

MODUS_CSS_DIR := themes/sdowney-tailwind/assets/css

.PHONY: strip-modus-css
strip-modus-css: ## Clean modus CSS files (legacy fallback; prefer M-x secretaire-css-export)
	@for f in $(MODUS_CSS_DIR)/modus-*.css; do \
		[ -f "$$f" ] || continue; \
		changed=0; \
		if grep -q '<style\|<!--\|-->\|</style>' "$$f"; then \
			echo "Stripping HTML wrappers from $$f"; \
			sed -i '/^<style/d; /^[[:space:]]*<!--[[:space:]]*$$/d; /^[[:space:]]*-->[[:space:]]*$$/d; /^<\/style>/d' "$$f"; \
			changed=1; \
		fi; \
		if grep -qP '^\s*(?:/\*\s*)?(?:body|a(?::hover)?)\s*\{' "$$f"; then \
			echo "Stripping base element rules from $$f"; \
			$(PYEXEC) plugins/orgmode/strip_base_rules.py "$$f"; \
			changed=1; \
		fi; \
		if [ "$$changed" = "0" ]; then echo "$$f: already clean"; fi; \
	done

.PHONY: lint
lint: venv
lint: ## Run all configured tools in pre-commit
	$(PRE_COMMIT) run -a

.PHONY: lint-manual
lint-manual: venv
lint-manual: ## Run all manual tools in pre-commit
	$(PRE_COMMIT) run --hook-stage manual -a


ifeq ($(UV),)
define install_uv_cmd
pipx install uv
endef

define uv_error_message

'uv' command not found.
Please install uv or set the UV variable to the path of the uv binary.
The makefile target "install-uv" will run ``$(install_uv_cmd)''
endef

$(error "$(uv_error_message)")
endif

.PHONY: install-uv
install-uv: ## install uv via `pipx install uv`
	$(install_uv_cmd)

# Help target
.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[.a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'  $(MAKEFILE_LIST) | sort

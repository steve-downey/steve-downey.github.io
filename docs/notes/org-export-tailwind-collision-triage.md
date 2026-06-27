# Org Export / Tailwind Collision Triage

This note classifies the overlap between Org-exported content classes and
Tailwind CSS class selectors found in the WCTM repo.

Related scratch reports:

- [Full class frequency report](../../tmp/org_export_class_frequency.md)
- [Tailwind collision candidates](../../tmp/org_export_tailwind_collision_candidates.md)
- [High-risk Tailwind collision candidates](../../tmp/org_export_tailwind_high_risk_candidates.md)

## Triage categories

### Harmful collisions

These are exported structural wrapper classes whose names collide with Tailwind
utilities that mean something else.

- `outline-2`
- `outline-3`
- `outline-4`
- `outline-5`

Why they matter:

- Tailwind interprets `.outline-*` as outline-width utilities.
- Org exported these as structural section wrapper classes.
- The result was visible boxes around section wrappers.

Action:

- Namespace these at the exporter level, e.g. `ox-nikola-outline-*`.
- Keep the temporary compatibility patch in `files/assets/css/custom.css`
  until regenerated content no longer emits the old `outline-*` classes.

### Benign semantic overlap

These collide by name with Tailwind utilities, but the meaning is effectively
the same.

- `underline`

Why it is likely fine:

- In Org HTML, this comes from inline text-markup handling via
  `org-html-text-markup-alist` / `org-html-underline`.
- Tailwind's `.underline` utility also means underlined text.

Action:

- No urgent renaming required.
- Only revisit if a visual regression shows that Tailwind's implementation is
  not compatible with Org's expected underline semantics.

### Expected namespaced classes

These are not current collision problems and should generally be left alone.

- `org-*`
- `src-*`
- `section-number-*`

Why they are fine:

- They are already namespaced.
- In practice they are used for Org export structure or syntax highlighting.
- They do not materially overlap with Tailwind utility naming.

Action:

- Do not rename these just because they appear in the raw frequency report.

## Practical guidance

When auditing Org-exported classes in this repo, use this rule:

1. Structural wrapper classes should be namespaced with `ox-nikola-*`.
2. Semantic inline markup that already matches Tailwind semantics can stay.
3. Existing `org-*` syntax-highlighting classes are expected and not priority work.

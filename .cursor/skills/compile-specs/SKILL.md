---
name: compile-specs
description: >-
  Compiles design-spec, build-spec, screens-status, moonchild, and
  build-status from the PRD plus design exports. Use for the one-time
  compile-specs pass, Phase 0 spec compile, or when the user mentions
  the compile-specs master prompt.
---

# Compile specs

One strong-model pass per product clone. **Do not** use a cheap model.

## Before you start

1. `docs/PRD.md` finished (no `<!-- TEMPLATE_PLACEHOLDER -->`).
2. Design artifacts in `docs/design-exports/` or MCP-linked in `docs/moonchild.md`.
3. Identity set (`npm run init-app`) if the final name is known.

## Do this

1. Read **all** of `docs/recipes/compile-specs.md`.
2. Copy **only** the Master prompt block into this chat (or a new strong-model
   chat). Do not paraphrase it.
3. Follow that prompt. Do not invent product scope or screens.

## Config trap

`PURCHASES_MODE` is a **standalone export** in `apps/mobile/lib/app-config.ts`,
not a key on `APP_CONFIG`. `APP_CONFIG` has only `STORAGE` and `MONETIZATION`.
Leave `PURCHASES_MODE` as `'mock'` until live keys exist.

## After

Planning model mails the first incomplete build-spec task. Implementers
follow `.cursor/skills/mailbox/`.

## Source

`docs/recipes/compile-specs.md` — the recipe is authoritative. Full loop:
`docs/recipes/product-pipeline.md`.

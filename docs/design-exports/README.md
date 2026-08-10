# Design exports

Drop design-tool exports for this product clone here (or in subfolders), then
point `docs/moonchild.md` at this path.

## What to put here

- Screen / flow frames (PNG, PDF, or the tool’s export format)
- Design-system / token exports if the tool provides them
- Anything an agent needs when MCP pull is unavailable

## Naming (suggested)

```
docs/design-exports/
  README.md                 ← this file
  onboarding-01.png
  home.png
  settings.png
  …
```

Or group by flow: `docs/design-exports/onboarding/…`.

## After exporting

1. Fill `docs/moonchild.md` — tool name + **Committed exports** path
   (`docs/design-exports/`).
2. Update `docs/screens-status.md` — each screen’s **Designed** = `yes` and
   artifact name/path.
3. Run the one-time compile pass:
   `docs/recipes/compile-specs.md`.

Do not invent layouts from the PRD alone. Agents implement from these
artifacts (or an MCP pull of the same screens).

# Design exports

Drop design-tool exports for this product clone here (or in subfolders).
A named file in this folder is the implement gate for a new screen.

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

Claude `/app-contract` reads these files and writes `docs/CONTRACT.md`. Cursor
`/app-critic` then writes `docs/CRITIC.md`. Do not invent layouts from the
PRD alone. Agents implement from these artifacts (or an MCP pull of the
same screens).

A `design.md` or `navigate.md` in this folder is a design-tool artifact, not
the build contract. The build contract is `docs/CONTRACT.md`.

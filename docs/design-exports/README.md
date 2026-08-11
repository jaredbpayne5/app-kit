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

Put the exports here, then run the one-time compile pass:
`docs/recipes/compile-specs.md`.

**You do not hand-fill `docs/moonchild.md` or `docs/screens-status.md`.** The
compile pass writes both from what it finds here (or via the design tool's MCP)
— that is steps 1 and 2 of its master prompt. Filling them yourself duplicates
the work and risks disagreeing with the design spec compiled in the same pass.

Optional: if you already know the tool name and project ids, jotting them into
`docs/moonchild.md` first gives the compile pass a head start. It will still
verify and rewrite the file.

Do not invent layouts from the PRD alone. Agents implement from these
artifacts (or an MCP pull of the same screens).

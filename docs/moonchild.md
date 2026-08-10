<!-- TEMPLATE_PLACEHOLDER -->

# Design tool of record

Which design tool and project this product clone uses, and/or where committed
exports live. The filename is historical; this works for Moonchild, Figma, or
another tool.

Until the sentinel above is removed, treat this clone as **not linked** to a
design source. Agents must still verify MCP tools respond in-session (when
used) or that export paths exist before any UI pull (`AGENTS.md`).

## Tool

- **Name:** _(e.g. Moonchild, Figma)_
- **Notes:** _

## Design system

- **Name:** _
- **Id / URL:** _

## Scene / file (flows / screens)

- **Name:** _
- **Id / URL:** _

## Committed exports (if no MCP)

- **Path in repo:** `docs/design-exports/` _(default; see that folder’s README)_
- **What is included:** _(frames, tokens, etc.)_

## Machine checklist

- [ ] Design-tool MCP connected in Cursor for this workspace (if using MCP)
- [ ] Design-tool MCP connected in Claude Code (if you use it)
- [ ] Can list/fetch this design system via MCP, **or** exports are present at
      the path above
- [ ] Can fetch at least one frame via MCP, **or** that frame’s export is in
      the repo

See `docs/recipes/product-pipeline.md` for the full PRD → design → specs → code
loop.

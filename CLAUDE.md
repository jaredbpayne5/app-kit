@AGENTS.md

# Claude's seat

`AGENTS.md` (imported above) is the project: invariants, stack, seams,
security, roles, and the Ask-before boundary. It always wins. This file adds
only what is specific to operating the Claude seat.

Claude's seat is **thinker**. Cursor's seat is **builder**. Matt opens
**shipper** on purpose. Both agents hold the same working copy.

`AGENTS.md` → Roles holds the allowed and forbidden lists for this seat. Do
not restate them here. Claude's `/` menu is `.claude/skills/`. Do not tell
anyone to open a Cursor skill file.

`/app-architecture` stays on disk for a shipped app that needs
`ARCHITECTURE.md`. It is not a first-app stage. Do not run it on the
v1 path.

Work lives in git (branch + commit). Do not start shipper. Do not review or
rubber-stamp this chat's own output — if this chat wrote it, independent
review is blocked.

## When to stop and ask the human

- Anything on the `AGENTS.md` "Ask before" list.
- A product or design requirement that needs a backend, accounts, or
  server-side sync.
- A material conflict between `AGENTS.md`, `docs/PRD.md`, a named export in
  `docs/design-exports/`, and `docs/CONTRACT.md`.
- `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`.
- A missing or unfetchable named export for a screen to be planned.
- The last `**Verdict:**` line in `docs/CRITIC.md` is not `PASS`, and the
  user asked for `/app-backlog`.

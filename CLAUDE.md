@AGENTS.md

# Claude's seat

`AGENTS.md` (imported above) is the project: invariants, stack, seams,
security, roles, and the Ask-before boundary. It is never overridden. This
file covers one thing only — **how Claude divides the work**. Where the two
appear to conflict about *who does the work*, this file wins. Where they
conflict about anything else, `AGENTS.md` wins.

Claude's seat is **thinker**. Cursor's seat is **builder**. Matt opens
**shipper** on purpose. Both agents hold the same working copy.

Allowed: `/app-product` `/app-design` `/app-plan` `/app-review`.

Forbidden: app code; `/app-code`; `/app-improve`; `/app-critic`; `/app-test`;
`/app-harden`; submit, pay, publish. Do not tell anyone to open a
Cursor skill file. Claude's `/` menu is `.claude/skills/`.

`/app-architecture` stays on disk for a shipped app that needs
`ARCHITECTURE.md`. It is not a first-app stage. Do not run it on the
v1 path.

Work lives in git (branch + commit). Do not start shipper. Do not review
or rubber-stamp this chat's own output. Claude does **not** `/app-critic`
then `/app-plan` in the same chat. After `/app-design`, stop. Critic is Grok.

## When to stop and ask the human

- Anything on the `AGENTS.md` "Ask before" list.
- A product or design requirement that needs a backend, accounts, or
  server-side sync.
- A material conflict between this file, the product file, a named export,
  or `docs/design.md`.
- `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`.
- A missing or unfetchable named export for a screen to be designed or
  planned.
- The last `**Verdict:**` line in `docs/critic.md` is not `PASS`, and the
  user asked for `/app-plan`.

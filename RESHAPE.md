# app-kit reshape plan

**Status:** Pass 1–2 done. Letter is a pager; mailbox-check cluster deleted and unwired; `u4-check` unplugged from `check`; fail-proof mailbox section cut. Secret-deny proof passed (35/35). `AGENTS.md` thinned (roles in, six-doc / mailbox loop / product-vs-template out). `CLAUDE.md` and `.cursor/rules/implementation-workflow.mdc` no longer teach mailbox. Full `npm run check` is still red only because untracked `blueprint-main/` and `factory-main/` research copies sit in the tree. Passes 3–5 not started.

**This repo:** `/Users/matt/Development/mobile-apps/app-kit`  
**GitHub:** `https://github.com/jaredbpayne5/app-kit.git`  
**Do not push to:** `jaredbpayne5/new-app`  
**Leave untouched:** `/Users/matt/Development/mobile-apps/new-app`

`app-kit` is a git clone of `new-app` at commit `48cc955`. Origin is the new GitHub repo (verified). The Expo app, seams, tests, and store scripts stay. The mailbox and six-doc authority stack get replaced.

Impact brief (read beside chat):  
`/Users/matt/.cursor/projects/Users-matt-Development-mobile-apps-app-kit/canvases/reshape-impact-brief.canvas.tsx`

---

## Locked workflow

Do not rename these unless Matt asks.

### Roles (privilege lanes — not a step per hat)

| Role | Seat | Allowed skills | Forbidden |
|---|---|---|---|
| **thinker** | Claude Code | `/product` `/design` `/design-review` `/plan` `/harden` `/as-built` | App code. `/task-to-pr`. `/improve`. Submit, pay, publish. |
| **builder** | Cursor | `/task-to-pr` `/improve` | Rewrite product file or `design.md` (except Open questions). `/ship`. Invent a screen with no export. |
| **shipper** | Matt opens this on purpose | `/ship` only | Feature work. Redesigning the product. Auto-start from the pager. |

**Shared** (either seat): `/review` `/test` on the *other* agent's work. A chat must not review what it just wrote.

Matt still presses paid / public buttons. The pager never starts shipper.

`/` means **run this skill** (a playbook). Seats are fixed. The agent picks the next allowed skill.

### First-app movie

1. Clone this kit. Claude (thinker) → `/product` until the product template is filled. Pager idle.
2. Matt takes that file to a UI/UX tool (Moonchild or other). Drops exports in `docs/design-exports/`.
3. New thinker chat → `/design` (how we build it: storage, purchases, failures, INV/AC). Cites export frames. No app code.
4. New thinker chat → `/design-review` then `/plan`. Attack holes. If solid, commit task 1. Pager → builder.
5. Cursor (builder) → `/task-to-pr` + `/test`. One task. Named frame. Commit. Pager → thinker.
6. The other seat `/review` (and `/test` if needed) on `git diff main...branch`. Approve → next task. Revise → builder. Deny → stop.
7. After the last feature: thinker `/harden` (whole-app audit). Then Matt opens `role: shipper` → `/ship`.

### Pager vs letter

- **Pager** (doorbell): `owner` (thinker \| builder), `status` (ready \| review \| idle), `seq`. Nothing else. Never auto-pages shipper.
- **Letter:** git (branch + commit). Product file, `docs/<slug>/design.md`, the task, the code.
- `.ai/current-task.md` must not be the source of requirements.

### Cheap models

Opus may spawn Sonnet for mechanical docs. Grok may spawn Composer 2.5 Fast for mechanical code. A chat must not review code it just wrote.

---

## Reuse (do not rebuild the phone)

About **75%** of factory-build time is already here. Clone-and-reshape, do not start an empty Expo repo.

| Layer | Reuse | Action |
|---|---|---|
| `apps/mobile/lib/` seams + tests | ~90% | Keep as-is |
| Expo shell, `ui/`, NativeWind, Router | ~85% | Keep. Demo screens go when a real product exists |
| Store, lander, `init-app`, session, doctor, preflight | ~80% | Keep. Become shipper `/ship` + recipes |
| ESLint seams, test, verify, gitleaks, CI | ~70% | Keep gates. Drop `mailbox-check` from `check`. Unplug `u4-check` from `check`, keep the file. Split `fail-proof-check`: keep secret/design-lint proofs on `check`; cut only the mailbox section |
| `docs/recipes/` (store, payments, EAS, lander) | ~80% | Keep on-demand. Drop compile-specs / product-pipeline as bosses |
| AGENTS.md, skills, hooks, mailbox, spec stack | ~20% | Keep seam table, ask-before, deploy/secret hook idea. Rewrite the rest |

**Do not rewrite** `storage.ts`, `purchases.ts`, or other working seams “to match the new process.”

Hands off unless a pass names the file: Expo app, NativeWind, `ui/`, Router, seam tests, store/lander/session/doctor/preflight scripts, secret + deploy guards, gitleaks, `docs/design-exports/`, `docs/PRD.md` template, `docs/CAPABILITIES.md`.

---

## Hygiene (no orphans)

If a pass unplugs a file from daily use, that **same pass** must delete it, rewrite it, or mark it “dies in Pass N” in the leftover list below.

Danger zone — mixed files (mailbox sits next to real safety). Edit only mailbox-named bits. After touching them, prove a fake secret is still denied:

- `scripts/lib/fail-proof-checks.test.sh`
- `.claude/settings.json`
- `.cursor/hooks.json`
- `scripts/lib/guard-sensitive-paths.sh`

Every pass that deletes a `.sh` file must also edit `scripts/dev/shellcheck-guards.sh`.

Do not start product UI screens until Pass 5 rewrites `pull-design` and `design-lint`. Existing demo routes stay.

---

## Owner-word tripwire

Today waiters only wake if `owner` is `cursor` / `claude` and status is `ready-for-cursor` / `ready-for-review`.

Do **not** rename those words to `thinker` / `builder` and `ready` / `review` / `idle` until Pass 4 updates `wait-for-mail.sh` and `wait-for-review.sh` — unless Pass 1 updates the waiters in the same chat.

Pass 1 thins the **letter** (stop using `.ai/current-task.md` as the work order). Keep doorbell vocabulary until the waiters change.

---

## Remaining passes (separate chats — do not one-shot)

Credit warning: one prompt that “installs the whole workflow” will burn context and make a mess. One pass per chat.

1. **Strip mailbox as source of truth (cluster)** — **Done.** Letter thinned. mailbox-check + adapters deleted and unwired. `mailbox-check` dropped from `check`. `u4-check` unplugged (file kept). Fail-proof mailbox section cut. Deny list + `guard-sensitive-paths` updated. Owner words unchanged.
2. **Thin `AGENTS.md`** — **Done.** Kept stack, seam table, ask-before, no-backend. Removed six-doc authority chain, product-vs-template mode, mailbox loop. Added role allow-lists. Rewrote `CLAUDE.md` and `.cursor/rules/implementation-workflow.mdc` so they stop teaching mailbox. Dropped the mailbox-format freeze from `REPO-UPGRADE.md`.
3. **Add role files + shared `skills/`** — Same markdown for Claude Code and Cursor. `/product` uses the existing PRD template. Delete old mailbox / write-mailbox-task / review-cursor / compile-specs skills when the new ones exist. Keep `maestro-e2e`. Fold `store-preflight` into `/ship` or keep until `/ship` exists.
4. **Hooks** — Keep secret + deploy guards (shipper backstop on Cursor). Shrink or remove wait-for-mail-as-task-bus. Same pass: `/watch`, `/stop`, `.ai/.watching`, `.ai/.review-seen`, gitignore comments for those. Then (and only then) rename pager owner/status words if not done in Pass 1.
5. **Docs** — Keep `docs/recipes/` and `docs/design-exports/`. Demote or delete `design-spec` / `build-spec` / `build-status` / `screens-status` / `moonchild.md` as bosses. Same pass: rewrite `pull-design` and `design-lint` so new screens gate on a named export in `docs/design-exports/` (Moonchild optional). Rewrite `README.md` and `docs/recipes/product-pipeline.md` to the first-app movie. Update `doctor.sh` warnings, `init-app` “Next” blurb, `compile-specs.md`, design-exports README.

---

## Leftover list (dies in which pass)

| File | Dies / rewritten in |
|---|---|
| `.ai/current-task.template.md` | Thinned in Pass 1; delete in Pass 3 with mailbox skills |
| `scripts/lib/u4-fail-proof.sh` | Unplugged from `check` in Pass 1; keep file (run when changing hooks/CI) |
| `blueprint-main/`, `factory-main/` | Untracked research copies; they break `npm run check`. Move or gitignore — not a Pass 1 file edit |
| `CLAUDE.md`, `.cursor/rules/implementation-workflow.mdc` | Rewritten in Pass 2 |
| `AGENTS.md` “until shared files exist” sentence | Dies in Pass 3 when skills land |
| `.cursor/commands/watch.md`, `stop.md` | Pass 4 |
| `README.md` | Pass 5 |
| `REPO-UPGRADE.md` | Mailbox-format freeze dropped in Pass 2; leftover U6/U1b copy is Pass 5 |
| `scripts/dev/doctor.sh` placeholder warnings | Pass 5 |
| `scripts/dev/shellcheck-guards.sh` file list | Every pass that deletes a `.sh` |
| `.gitignore` watcher comments | Pass 4 |

Construction zone is expected until Pass 5. That is not a license to leave dead scripts.

---

## Source conversation (for a new agent)

This plan came from a review of `new-app` vs `blueprint-main` (Owain Lewis process skills) vs `factory-main` (agent control plane). Decisions:

- Git + branch + diff is the handoff, not a mailbox essay.
- Blueprint skills are the playbooks; roles are only thinker / builder / shipper.
- Design-tool exports stay first-class. Moonchild is optional.
- `/product` not `/spec`. `/design-review` not `/architecture-review`. `/harden` is a thinker audit before shipper.
- Independent review = new thinker session, not a fourth job title.

Older canvas (other workspace):  
`/Users/matt/.cursor/projects/Users-matt-Development-mobile-apps/canvases/blueprint-factory-review.canvas.tsx`

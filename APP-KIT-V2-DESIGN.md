# App-Kit — remaining work

What is left to build, and what we have decided not to build. Everything that
was in this file's previous life as a V2 migration spec is done and has been
removed; read `git log` for that history.

Authority still lives where it always did: `AGENTS.md`, then `docs/PRD.md`,
then a named export in `docs/design-exports/`, then `docs/CONTRACT.md`, then the
source. This file is a backlog. It is not an authority, and nothing here
overrides those.

---

## 1. Deferred by choice — automation

These only remove Matt as the scheduler. None of them improves what the agents
produce, and each is actively harmful before the proof gates in section 2 are
deep enough to catch what an unattended loop would miss.

| # | Item | Note |
| --- | --- | --- |
| 1 | **Retry with a fresh context.** On a red gate, compact the failure trace, discard the polluted session, retry. Cap at 2–3 attempts, then escalate. | Pure waste without deep gates — retrying against weak checks just relaunders the same failure |
| 2 | **Keep-working enforcement.** Refuse to end a turn with no proof. | Mechanism differs per tool; see section 5 |
| 3 | **Read-only reviewer subagent.** `readonly: true` in `.cursor/agents/*.md`, plus a post-flight dirty-tree check. | Makes "must not review its own diff" mechanical instead of prose |
| 4 | **Stage printer.** Read-only, derived from files: PRD sentinel, presence of `CONTRACT.md` / `CRITIC.md` / `BACKLOG.md`, the last `**Verdict:**` line, the `- [ ]` count. | Useful standalone for resuming after a break. The cheapest item here |
| 5 | **Driver.** Reads stage, spawns one fresh `claude -p` / `agent -p` per unit with the right skill, parses the verdict, writes receipts, commits with an `Agent:` trailer, enforces caps. | The real commitment. Most moving parts, most maintenance as CLI flags churn |
| 6 | **Run report and desktop notification** on block or completion (`osascript`). | Only matters for unattended overnight runs |
| 7 | **Optional:** one council pass (draft/vote/refine) on `CONTRACT.md` and `BACKLOG.md` only, never per job. Worktree isolation for risky jobs. | Council costs 3–5×. Worktrees carry the auto-deletion footgun in section 5 |

Stage must stay **derived, never stored**. A committed turn file desyncs from
reality; the four signals above cannot lie.

---

## 2. Blocked on real inputs

Not deferred by choice — these cannot be built or tested until an actual
product exists in the repo. Today `docs/PRD.md` still holds its
`TEMPLATE_PLACEHOLDER` sentinel, `docs/design-exports/` holds only its README,
and there is no `docs/BACKLOG.md`.

Writing a gate with nothing to run it against produces a check that has never
fired, which is the fake-gate failure mode this repo exists to avoid.

| Item | Needs first |
| --- | --- |
| **Readiness gate** — a pass over PRD + exports returning `READY` or `BLOCKED` with batched written questions, never a conversation | A filled `docs/PRD.md` |
| **Maestro on the critical path** for `flow`-tier jobs. `--allow-skip` must be forbidden unattended | A `docs/BACKLOG.md` with flow-tier jobs |
| **Visual conformance** — `npm run screenshots`, then compare against the named export frame | Real export frames |
| **Token sync** — design tool export → `global.css` → `gen-theme` | A token export (JSON or CSS) committed to `docs/design-exports/` |

Both design-facing items must stay **tool-agnostic**: read the committed file
in `docs/design-exports/`, never a vendor API. An MCP pull is an optional fast
path when a tool happens to offer one, never the contract.

---

## 3. Open smaller items

| Item | Why it is still open |
| --- | --- |
| **Preflight gate-6 additions.** Wire `expo-sdk-check.sh` and `audit-report.sh` into `scripts/store/review-preflight.sh` at gate 6. Both scripts exist and are CI-only today; the gate 4/6 split is already there | Carried over from the old spec. Never done |
| **A11y depth.** `design-lint.sh` has a warn-only check that a file rendering something tappable offers some accessibility affordance. Per-element labels, roles, and touch-target sizes are not checked | The warn is a floor, not an audit. See `docs/recipes/accessibility-audit.md` for the manual pass |
| **`backlog-lint` strictness.** Warn-only today; `--strict` fails | Cannot be tightened honestly until a real `docs/BACKLOG.md` proves the schema is right rather than friction |
| **Coverage.** `npm run test:coverage` reports on `lib/` only, with no threshold, deliberately — a number to hit invites padding tests | Revisit only if a real untested branch ships a bug. A mutation spot-check would prove more than a percentage |
| **Recipe gaps.** No offline-first recipe. ASO/listing and EAS diagnosis are partly covered by `app-store.md`, `play-store.md`, and `eas-build.md` | Long tail, weakest payoff per item |
| **Stale guard wording.** `guard-protected-files.sh` and `guard-shell.sh` still say "mailbox check" in their denial messages, naming a system that no longer exists | Cosmetic. Both are protected files, so Matt edits them by hand |

---

## 4. Not building

Rejected on evidence, not taste. Re-opening any of these needs a new reason,
not a new conversation.

- **Deep links as an automation trigger.** `cursor://` deep links never
  auto-execute — the prompt is pre-filled and a human must confirm. A
  file-less handoff loop built on them cannot work.
- **Agents launching each other.** Two agents calling each other reciprocally
  has no arbiter, so nothing can enforce a cap or a cost ceiling. One driver
  spawns; agents never spawn each other.
- **A committed turn file** (`docs/current_turn.txt` or any equivalent), or a
  workflow state machine in JSON. Derive stage instead.
- **Falsified commit authorship.** `--author="Claude Opus …"` lies about who
  wrote the code. `Agent:` / `Co-authored-by:` trailers give the same
  filterable log honestly.
- **`git add .` per turn.** Stages secrets, `ios/`, and `android/`. Explicit
  paths only.
- **A tracked attention file** such as `⚠️_ATTENTION_REQUIRED.md`. Merge
  hazard and repo clutter; a notification plus a gitignored report does the
  same job.
- **tmux panes for watching.** `--output-format stream-json` to a log file is
  strictly better.
- **A second job store.** `docs/BACKLOG.md` is the only job list. No ticket
  database, no `tasks/` directory.
- **YOLO / unrestricted permissions** on a signing-adjacent Mac. Use
  `dontAsk` plus allowlists plus `permissions.deny`.
- **A backend, accounts, or server-side sync.** `AGENTS.md` outranks any
  product file that asks for one: stop and discuss.
- **Always-on skill packs** from other repos. They contradict this stack
  (NativeWind v5, `@expo/ui`, React Query) and cost context on every turn.
- **Any script whose job is reminding an agent of something `npm run check`
  could fail on.**

---

## 5. Verified constraints

Expensive to rediscover, so recorded here. Re-verify before building on any of
it, since both CLIs churn.

- **`preToolUse` enforces `deny` but ignores `ask`.** A guard that returns
  `ask` on a tool write is a gate that never fires.
  `beforeShellExecution` / `beforeMCPExecution` enforce both. Any gate the
  loop depends on needs an assertion that fails when *enforcement* is absent,
  not merely when the script's output changes.
- **Cursor's `stop` hook cannot block.** Its only output is
  `followup_message`, which auto-submits as the next user message.
  `loop_limit` defaults to 5. Claude's `Stop` hook exit 2 is a true block.
- **`failClosed` defaults to `false`** in `.cursor/hooks.json`. Set it only on
  hooks whose intent is fail-closed; guards deliberately written to fail open
  should stay that way.
- **Cursor skills do not honor `allowed-tools` or `model`.** Restricting
  either means a subagent, not a skill.
- **Subagent nesting stops at two levels.** Main and its direct subagents may
  spawn; a subagent's subagent may not.
- **Skill names collide with bundled ones.** Every skill here is prefixed
  `app-` for that reason; a project skill overrides a bundled skill's *name*
  but not its *aliases*. Keep the prefix on anything new.
- **`cursor.worktreeMaxCount` defaults to 25 per machine**, and cleanup
  deletes worktrees created outside the manager, including plain
  `git worktree add`.
- **Composer 2.5 carries no token rate** on any plan. Delegating mechanical
  work to it is an economic decision, not a stylistic one.
- **Cursor Automations are cloud-only.** A recurring local run means OS cron
  or an in-session loop.
- **Claude's `--bare` skips hooks, skills, and `CLAUDE.md`** and wants an API
  key instead of the subscription. Do not use it.
- **No pooled cost ceiling.** Subagents bill independently;
  `total_cost_usd` per invocation is the only hard cap available.

---

## 6. Permanently human

Not a backlog. These never move to an agent, however good the gates get.

Spend (`eas build`, `eas submit`, `eas update`, `prebuild`) · publish
(`store:push`, `web:deploy`, `domain-attach`) · `git push` · app identity and
bundle IDs · production keys · adding a backend · overruling a critic `FAIL` ·
final aesthetic sign-off.

The ceiling on all of this is gate depth. Autonomy amplifies whatever the
checks miss, so proof depth is not polish — it is the thing that makes a
driver safe rather than reckless. The output is an app *awaiting approval*.

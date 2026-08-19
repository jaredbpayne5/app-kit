# APP-KIT V2 — Implementation Specification

**Status:** decided. This file is the build spec for App-Kit V2.
**Audience:** Claude Opus and Grok, later, when they build the kit.
**Not audience:** Matt's daily chat. Chat stays one line. This file carries the detail so the chat does not have to.

This file supersedes `APP-KIT-V2-FINAL.md` and the reshape/upgrade backlogs
(`RESHAPE.md`, `REPO-UPGRADE.md`). When V2 is implemented, those are retired — three
roadmaps is three sources of truth.

Every decision here is stated once. If you want a rule restated in your own words
somewhere else, don't. Link to the section.

---

## 1. What App-Kit is

A reusable, local-first Expo/React Native template plus a small AI workflow, cloned once
per app, run by one person on one Mac.

**Non-goals.** Not an agent framework. Not a control plane. Not a product-management
system. Not a replacement for git or for tests. Not a pipeline every change must walk.

**The whole point:** get real leverage from two frontier models while making it hard for
their mistakes to reach a shipped app. Prefer files and exit codes over reminders. Prefer
deleting machinery over adding it.

---

## 2. Authority

1. **`AGENTS.md` governs repo invariants** — no backend, the `lib/` seam table,
   Ask-before spend list, named-export gate for new screens, on-device data,
   `PURCHASES_MODE: mock`. These are already lint- and hook-enforced.
2. **This file governs process** — who does what, in what order, with which files.
3. **Invariants win.** If a process step would require breaking an invariant, stop and
   tell Matt. Do not implement around it.

`docs/PRD.md` says what the product must do. `docs/design.md` says how it is built.
Source code is what actually exists. After the first store ship, the running source is the
living spec: do not revert a correct fix to satisfy a stale doc — report the drift.

---

## 3. The cast

| Who | Does | Never does |
|---|---|---|
| **Matt** | Answers product questions. Drops screen pictures. Agrees the design. Switches helpers. Presses ship. | — |
| **Claude Opus** | `/product` `/design` `/plan` `/review` | App screens. Shipping. Grading its own work. |
| **Grok (Cursor)** | `/critic` `/code` `/improve` `/test` `/harden` | Inventing the product. Rewriting `docs/design.md`. Shipping. |
| **Sonnet** | Claude's mechanical leftovers: docs, searches, logs, decided renames. | Any PASS/FAIL. Advancing a stage. Design or review judgment. |
| **Composer** | Grok's mechanical leftovers. See below. | Any PASS/FAIL. Advancing a stage. |

**Composer may:** renames, repeated edits across files, adding `testID`s, "change Y to Z"
inside a pattern that already exists.

**Composer must never touch:** Expo config (`app.json`, `metro.config.js`,
`babel.config.js`), EAS (`eas.json`), `apps/mobile/lib/` seams, purchases or entitlement
logic, navigation structure (`app/` route tree, `_layout.tsx`), native modules, new
dependencies.

Frontier models own decisions. Lesser models do decided work. A script cannot check which
model sat in the chair — see §14.

---

## 4. v1 is one complete app

**The first app gets one PRD, one design, one critic pass, one plan.** Then many small
jobs until the app matches that design. Then ship.

Do **not** restart product → design → critic per screen or per task. "Per feature" is
Blueprint language for a team with a backlog; it is not the default here.

During build there is exactly one loop:

```
next unchecked job in docs/plan.md
  → Grok: code → test → improve → test
  → Claude: /review
  → box checked
  → next job
```

Design is reopened only for the reasons in §11.

---

## 5. Files (exact paths)

### v1 — flat, at `docs/` root

| Path | Is | Owner | Lifecycle |
|---|---|---|---|
| `docs/PRD.md` | Product: what and why | Matt (Claude interviews) | Edited until Matt is satisfied |
| `docs/design-exports/` | Screen pictures from a UI tool | Matt | Added to as screens are designed |
| `docs/design.md` | Technical how | Claude writes | **Frozen** once Matt agrees |
| `docs/critic.md` | Grok's verdict + findings | Grok writes | Appended per round; never deleted |
| `docs/plan.md` | Ordered jobs, checkboxes | Claude writes, Claude checks boxes | Living |

There is **no** `docs/<app-name>/` folder for v1. The app is the repo.

### Later chunk, after v1 has shipped

Only when the new chunk is real work the v1 design never covered:

```
docs/<new-feature>/design.md
docs/<new-feature>/critic.md
docs/<new-feature>/plan.md
```

`docs/PRD.md` is updated only if the *product* changed, not merely because code will.

A feature folder must **not** silently override `docs/design.md`. If the new chunk changes
v1 architecture, reopen `docs/design.md` on purpose (§11).

### Never create

`docs/tasks.md` · `docs/review-task-N.md` · any `workflow.json` / `state.json` /
`.ai/*.json` · `.ai/current-task.md` · mailbox files · pager files · a per-job review file.

---

## 6. Product vs Design vs Plan

Three different jobs. Mixing them is the failure this system exists to prevent.

- **PRODUCT** (`docs/PRD.md`) — what and why. Outcomes, users, business rules, edge cases,
  acceptance criteria. Not navigation, colors, type, or spacing unless a product rule
  forces it. Matt's intent; Claude must not invent requirements.
- **DESIGN** (`docs/design.md`) — technical how. Storage, purchases, failure behavior,
  invariants, acceptance criteria, test approach. Freezes on Matt's agreement.
- **PLAN** (`docs/plan.md`) — the order in which to build what design already decided.
  Changes daily as boxes get checked.

**`plan.md` must not decide anything.** No new screens, no data rules, no payment
behavior, no architecture. If planning reveals a design hole, stop and reopen design —
do not patch it in the plan.

**The job list must not live inside `design.md`.** Tracking work is never a reason to edit
a frozen design.

---

## 7. `docs/design.md`

Written by Claude in a fresh chat, from `docs/PRD.md` plus the pictures in
`docs/design-exports/`. No app code in that chat.

Required content, in this order. Omit a section only when it genuinely does not apply.

1. **Summary** — what is wrong today, what changes, the main downside.
2. **Scope** — what this design covers and what it does not.
3. **How it works** — one real user case walked start to finish.
4. **Components** — for each part: what it owns, what it depends on, what it does *not*
   own.
5. **Decisions** — for each real choice: what was chosen, what was rejected, what it costs.
6. **Invariants** — `INV-1`, `INV-2`… rules that must always hold. Short and testable.
7. **Interfaces and data** — storage keys via `lib/storage.ts`, entitlement rules via
   `lib/purchases.ts`, config flags, migration.
8. **Failure behavior** — what can fail, what state follows, what the user sees. Cover
   app start, purchases, work in flight.
9. **Acceptance criteria** — `AC-1`, `AC-2`… observable conditions that prove done.
10. **Test approach** — how each `INV-n` and `AC-n` gets proved.
11. **Risks** and **Open questions**.

Cite export frames by filename. A frame beats prose: if a screen is in scope and has no
named export in `docs/design-exports/`, stop — do not invent a layout.

Once an `AC-n` or `INV-n` is cited anywhere, that ID is permanent. Never renumber.

---

## 8. `docs/critic.md`

Written by Grok in a fresh Cursor chat that did not write the design. Read-only: Grok
does **not** edit `docs/design.md`.

`critic.md` is the **memory**. It is why the designing Claude chat can be closed. A
one-word stamp is a failed critic pass.

Required shape:

```markdown
# Critic — round 1

**Verdict:** FAIL

## What I checked
PRD.md, design-exports/ (home.png, onboarding-01.png), design.md, lib/storage.ts,
lib/purchases.ts, existing app/(tabs) routes.

## Findings

### 1. Streak resets on timezone change (Blocker)
- Where: design.md §7, INV-2
- Failure: INV-2 stores the streak against a local calendar day. A user who flies
  east loses a day they earned.
- Why it matters: the streak is the product's core loop. Losing one silently reads
  as a bug and there is no recovery path.
- Must change: state which clock is authoritative and what happens when it moves
  backward.

### 2. Paywall has no locked-state design (Important)
- Where: design.md §4, no matching AC
- Failure: MONETIZATION is subscription but no AC describes what a locked user sees.
- Must change: add an AC for the locked path, or state that everything is free in v1.

## Open questions
- Blocking: which clock owns the streak day?

## Not blocking
Naming of the storage key. Implementation may choose.
```

Rules:

- First line of the verdict block is exactly `**Verdict:** PASS`, `**Verdict:** FAIL`, or
  `**Verdict:** BLOCKED`. Machine-readable on purpose (§14).
- `BLOCKED` means the critic cannot judge yet — usually `docs/PRD.md` still contains
  `<!-- TEMPLATE_PLACEHOLDER -->`. Next step is `/product`, not a design fix.
- Every finding names: where, the concrete failure, why it matters, what must change.
- Report only findings that can change the design or its safety. Style preferences are not
  findings.
- The critic does not redesign, does not plan, does not write code.
- Round 2 **appends** `# Critic — round 2` to the same file. Never overwrite round 1.
  The FAIL history is the point.
- The chat ends after the verdict.

---

## 9. `docs/plan.md`

Written by Claude in a fresh chat after the design is frozen. Jobs only.

```markdown
# Plan

Design: docs/design.md (frozen 2026-08-20)

- [x] 1. Store and read the streak count
      Done when: streak survives app restart; INV-2 has a test; AC-3 passes.
      Check: npm run check, npm test
      Notes: use lib/storage.ts. No UI in this job.

- [ ] 2. Show the streak on the home screen
      Done when: home renders the stored count; empty state shows "Start today".
      Export: home.png
      Check: npm run check, npm run test:e2e
      Notes: depends on job 1.

- [ ] 3. Lock the history tab behind the paywall
      Done when: AC-7 and AC-8 pass with MOCK_ENTITLED false, then true.
      Check: npm run check, npm test
      Notes: use lib/purchases.ts. Do not add real keys.
```

Rules:

- One job = one thing that works when it is finished. Small enough for one Cursor chat and
  one review.
- Each job carries: **Done when** (observable, cites `AC-n`/`INV-n` where they apply),
  **Check** (exact commands), **Notes** (dependencies, seam to use, named export if UI,
  what to stay out of).
- Ordered by dependency. No job may need a decision that `design.md` does not already
  contain.
- **Only Claude checks a box, and only after `/review` returns PASS.** A checked box means
  *built and reviewed*, not *code written*. This is the whole progress record — which is
  why there is no per-job review file.
- If a job turns out to need a design decision, stop the job. Do not decide it in `/code`.

---

## 10. The v1 path

Matt is the doorbell. Helpers cannot open each other. Matt pastes one line into the right
app. The paste lines below are the interface — keep them this short.

| # | Who | Paste | Produces |
|---|---|---|---|
| 1 | Claude | `/product` | `docs/PRD.md` filled |
| 2 | Matt | — | pictures in `docs/design-exports/` |
| 3 | Claude, **new chat** | `/design` | `docs/design.md` |
| 4 | Grok, **new chat** | `/critic` | `docs/critic.md` |
| 5 | Claude, **new chat** (only on FAIL) | `/design fix the critic findings` | `design.md` edited |
| 6 | Claude, **new chat** (after PASS + Matt agrees) | `/plan` | `docs/plan.md` |
| 7 | Grok, **new chat** | `/code next job` | code + tests, committed |
| 8 | Claude, **new chat** | `/review job N` | verdict; box checked on PASS |
| 9 | — | repeat 7–8 | until `plan.md` is complete |
| 10 | both, then Matt | release gate (§13) | shipped |

Detail per step:

**1. `/product`.** Claude fills `docs/PRD.md` using the template already in that file.
Stops and asks while `<!-- TEMPLATE_PLACEHOLDER -->` remains. Does not invent an MVP, a
screen list, or a design system. Removes the sentinel only when a UI tool could work from
the PRD alone.

**2. Pictures.** Matt takes `docs/PRD.md` to a UI tool and drops exports in
`docs/design-exports/`. The PRD is the only repo file the tool gets. Kickoff prompts stay
out of the repo.

**3. `/design`.** Per §7.

**4. `/critic`.** Grok gets `docs/PRD.md`, `docs/design-exports/`, `docs/design.md`, and
the repo. Grok does **not** get Claude's explanation of why the design is good — the
committed file is the input. Per §8.

**5. On FAIL.** Per §12.

**6. `/plan`.** Matt agrees to the design out loud; design freezes; Claude plans. Per §9.

**7. One job.** Grok takes the next unchecked job. `code → test → improve → test`, then
`npm run check`. Simulator and Maestro only per §15. Commits. Asks before `git push`.
Does not start the next job. Does not review its own diff.

**8. `/review`.** Claude in a fresh chat. **Starts from `docs/PRD.md`, the job's
`AC-n`/`INV-n`, and the diff.** The question is *would the user succeed?* — not *does this
match my `design.md`*. See §16. On PASS, Claude checks the box. On FAIL, Claude names the
fixes and the job returns to Grok.

**10. Release.** §13.

---

## 11. When design must be reopened

Reopen `docs/design.md` only for one of these:

- New or changed stored-data rules, or a data migration
- Purchases or entitlement behavior
- A new permission, native module, or dependency
- A change to a `lib/` seam contract
- A new screen the v1 design did not cover

Anything else does not restart design. Do not reopen design to record progress, rename a
storage key, or adjust copy.

Reopening is: edit `design.md` → `/critic` again (appends a round) → Matt agrees → then fix
`plan.md` to match. Nobody redesigns quietly inside `/plan` or `/code`.

**After v1: the small-change path.** A decided change matching none of the triggers above —
a typo, a color, copy, an obvious bug on a screen that already exists — skips product,
design, critic, and plan entirely. Grok takes it straight to `code → test → improve →
test`, then `npm run check` plus whatever §15 requires for the surface it touched. Claude
`/review` in a fresh chat, starting from `docs/PRD.md` as always. Then merge under §18. No
`design.md` edit, no `critic.md` round, and no new `plan.md` entry — a small change is not a
job on the plan. If the work turns out to match a trigger above once Grok is inside it,
stop and reopen design rather than finishing it on this path. Nothing may be downgraded to
this path to avoid independent review.

---

## 12. On critic FAIL

1. **Close the Claude chat that wrote `design.md`.** Not for context limits — so it cannot
   defend its own work.
2. **New Claude chat** reads `docs/PRD.md`, `docs/design.md`, `docs/critic.md`. Edits
   `design.md` only to address the findings. Does not rewrite the parts that passed.
3. **Grok critic again.** Either the same critic chat continues as round 2 (still the
   critic job, still read-only), or a new critic chat reads the updated `design.md` plus
   the existing `critic.md`. Both are allowed.
4. **Max 2 rounds.** Then Matt decides: accept a finding as non-blocking, overrule it, or
   change the product.
5. **While `critic.md` is FAIL, `/plan` and `/code` do not start** unless Matt explicitly
   overrides in that chat.

---

## 13. The release gate

One checkpoint. Run it before **every** ship, not once when the app is "complete."

Three lenses, in any order, then Matt:

- **Grok — `/harden`** (new Cursor chat). Try to break the app: no network, slow
  network, interrupted request, bad and empty and huge input, double taps, app restart,
  background/foreground, permission denied, storage failure, purchase and restore failure,
  iOS vs Android differences, navigation edge cases, accessibility. Reports findings; fixes
  land as jobs.
- **Claude — `/review`, whole-app target** (new chat). Product fit against `docs/PRD.md`,
  architecture coherence, unnecessary complexity, security, dead code, drift between docs
  and running source. May list simplify work; Grok performs the edits. Claude does not gain
  app-write authority here.
- **Computer** — `npm run verify` and `npm run preflight`. **This is the full test.** It is
  not a third helper stage and no agent may declare it passed.

Then **Matt ships.** EAS build, EAS submit, `store:push`, `web:deploy`, App Store, Play —
Matt only, per the `AGENTS.md` Ask-before list.

There is no separate HARDEN stage, no separate FULL TEST stage, and no separate FINAL
REVIEW stage. This section is all three.

The old Claude-only `/harden` is **retired**: its product-fit and authority
checks fold into whole-app `/review`, and its store-readiness checks are
already in `preflight` and `/ship`. Grok owns `/harden` as the runtime lens.

---

## 14. Deterministic vs convention vs Matt

### A script can check these

| Question | Check |
|---|---|
| Is product done? | `grep -q TEMPLATE_PLACEHOLDER docs/PRD.md` |
| Do pictures exist? | any file in `docs/design-exports/` besides `README.md` |
| Does a design exist? | `test -f docs/design.md` |
| Did the critic pass? | last `**Verdict:**` line in `docs/critic.md` is `PASS` |
| Is a plan present? | `test -f docs/plan.md` |
| Any jobs left? | `grep -c '^- \[ \]' docs/plan.md` |
| Is the code clean? | `npm run check` exit 0 |
| Do tests pass? | `npm test` exit 0 |
| Is it releasable? | `npm run verify` and `npm run preflight` exit 0 |
| Seams respected, no hardcoded hex, no `text-[15px]`? | already `eslint` + `design-lint` |
| Secrets? | already `gitleaks` + pre-commit + CI |
| Generated files stale? | already `gen-theme --check`, `sync:legal --check` |

**v1 mechanism: the skills read these files themselves and refuse.** `/plan` and `/code`
stop when the last `**Verdict:**` line in `docs/critic.md` is not `PASS`, and every skill
stops on the PRD sentinel. That is convention rather than an exit code, and it is the
honest weakness of v1.

**Optional later — `scripts/dev/stage.sh`.** If a FAIL ever gets walked past in practice,
add a small tool that reads the files above, prints the current stage and whose turn it is,
and exits non-zero on `--require <stage>` when a precondition is unmet. Build it then, as
§26 step 7 — not up front.

If it is built, it must **store nothing**: no state file, no cache, no writes, everything
derived from the artifacts on each run. If it ever grows a file it writes to, that is the
mailbox again — delete it.

### A script cannot check these — they are convention

Which model wrote a file. Whether a chat was fresh. Whether the critic was truly
independent. Whether a finding is material. Whether tests are adequate. Whether a change
is small or material when it does not match the §11 trigger list.

Matt enforces these by opening the right app and starting a new chat. Do not build a check
that appears to verify authorship — a fake gate is worse than an admitted convention.

### Matt decides these

Ship. Spend. App identity and bundle IDs. Production keys. Adding a backend. Overriding a
critic FAIL. Merging when something is still red.

---

## 15. Simulator and test rules

| Change | Proof required |
|---|---|
| Lint, types, formatting, tokens, generated-file drift | `npm run check` only. **No simulator.** |
| Logic, storage, purchases, entitlement behavior | Jest + `npm run check` |
| New or changed user-visible flow | iOS Simulator + Maestro (`npm run test:e2e`) |
| Android-specific UI, Play-bound work | Android emulator + Maestro — at the release gate, not every job |
| Custom native module, or Expo Go cannot run it | local development build (`dev:build:ios` / `dev:build:android`) |
| Store binary, TestFlight, real device | EAS — release only, Matt only |

Maestro is required on the **first implementation of a new screen or flow**, and at the
release gate for the main happy path. It is not required for every job. Reading source is
never device proof.

Maestro stays out of default CI. XcodeBuildMCP is an IDE convenience — do not add it to the
kit, to CI, or to any stage here.

---

## 16. Independence

Independence comes from three things: the other app, a new chat, and a committed artifact.
Not from a checkbox.

- **Design critic:** Grok only. New Cursor chat. Read-only. Ends after the verdict.
- **Implementation review:** Claude only. New chat.
- **Do not implement in the critic chat.** A critic that will have to build what it
  criticized softens findings. The implementing chat is new and reads only the committed
  `design.md` and `critic.md`.
- **`/review` must not rubber-stamp Claude's own design.** Review starts from `docs/PRD.md`
  and the job's acceptance criteria. Design-compliance is a secondary check, not the
  standard. If the implementation satisfies the design but the user would still fail, that
  is a review FAIL and a §11 design reopen.
- **A chat never grades its own output.** Same rule for `/code` and `/improve`.
- **"Dual approval" is not two independent approvals** and V2 does not claim it is.
  `docs/critic.md` is the one independent gate. Claude may revise. Matt agrees. That is the
  honest description; do not dress it up.

Sonnet and Composer do not supply independence. A delegated worker inside a chat is still
that chat.

---

## 17. Verdict grammar

One vocabulary everywhere: **PASS** · **FAIL** · **BLOCKED**.

- `PASS` — no blocker or important finding remains.
- `FAIL` — a fixable blocker or important finding remains. Name the next owner.
- `BLOCKED` — required input is missing (PRD sentinel, missing export, no independent
  reviewer available).

`critic.md` records its verdict in the file. `/review` reports its verdict in chat; the
durable record is the checked box in `plan.md` plus the commit. No third artifact.

---

## 18. Git and GitHub

**Workflow state is the files in §5.** GitHub is not the stage machine. A pull request is
not required to run `/critic` or `/plan`. No labels, no PR-body checkboxes, no CI job
parsing either.

Minimum git convention:

- Work for one job lands as one or more commits a reviewer can read as a diff.
- Branch per job is optional; the requirement is that `/review` has a diff to review.
- `git push` is Ask-before, per `AGENTS.md`.

**Before merge to `main` or before a ship, someone other than the coder re-runs the
checks.** Either CI runs them on a PR, or Matt runs `npm run check` (and `verify` before a
ship) and reads the result himself. Either satisfies this rule. An agent reporting its own
green run does not.

---

## 19. Skill ownership

| Skill | Owner | Location | Purpose |
|---|---|---|---|
| `/product` | Claude | `.claude/skills/product/` | Fill `docs/PRD.md` |
| `/design` | Claude | `.claude/skills/design/` | Write `docs/design.md` |
| `/plan` | Claude | `.claude/skills/plan/` | Write `docs/plan.md` |
| `/review` | Claude | `.claude/skills/review/` | Review a job diff, or the whole app at the release gate |
| `/critic` | Grok | `.cursor/skills/critic/` | Write `docs/critic.md` |
| `/code` | Grok | `.cursor/skills/code/` | Build one job |
| `/improve` | Grok | `.cursor/skills/improve/` | Same behavior, clearer code — inside a job |
| `/test` | Grok | `.cursor/skills/test/` | Prove acceptance criteria |
| `/harden` | Grok | `.cursor/skills/harden/` | Adversarial lens at the release gate |
| `/ship` | Matt | `.cursor/skills/ship/` | Store gate and submission, human-driven |
| `pull-design` | Grok | `.cursor/skills/pull-design/` | Fetch the named export before UI work |
| `maestro-e2e` | Grok | `.cursor/skills/maestro-e2e/` | Maestro mechanics |

Changes from what is on disk today:

- `/critic` becomes **Cursor-only.** Delete the Claude copy. `AGENTS.md` currently lists
  `/critic` as shared and its first-app path has Claude run `/critic` then `/plan` — both
  are wrong and must go.
- `/test` becomes **Cursor-only.** Delete the Claude copy. `/review` may run `npm run
  check` and `npm test` read-only as evidence; it does not need its own test skill.
- Claude `/harden` is **retired.** Grok owns `/harden` (runtime lens) plus
  whole-app `/review` (Claude), per §13.
- `/architecture` is **not a v1 stage.** A fresh clone has no product-specific system to
  document. Keep the playbook on disk, on demand, for when a shipped app genuinely needs
  `ARCHITECTURE.md`.
- `/improve` is **inside every job** (§10 step 7), never a whole-app chapter after the plan
  is done. Claude may list simplify work at the release gate; Grok performs the edits.

---

## 20. `/improve` placement

Stated once, because it is the rule most likely to drift:

**`code → test → improve → test` is one job.** There is no app-wide IMPROVE phase. Simplify
work found at the release gate becomes jobs, or rides along with harden fixes. Improvement
never adds product behavior, and its tests must prove behavior was preserved.

---

## 21. Where we are

Derived from §5 and §14 — this is a lookup for resuming after a break, not a second copy of
the workflow. The table below is the answer; `scripts/dev/stage.sh` would print the same
thing if you ever build it (§14).

| File condition | Stage | Next |
|---|---|---|
| `PRD.md` has `TEMPLATE_PLACEHOLDER` | product | Claude `/product` |
| PRD ready, `design-exports/` empty | pictures | Matt |
| pictures exist, no `design.md` | design | Claude `/design` (new chat) |
| `design.md` exists, no `critic.md` | critic | Grok `/critic` (new chat) |
| `critic.md` last verdict = `BLOCKED` | product gap | Claude `/product` |
| `critic.md` last verdict = `FAIL` | design fix | new Claude chat, §12 |
| `critic.md` last verdict = `PASS`, no `plan.md` | plan | Matt agrees, then Claude `/plan` |
| `plan.md` has `- [ ]` jobs | build | Grok `/code next job`, then Claude `/review` |
| `plan.md` all `- [x]` | release | §13, then Matt ships |

---

## 22. Keep

Working, already V2-aligned, do not rebuild:

- The Expo app: `apps/mobile/` routes, `ui/` primitives, NativeWind, Expo Router
- `apps/mobile/lib/` seams and their tests, enforced by `eslint.config.js`
  `no-restricted-imports`
- `apps/mobile/lib/app-config.ts` capability flags, including `PURCHASES_MODE: mock` — the
  whole paywall is buildable before paying Apple or Google
- `npm run check` chain: `format:check`, `lint`, `typecheck`, `gen-theme --check`,
  `sync:legal --check`, `contrast-check`, `design-lint`, `guard-check`, `fail-proof-check`,
  `shellcheck-guards`
- `npm test`, `npm run verify`, `npm run smoke:export`, `npm run smoke:init`
- `scripts/store/review-preflight.sh` — see §23
- `scripts/lib/fail-proof-checks.test.sh` — 35 assertions proving each guard *can fail*.
  The best single idea in the repo: evidence applied to the tooling itself
- Secret defense: `.githooks/pre-commit` (gitleaks + regex fallback), `guard-secrets.sh`
  fail-closed, `gitleaks-action` in CI
- Guards: `guard-deploy-match.sh` and the two `scripts/lib/guard-*-claude.sh` adapters,
  `guard-protected-files.sh`, `guard-secret-files.sh`, `guard-identity-writes.sh`,
  `guard-shell.sh`
- CI: `expo-sdk-check.sh`, `audit-report.sh`, `check`, `test`, `smoke:init`, `smoke-export`
- `docs/recipes/` for store, payments, EAS, lander, compliance, Maestro, brand
- `docs/CAPABILITIES.md`, `docs/design-exports/`, `scripts/factory/init-app.sh` and its
  smoke test, `scripts/dev/session.sh`, `scripts/dev/doctor.sh`
- `AGENTS.md` invariants: no-backend, seam table, Ask-before list, security rules
- Skill playbook **content** for `/product` `/design` `/plan` `/review` `/critic` `/code`
  `/improve` `/test` `/ship` — good writing, wrong owners. Fix owners per §19; keep the
  bodies.

---

## 23. Preflight already exists

`scripts/store/review-preflight.sh` **is** the release check. Do not re-invent it. It has
14 checks and a `--gate=4` / `--gate=6` split so a harden-time run can defer what cannot
pass yet:

identity placeholders and bundle IDs · metadata TBD/empty · store character limits ·
app-config vs data-practices purchases · Sentry DSN vs declared crash reporting ·
`product.json` identity and legal URLs · privacy URL HTTP 200 · `eas.json` placeholders and
submit track · placeholder icon/splash hashes · screenshots valid per platform · compliance
fingerprint freshness (defeats `touch`) · attribution SDK vs declared analytics · leftover
demo copy · canonical legal markdown · then `npm run verify`.

Two additions, gate 6 only: `expo-sdk-check.sh` and `audit-report.sh` (both already exist,
currently CI-only).

**Drop "git state is understood."** It is not mechanizable, and inviting an agent to assert
it is exactly the assertion-over-evidence failure this system is built to avoid.

---

## 24. Throw away from the process

| Remove | Why |
|---|---|
| Mailbox: `.ai/current-task.md`, `mailbox-state.json`, `mailbox-check*.sh`, `guard-mailbox.sh`, the mailbox/`write-mailbox-task`/`review-cursor` skills | A side file claiming what the work is. Replaced by §5 artifacts |
| Pager: `.ai/.watching`, `.ai/.review-seen`, `wait-for-mail.sh`, `wait-for-review.sh`, `.cursor/commands/watch.md`, `stop.md` | Broken and unnecessary. Matt is the doorbell |
| The `stop` hook entry in `.cursor/hooks.json` (`timeout: 3600`) | Arms a 55-minute sleep on every Cursor turn to poll a file that no longer exists. **Unwire this first** |
| `.ai/` and its four `.gitignore` lines | Nothing lives there now |
| A 14-stage linear pipeline | §4 and §10 are the movie. There is no other |
| Workflow JSON / state files | §14: derive from artifacts, store nothing |
| GitHub labels or PR checkboxes as authority | §18 |
| Three contradictory manuals — `AGENTS.md` roles vs `RESHAPE.md` vs `docs/recipes/agent-workflow.md` | One workflow. This file. `agent-workflow.md` is deleted; its two good ideas (Grok owns critic, max 2 rounds) are already in §8 and §12 |
| `docs/build-spec.md`, `build-status.md`, `design-spec.md`, `screens-status.md`, `moonchild.md` | The six-doc authority stack. Replaced by `docs/design.md` + `docs/design-exports/` |
| `docs/recipes/compile-specs.md`, `docs/recipes/product-pipeline.md`, `README.md` §4 steps | Still teach the mailbox and the six-doc chain |
| Jobs inside `design.md` | §6 |
| `/architecture` as a required v1 stage | §19 |
| `scripts/lib/u4-fail-proof.sh` | Unplugged from `check`, so decoration by its own rule. Move its PRD-sentinel assertion into `fail-proof-checks.test.sh` and delete the file |
| `.claude/hooks/guard-deploy.sh`, `.claude/hooks/guard-sensitive-writes.sh` | Superseded by the `scripts/lib/guard-*-claude.sh` adapters that `settings.json` actually wires |

`pull-design` stays, rewritten: it gates on **a named export in `docs/design-exports/`**
only. Its current gates on `docs/screens-status.md` `Designed = yes` and
`docs/design-spec.md` die with those files.

`docs/PRD.md`'s header must stop naming `build-spec.md` and `design-spec.md` as
authorities. Fix the file — do not add prose telling agents to ignore it.

---

## 25. Never build

- Mailbox 2.0, pager 2.0, any doorbell that wakes an agent
- A workflow state machine, in JSON or any other file
- GitHub as the stage machine: label gates, checkbox parsers, CI that decides a stage
- Automatic cross-agent launching or notification
- Extra agent personas beyond the five in §3
- A control plane (`factory-main`-style), a release platform, or a rollback system —
  `git revert` is the rollback
- Blueprint's `/html-doc`, `/codex-issue-coordinator`, worktree stacks, or `check_repo.py`
  as an app gate
- A product-readiness artifact type. The PRD sentinel plus a `BLOCKED` critic verdict
  already gate this
- An orphan/reachability framework. Instead, `scripts/dev/shellcheck-guards.sh` must
  **glob** the hook and script directories rather than list files by hand — the handwritten
  list is why two dead waiters kept passing `npm run check`
- Any script whose job is reminding an agent of something `npm run check` could fail on

---

## 26. When app-kit is implemented (not now)

This file is the spec. Building it is separate work, one pass per chat. Do not one-shot
"install V2."

Order, and the traps:

1. **Unwire the `stop` hook in `.cursor/hooks.json` first.** It is a live footgun, not just
   dead code.
2. **Move `factory-main/` out of `app-kit`.** It is an unrelated Go control plane sitting in
   an Expo template, untracked and not gitignored; its 32 unformatted files are the only
   reason `npm run format:check` fails today. **`blueprint-main` is not inside `app-kit`** —
   it lives at `mobile-apps/blueprint-main`. Do not repeat the claim that it is.
3. **Get `npm run check` green.** A system built on exit codes cannot start from a red one.
4. **Reconcile the workflow into one story:** fix skill owners per §19, delete the files in
   §24, rewrite `pull-design` and `docs/PRD.md`'s header, rewrite `README.md`'s quickstart.
5. **Commit one coherent baseline** — the new skills *and* the pager deletion in the **same
   commit.** Never commit a broken stop hook alongside new skills and call it done.
   The current tree has 28 uncommitted paths and `HEAD` still contains the mailbox-era
   skills, so a fresh clone gets the old factory. Nothing in this spec is real until
   `git clone` reproduces it.
6. **Verify the clone:** clone to a scratch directory, run `npm run check` and `npm test`
   there.
7. **Then, optionally:** `scripts/dev/stage.sh`, skill frontmatter validation in `check`
   (~20 lines, name matches directory, description present), the two preflight gate-6
   additions from §23.

---

## 27. Success check

A later agent can build App-Kit V2 from this file without guessing:

1. **Which files exist** — §5, flat at `docs/` for v1, a folder only for a later chunk.
2. **Whose turn it is** — §10 to run it forward, §21 to resume.
3. **What Matt pastes** — §10, one line per step.
4. **What happens on FAIL** — §12: close the chat, new chat reads `critic.md`, max 2 rounds,
   Matt breaks ties.
5. **That v1 is one complete app** — §4. One PRD, one design, one critic, one plan, many
   jobs, then ship. Folders come later.
6. **What must not be built** — §25.

If two sections of this file ever disagree, that is a defect in this file. Fix it here
rather than deciding in a chat.

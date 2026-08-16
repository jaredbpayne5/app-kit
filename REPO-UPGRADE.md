# Factory upgrade backlog

Tracked list of changes to this **template** (the factory you clone per app).
Not a product spec. Not a substitute for `AGENTS.md`.

Local grades and incident notes stay in gitignored `REPO-EVALUATION.md`.
This file is the durable “what to change” list. Template-mode mailbox
tasks cite a section here, not `REPO-EVALUATION.md` §2.

**Status:** path locked 2026-08-15; stay-on-branch 2026-08-15. U0 leftovers
+ U-zero + U2 + U3 + U4 + U5 + U1a done on `factory-upgrade`. U6 and U1b
wait for a real app. Stay on that branch until this file is complete and
verified. One merge to `main` at the end. U6 clones from
`factory-upgrade`, not from `main`.
**Source:** independent evaluation, then two review passes.

---

## How to read this file

- **Always-on** — instructions an AI loads on every turn, whether or not
  they are relevant. Tokens here compete with the file it should be editing.
- **Seam** — a single `lib/` file that wraps a native SDK so screens cannot
  import that SDK directly (already lint-enforced).
- **Guard** — a hook or script whose job is safety (secrets, paid deploys,
  identity files).
- **Matcher** — `scripts/lib/guard-deploy-match.sh`. A speed bump against
  an aligned agent’s mistakes, **not** a security boundary.
- **Mailbox** — `.ai/current-task.md` (the task) plus
  `.ai/mailbox-state.json` (the doorbell). Do not change that file format.
- **U0–U5** are template edits. **U1a** is the always-on dedup (done).
  **U6** is a real product clone (evidence). **U1b** thins product rules
  from those notes. **U7** is optional doc polish.

Do **not** implement this as one task. Instruction-file edits fail in bunches.
Exception: U0 leftovers and U-zero are **one sitting**.

---

## Class rule

**Every check that can pass vacuously must prove it can fail**, in
`npm run check`. An acceptance criterion you have not watched fail is
decoration.

Known cases today:

- `.claude/hooks/guard-secrets.sh` — `grep` pattern starts with `-`, so
  macOS `grep` treats it as flags. The hook allows a fake AWS key.
- `.githooks/pre-commit` secret fallback — same `grep` shape, currently
  safe only because the pattern starts with `AKIA`. One edit from the
  same bug.
- `scripts/dev/design-lint.sh` sections 5 and 6 — print success when
  `find` returns zero files.

New checks follow the same rule.

---

## In scope / out of scope

**Do**

- Fix checks that cannot fail. Protect guard files from agent edits.
- Make Cursor’s secret/identity pauses real. Be honest about the matcher.
- Require a mailbox JSON + Premises check.
- U1a (mailbox/review out of always-on) is done. Clone one real app
  **before** thinning `AGENTS.md` product/design text (that is U1b).
- Then thin from clone notes; cap **bytes/tokens** of repo always-on
  files from that measurement (not a 200–250 line guess).
- Skills, Renovate, `knip:clone`, secure-storage seam, living-spec line.

**Do not**

- Delete unused `ui/` / demo screens / dormant seams in *this* template.
- Rewrite `session.sh` / `doctor.sh`.
- Put Maestro in default CI.
- Add a second ticket system (Taskmaster, Beads, Spec Kit, Conductor).
- Add a `Designed=yes` file-existence validator.
- Change the mailbox file format.
- Install full pstack, or unslop as always-on.
- Thin `AGENTS.md` before a first clone.
- Catch every `bash -c` wrapper (arms race).
- Gate ordinary `git commit` or `--no-verify`.
- Rearrange `apps/`.
- Run `npm audit fix --force`.

---

## Expected outcome

Repo always-on after U1a is about **4k tokens** (Claude ~4.1k with imported
`AGENTS.md`; Cursor ~4.0k without always-loading `CLAUDE.md`). Rough
tokens = bytes ÷ 4. User-level Cursor rules are extra and live outside
this repo.

U1a already moved mailbox/review procedure into skills. U1b’s saving is
whatever the first clone shows was unused — not a promised percentage.
Set the cap **after** that thin (U1b), not now.

On disk the template is slightly bigger (skills, tests, Renovate,
`knip`). The agent’s head is already smaller after U1a; U1b may shrink
`AGENTS.md` further from clone notes.

The factory gets **safer first**, then **cheaper to operate**. It does not
get dramatically faster at shipping a screen. Mailbox round-trips stay.

---

## Order

```
U0 leftovers + U-zero   one sitting on factory-upgrade
U2                      Cursor hooks, mailbox check, matcher honesty
U3                      Skills — pulled forward 2026-08-15 (no app yet)
U4                      lint-staged, Renovate, knip, CI — same sitting
U1a                     always-on dedup + re-measure (done; not behind U6)
U6                      first product clone from factory-upgrade (not main)
U1b                     thin product rules from those notes; measure; cap
U5                      secure-storage, living-spec, preflight “gate”
U7                      optional /unslop on leftover docs (on demand)
Merge to main           once, after the list above is done and verified
```

U6 and U1b still wait for a real app. U1a does not — it is done on this
branch. U3/U4 do not. Stay on `factory-upgrade` until this file is
complete; do not merge early.

Cloning today’s constitution is **not** expensive to undo. Instruction
files are not welded to screens. After U1b, copy the thinner files into
the product in one commit. Extra tokens for one app are cheaper to undo
than a paragraph you cut and later need.

---

## Workstreams

### U0 — This file as the template backlog

- **What:** This file is the durable list. Point template mode at it
  (`CLAUDE.md`, `.cursor/rules/implementation-workflow.mdc`,
  `.ai/current-task.template.md`). Commit it. Untick “done” until those
  pointers exist and the file is on `main`.
- **Why:** Those three files still send template work to empty
  `REPO-EVALUATION.md` §2. A backlog no agent can find is not a backlog.
- **How:** Same sitting as U-zero. Copy-and-edit the pointer sentences.
  Do not regenerate those files from memory.
- **Done when:** this file is tracked on `main`, and a search for
  `REPO-UPGRADE.md` hits the three pointer files.

### U-zero — Checks that can fail

Same sitting as U0 leftovers. A guard that has never fired is not backlog.

- **What:** Fix the dead `grep`. Add fail-proof tests for the three known
  vacuous checks. Deny agent edits of guard files. Warn if `gitleaks` is
  missing.
- **Why:** `guard-secrets.sh` has never blocked a key. The pre-commit
  fallback and design-lint 5/6 can pass while doing nothing. Agents can
  edit the guards; `settings.local.json` on this machine even pre-approves
  rewriting the matcher.
- **How:**
  - `grep -Eqe` (or `grep -E -q --`) everywhere that pattern exists.
  - Tests in `npm run check`: fake `AKIA` / PEM must deny; a normal edit
    must allow; pre-commit fallback must use `-e`; design-lint 5/6 must
    fail on an empty scan set (or a planted bad route).
  - Claude `permissions.deny` on guard scripts, `eslint.config.js`,
    `.githooks/`, `.github/workflows/ci.yml`. Cursor equivalent if the
    hook API allows.
  - `doctor.sh` warns if `gitleaks` is not on PATH.
  - You trim the dangerous allowlist rows in gitignored
    `.claude/settings.local.json` (cannot be fixed in the repo alone).
- **Benefits:** “We have secret hooks” becomes true. The class does not
  recur.
- **Risks:** A broken `failClosed` read-hook can block normal work. Prove
  with synthetic payloads.

### U2 — Cursor hooks and matcher honesty

- **What:** Secret/identity pauses on Cursor, including generated
  `apps/mobile/ios/` and `apps/mobile/android/`. Required mailbox JSON +
  non-empty Premises check. Cheap matcher holes. Honest docs.
- **Why:** Cursor can write `.env` / `app.json` / `data-practices.json`
  with no pause. Premises is a stop-the-line rule with no machine check.
  The matcher misses `session:down`, `npx eas-cli build`, two-space
  `git  push`, `git config core.hooksPath /dev/null`, and
  `rm .githooks/pre-commit`. Surrounding docs read like a security wall.
- **How:**
  - Cursor `beforeReadFile` deny on keystores / `.p8` / service-account
    JSON. `preToolUse` **deny** (not ask) on writes to those paths.
    `afterFileEdit` cannot reject — do not use it as a guard.
  - Write pause on `app.json`, `eas.json`, `data-practices.json`, and
    generated `ios/` / `android/`. Allowlist `init-app`.
  - Mailbox: valid JSON, allowed owner/status/mode, Premises not empty
    when status is `ready-for-cursor`.
  - Matcher: `session:down`, `eas-cli`, two-space push, `core.hooksPath`,
    `rm` of the pre-commit hook. Header: speed bump, not a boundary.
  - One line in `AGENTS.md`: which Ask-before items are matcher, which
    are file-write hooks, which are prose-only.
  - `shellcheck` in `npm run check`.
  - jq: fail-closed only on secret detection; other hooks warn and allow.
  - Re-arm: no paid Cursor `followup_message` just to say “still watching.”
  - Do not catch every `bash -c`. Do not gate ordinary commits.
- **Benefits:** Broken-guard-worse-than-no-guard is closed on both agents.
- **Risks:** Deny-on-`app.json` fights `init-app` unless allowlisted.

Stay on `factory-upgrade`. Clone U6 from this branch, not from `main`.

### U6 — First product clone (evidence, not a template commit)

- **What:** PRD → Moonchild → compile-specs → mailbox → `verify` →
  `preflight` on one real app, cloned from post-U2 `factory-upgrade`. Write down
  which always-on rules actually fired.
- **Why:** This factory has never produced a product. Every claim about
  which rules earn their keep is inference. U1b without that is guessing.
- **How:** Separate repo or folder. Do not thin the template first.
- **Benefits:** A list of hit vs never-hit rules. That list is U1b’s input.
- **Risks:** Temporary extra always-on tokens during the first build.
  Not lock-in.

### U1a — Always-on dedup (done 2026-08-15)

- **What:** Move mailbox write/review procedure out of always-on files.
  Stub Cursor’s implementation-workflow. Point `runner.md` at
  `AGENTS.md` Ask-before instead of restating it. Re-measure. Glob-scope
  the user Maestro hygiene rule (machine, not this repo).
- **Why:** Several files restated `AGENTS.md`. Cursor loaded Claude’s
  review protocol every turn. That is procedure, not a constraint.
- **How:** Skills (`mailbox`, `write-mailbox-task`, `review-cursor`,
  `pull-design`). Do not thin `AGENTS.md` product/design rules. Do not
  change hooks, `eslint.config.js`, or the mailbox file format.
- **Done when:** before/after counts exist in this file; one mailbox
  write + Cursor pickup + review already proved (Phases 2–3).
- **Benefits:** Fewer always-on tokens on every turn.
- **Risks:** Over-thinning product rules — that is U1b, not this.

Skills and `docs/recipes/` are not always-on.

#### Before / after

Phase 0 baseline was line counts only. After is `wc -l` / `wc -c` on
2026-08-15. Rough tokens = bytes ÷ 4.

| Path | Who | Before (lines) | After (lines) | After bytes | After tokens | Always-on after? |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `AGENTS.md` | both | 334 | 304 | 14646 | ~3662 | yes |
| `CLAUDE.md` | Claude | 194 | 43 | 1732 | ~433 | yes (Claude) |
| `.cursor/rules/implementation-workflow.mdc` | Cursor | 97 | 14 | 514 | ~129 | yes (Cursor) |
| `.cursor/rules/cursor-sandbox.mdc` | Cursor | 21 | 21 | 739 | ~185 | yes (Cursor) |
| `.claude/agents/runner.md` | Claude runner | restated Ask-before | 20 | 1032 | ~258 | when runner is used |
| `~/.cursor/rules/maestro-e2e-hygiene.mdc` | Cursor (user) | 39 (always-on) | 40 | 1332 | ~333 | no — glob-scoped |
| `~/.cursor/rules/delegate-to-cheaper-model.mdc` | Cursor (user) | 40 | 40 | 1793 | ~448 | yes (machine) |
| `~/.cursor/rules/beginner-step-by-step.mdc` | Cursor (user) | (not in Phase 0 list) | 27 | 1243 | ~311 | yes (machine) |

Repo always-on after U1a: Cursor `AGENTS.md` + implementation-workflow +
sandbox = 15899 bytes ≈ **4.0k** tokens. Claude `AGENTS.md` +
`CLAUDE.md` = 16378 bytes ≈ **4.1k** tokens.

User always-on (outside repo; count `beginner-step-by-step` once):
delegate + beginner = 3036 bytes ≈ **0.8k** tokens. A second identical
copy lives at `~/Development/.cursor/rules/beginner-step-by-step.mdc`
(27 / 1243). Maestro hygiene is glob-scoped (`alwaysApply: false`;
globs `**/*maestro*,**/test-e2e.sh`) and is not in that total.

No token cap yet. That is U1b after a real app.

#### Repeat map

| Path | Who loads it | Disposition |
| --- | --- | --- |
| `AGENTS.md` | both, every turn | keep (product/design authority; U1b may thin after U6) |
| `CLAUDE.md` | Claude only | keep (role split; points at skills) |
| `.cursor/rules/implementation-workflow.mdc` | Cursor, every turn | pointer / stub → `mailbox` skill |
| `.cursor/rules/cursor-sandbox.mdc` | Cursor, every turn | keep |
| `.claude/agents/runner.md` | Claude, when runner is used | pointer → `AGENTS.md` Ask-before |
| `.cursor/skills/` + `.claude/skills/` | on demand | skill |
| `docs/recipes/` | human / skill pointer | not always-on |
| `~/.cursor/rules/maestro-e2e-hygiene.mdc` | Cursor, Maestro / e2e files | keep, glob-scoped |
| `~/.cursor/rules/delegate-to-cheaper-model.mdc` | Cursor, every turn | keep (machine, not repo) |
| `~/.cursor/rules/beginner-step-by-step.mdc` | Cursor, every turn | keep (machine, not repo) |

### U1b — Product-rule thin (after U6 notes)

- **What:** Move unused *product* procedure out of always-on files.
  Keep what the clone actually hit. Cap repo always-on **bytes/tokens**
  from the post-thin measurement.
- **Why:** Extra rules compete with the open file. Cap lines reward long
  lines. A cap set before measuring fights itself.
- **How:** Thin from U6 hit vs never-hit notes. Do not guess. User-level
  rules stay a separate budget in `~/.cursor/rules`.
- **Benefits:** Cheaper turns; clones inherit a thinner constitution.
- **Risks:** Over-thinning. Mitigate with the clone notes, not a guess.

### U3 — Skills

- **What:** `.cursor/skills/`: `mailbox`, `compile-specs`,
  `pull-design`, `store-preflight`, `maestro-e2e`. Recipes stay the
  human source.
  Fix `PURCHASES_MODE` in `docs/recipes/compile-specs.md` (it is a
  standalone export, not an `APP_CONFIG` key).
- **Why:** Rules = constraints. Skills = procedures, loaded when relevant.
- **How:** Link to `docs/recipes/`. Do not paste a 200-line recipe into
  `SKILL.md`. Point at the skill from the thin `AGENTS.md` and the waiter.
- **Risks:** A skill nobody invokes is a dead file. The pointer is what
  makes it fire.

### U4 — DevEx and SDK drift

- **What:** `lint-staged` on pre-commit (touched files). **Renovate**
  (not Dependabot) with the Expo-managed set frozen (`expo`,
  `react-native`, `react`, `react-dom` move only via
  `npx expo install --fix`). `knip` ignores template inventory;
  `npm run knip:clone` after the PRD sentinel is gone. CI:
  `npx expo-doctor`, `npx expo install --check`, `npm audit` as a
  report (never `audit fix --force`).
- **Why:** Full `check`+`test` on every commit tempts `--no-verify`.
  Naive `knip` will “delete the factory.” SDK drift is the expensive
  clone failure. Same concern as Renovate.
- **How:** Wire `lint-staged` into `.githooks/pre-commit`. Do not add
  Husky. Do not put `knip` on default `npm run check` in this template.
- **Risks:** Configure `knip` ignores before `knip:clone`.

### U5 — Small product-hardening

- **What:** `apps/mobile/lib/secure-storage.ts` + ESLint restrict
  `expo-secure-store` (already installed). One living-spec paragraph in
  `AGENTS.md`. Rename preflight “phase” to “gate” (build-status phases
  0–8 are a different word).
- **Why:** Agents will put tokens in KV because that is the advertised
  seam. Spec-over-code will fight post-ship fixes.
- **How:** Same lazy-load pattern as `lib/purchases.ts`. List the seam in
  `docs/CAPABILITIES.md` as inventory.
- **Risks:** A seam with no callers looks unused. That is acceptable.

### U7 — Optional unslop (after U1b, not instead)

- **What:** One on-demand `/unslop` pass on leftover README / recipes.
  Skip hooks and the mailbox template unless you read every line.
- **Why:** Style is not volume. U1a already moved procedure out of
  always-on. U1b decides which product rules stay. Unslop decides how
  leftover sentences sound.
- **How:** Do **not** install as always-apply. Do not “add soul” on
  agent contracts.
- **Risks:** A whole-repo rewrite of `AGENTS.md` can drop a load-bearing
  rule while `check` stays green.

---

## Tools — include vs skip

**Put in the repo**

| Thing | Role |
| --- | --- |
| Fail-proof tests in `npm run check` | Class rule |
| Claude/Cursor deny on guard files | Agents cannot edit the net |
| Cursor `beforeReadFile` / `preToolUse` | Secret / identity pauses |
| Mailbox JSON + Premises check | Stop-the-line, machine-enforced |
| `.cursor/skills/` (names above) | On-demand procedures |
| Context-budget script (U1b, after measure) | Repo always-on size cap |
| Glob-scoped instruction-hygiene `.mdc` | Only when editing those files |
| `lint-staged` | Fast pre-commit |
| Renovate + Expo freeze | SDK drift |
| `expo-doctor` + `expo install --check` in CI | Same concern, cheapest catch |
| `npm audit` in CI (report) | Vulnerabilities, no `--force` |
| `knip` + `knip:clone` | Dead code **after** PRD |
| `shellcheck` in `npm run check` | Would have caught the dead grep |

**Already on the machine — wire, do not install**

- Bugbot and Security Review: optional line on the review checklist.
- Context7, Moonchild, XcodeBuildMCP: keep.
- `gitleaks` and `shellcheck` binaries: present on this Mac. `doctor.sh`
  must warn if `gitleaks` is missing (silent fallback otherwise).

**Do not add**

- Full pstack / always-on unslop.
- Dependabot (Renovate is the pick).
- `eslint-plugin-boundaries`, ts-prune, sweepy, siko.
- Taskmaster, Beads, Spec Kit, Conductor.
- A new MCP for the mailbox.

**Your machine, not this repo:** one copy of `beginner-step-by-step`.
Delegation can live only in `AGENTS.md`. Trim `.claude/settings.local.json`
allowlist rows that rewrite the matcher.

---

## Progress

- [x] Path locked in this file (2026-08-15)
- [x] U0 leftovers — pointers in CLAUDE.md / implementation-workflow /
      mailbox template; this file on `main`
- [x] U-zero — fail-proof tests + dead grep + deny on guard files
      (same sitting as U0 leftovers)
- [x] U2 — Cursor hooks, mailbox check, matcher honesty
- [ ] Merge `factory-upgrade` to `main` (once, after this list is verified)
- [ ] U6 — first product clone (separate repo; not a template commit)
- [x] U1a — always-on dedup + re-measure (mailbox/review in skills;
      implementation-workflow stub; runner Ask-before pointer;
      user Maestro hygiene glob-scoped). Before/after in this file.
- [ ] U1b — thin product rules from U6 clone notes; measure; cap
- [x] U3 — skills (`.cursor/skills/` mailbox, compile-specs,
      pull-design, store-preflight, maestro-e2e; `PURCHASES_MODE`
      standalone in `docs/recipes/compile-specs.md`; pointers in
      `AGENTS.md` + waiter)
- [x] U4 — lint-staged, Renovate, knip:clone, CI expo-sdk-check +
      audit report; Expo 56 patches aligned via `expo install --fix`.
      Pre-commit is lint-staged + secrets only — fail-proof / design-lint
      / mailbox-check live in CI and `npm run verify`, not at commit
      (deliberate; full check tempted `--no-verify`). `expo-doctor` is a
      report on SDK 56 (Hermes V1 check fails; advertised fix is SDK 57).
      `expo install --check` is the gate. Broader Renovate freeze than the
      four named packages: all `expo-*` + SDK-aligned natives travel with
      `npx expo install --fix`.
- [x] U5 — secure-storage + living-spec + preflight “gate”.
      Seam `apps/mobile/lib/secure-storage.ts` (lazy require, no callers).
      ESLint restrict on `expo-secure-store` watched fail on a probe import
      (`no-restricted-imports` → use `@/lib/secure-storage`), then probe
      removed. Preflight flag is `--gate=4|6`; build-status 0–8 stay phase.
      `docs/build-spec.md` + `docs/build-status.md` edits are vocabulary
      only (phase vs gate); both `TEMPLATE_PLACEHOLDER` sentinels stayed.
- [ ] U7 — optional unslop polish

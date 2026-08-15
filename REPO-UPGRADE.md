# Factory upgrade backlog

Tracked list of changes to this **template** (the factory you clone per app).
Not a product spec. Not a substitute for `AGENTS.md`.

Local grades and incident notes stay in gitignored `REPO-EVALUATION.md`.
This file is the durable “what to change” list. Template-mode mailbox
tasks cite a section here, not `REPO-EVALUATION.md` §2.

**Status:** path locked 2026-08-15. U0 leftovers + U-zero in progress on
`factory-upgrade`.
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
- **U0–U5** are template edits. **U6** is a real product clone (evidence).
  **U7** is optional doc polish.

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
- Clone one real app **before** thinning always-on text.
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

Repo always-on today is about **5–6k tokens** (Claude ~6.3k with imported
`AGENTS.md`; Cursor ~5.2k without always-loading `CLAUDE.md`). User-level
Cursor rules are extra and live outside this repo.

U1’s saving is whatever the first clone shows was unused — likely a few
thousand tokens, not a promised −60–75%. Set the cap **after** the thin.

On disk the template gets slightly bigger (skills, tests, Renovate,
`knip`). The agent’s head gets smaller only after U1.

The factory gets **safer first**, then **cheaper to operate**. It does not
get dramatically faster at shipping a screen. Mailbox round-trips stay.

---

## Order

```
U0 leftovers + U-zero   one sitting on factory-upgrade
U2                      Cursor hooks, mailbox check, matcher honesty
Merge U0–U2 to main     so the first clone inherits working guards
U6                      first product clone; note which rules fired
U1                      thin from those notes; measure; cap
U3                      Skills
U4                      lint-staged, Renovate, expo-doctor, audit
U5                      secure-storage, living-spec, preflight “gate”
U7                      optional /unslop on leftover docs (on demand)
```

Do not delay U-zero/U2 until you have an app idea. Do delay U1 until you
have used the factory once. If a product is months away, merge U0–U2 and
wait.

Cloning today’s constitution is **not** expensive to undo. Instruction
files are not welded to screens. After U1, copy the thinner files into
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

Then **merge U0–U2 to main** before cloning.

### U6 — First product clone (evidence, not a template commit)

- **What:** PRD → Moonchild → compile-specs → mailbox → `verify` →
  `preflight` on one real app, cloned from post-U2 `main`. Write down
  which always-on rules actually fired.
- **Why:** This factory has never produced a product. Every claim about
  which rules earn their keep is inference. U1 without that is guessing.
- **How:** Separate repo or folder. Do not thin the template first.
- **Benefits:** A list of hit vs never-hit rules. That list is U1’s input.
- **Risks:** Temporary extra always-on tokens during the first build.
  Not lock-in.

### U1 — Context budget (after U6 notes)

- **What:** Move unused procedure out of always-on files. Keep what the
  clone actually hit. Cap repo always-on **bytes/tokens** from the
  post-thin measurement. Glob-scoped hygiene rule.
- **Why:** Extra rules compete with the open file. Cap lines reward long
  lines. A cap set before measuring fights itself (`AGENTS.md` is already
  314 lines).
- **How:** Dedup map first (several files restate `AGENTS.md`;
  `.claude/agents/runner.md` drops Ask-before items). Move text into
  Skills / `CLAUDE.md` only. Shrink
  `implementation-workflow.mdc` to a short stub. Do not load full Claude
  review protocol on every Cursor turn. Prove one mailbox handoff after
  the thin. While `AGENTS.md` is open: one line so **source code is not
  ranked below `docs/build-status.md`** after ship. User-level rules
  stay a separate budget in `~/.cursor/rules`.
- **Benefits:** Cheaper turns; clones inherit a thinner constitution.
- **Risks:** Over-thinning. Mitigate with the clone notes, not a guess.

### U3 — Skills

- **What:** `.cursor/skills/`: `mailbox`, `compile-specs`,
  `store-preflight`, `maestro-e2e`. Recipes stay the human source.
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

### U7 — Optional unslop (after U1, not instead)

- **What:** One on-demand `/unslop` pass on leftover README / recipes.
  Skip hooks and the mailbox template unless you read every line.
- **Why:** Style is not volume. U1 decides what is always-on. Unslop
  decides how leftover sentences sound.
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
| `.cursor/skills/` (four names above) | On-demand procedures |
| Context-budget script (U1, after measure) | Repo always-on size cap |
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
- [ ] U-zero — fail-proof tests + dead grep + deny on guard files
      (same sitting as U0 leftovers)
- [ ] U2 — Cursor hooks, mailbox check, matcher honesty
- [ ] Merge U0–U2 to `main`
- [ ] U6 — first product clone (separate repo; not a template commit)
- [ ] U1 — thin from clone notes; measure; cap
- [ ] U3 — skills
- [ ] U4 — lint-staged, Renovate, expo-doctor, audit
- [ ] U5 — secure-storage + living-spec + preflight “gate”
- [ ] U7 — optional unslop polish

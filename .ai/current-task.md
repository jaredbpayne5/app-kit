# Current task

Agent-to-agent handoff between Claude (plans, reviews) and Cursor
(implements). **One task at a time. No history — overwrite each task.**

This file has no authority. It carries work already authorized elsewhere; it
never defines requirements.

- **Owner:** `claude`   <!-- claude | cursor | none -->
- **Status:** `ready-for-review`  <!-- idle | ready-for-cursor | in-progress | ready-for-review -->
- **Mode:** `template`    <!-- product | template | none -->
- **Updated:** 2026-08-11

Whoever is not the Owner does not write source files. Mode is set explicitly by
Claude on every handoff, never inferred:

- **product** — building the app in a clone. Authorized by `docs/build-spec.md`;
  `docs/build-status.md` remains the durable execution record and must be
  updated on completion.
- **template** — developing this template itself. Authorized by
  `REPO-EVALUATION.md` §2/§3; that file is the durable record. Leave
  `docs/build-status.md` and every `<!-- TEMPLATE_PLACEHOLDER -->` doc untouched.

---

## Task

Fix seven stale or missing statements in the template's documentation and one
comment. Every item below has been verified against the current tree — the line
numbers and the current text are accurate as of `d7d3fb3`. This is a
docs-and-comments task: **no behaviour changes, no script changes, no lint or
config changes.**

**Source:** `REPO-EVALUATION.md` §2 → "2. Smaller items" (the docs sub-bullets,
the two `README.md` sub-bullets, and the dead-tab-route sub-bullet).

**Goal:** A reader following this repo's docs top-to-bottom is not sent to a
deleted file, a non-existent path, a wrong check number, a wrong command form,
or a setup order that leaves `.env.local` unstamped — and knows the two hard
tooling requirements before they start.

**Scope:**

1. **`docs/recipes/ota-updates.md:57`** — delete this bullet entirely:

   ```
   - Go-live / prod env: `docs/FACTORY-PLAN.md (no backend go-live in this template)` (Stage 3 Part D).
   ```

   `docs/FACTORY-PLAN.md` was deleted, and "Stage 3 Part D" is a leftover
   reference to the project this template was extracted from. There is no
   backend and no go-live stage here, so the bullet has no correct rewrite —
   remove it and leave the other two bullets in that `## Related` list.

2. **`docs/recipes/payments.md:76`** — `preflight --phase=4` → `preflight -- --phase=4`.
   The `--` is required to pass the flag through npm to the script. Fix this
   file only; see *Out of scope* for the other two occurrences.

3. **`eas.json` path** — there is no `eas.json` at the repo root; the real file
   is `apps/mobile/eas.json`. Make the **first** mention in each of these files
   the full path. Later bare mentions inside the same file are fine once the
   path is established:
   - `docs/recipes/app-store.md:11`
   - `docs/recipes/eas-build.md:6`
   - `docs/recipes/play-store.md:4`

   `docs/recipes/app-store.md:31` ("Replace `REPLACE_WITH_APP_STORE_CONNECT_APP_ID`
   in `eas.json`") is an instruction to open the file, so it needs the path too
   even though it is the second mention in that file.

4. **`docs/recipes/ads-attribution.md`** — the attribution check is **check 12**,
   not check 11. `scripts/store/review-preflight.sh:438` is
   `# --- 12. Attribution SDK vs data-practices analytics (dormant guard) ----`;
   check 11 is compliance freshness (`:412`). Fix all five occurrences:
   lines 101, 103, 112, 116, 138.

5. **`README.md` — add a Requirements section.** The README currently never
   states either hard requirement. Add a short section immediately before
   `## Starting a new app`:
   - **Node ≥ 24** — matches `.nvmrc` (`24`) and `package.json` `engines`
     (`>=24.0.0`).
   - **`jq`** — all three `.claude/hooks` scripts (`guard-deploy.sh`,
     `guard-secrets.sh`, `guard-sensitive-writes.sh`) shell out to `jq` and fail
     closed without it, which makes Claude Code non-functional in this repo.
     Say that consequence, not just the dependency. `brew install jq`.

6. **`README.md:25-27` — fix the setup order.** Step 2 shows the `npm run init-app`
   command block and only *afterwards* says "Copy `.env.example` to `.env.local`
   first if you have not already." `scripts/factory/init-app.sh` only stamps
   `.env.local` if the file already exists (it is an "upsert … (if file exists)"
   edit — see the dry-run summary at `:160-163`), so a reader going top-to-bottom
   runs `init-app` against a missing `.env.local` and it is silently never
   stamped. Move the copy instruction **before** the command block so the
   ordering is correct when read straight through.

7. **`apps/mobile/app/(tabs)/library.tsx:1-5`** — the delete-me comment tells you
   to delete the screen but not that deleting it leaves a dead tab route behind.
   Extend it to say that removing this file also means removing the
   `<Tabs.Screen name="library" …>` block in `apps/mobile/app/(tabs)/_layout.tsx`.
   Comment text only — do not change the imports or any code in either file.

8. **`REPO-EVALUATION.md`** — the durable record for template mode:
   - Move each item above from §2 → §1 with the grep that proves it (see
     *Acceptance criteria*). Leave the rest of §2 in place — in particular
     §2.1 (the compile-pass validator), the `build-status.md` mitigation
     bullet, the `cssInterop`/FlashList bullet, and the device-only
     splash item are **not** part of this task and must stay open.
   - Fix the stale repo-state block at lines 15–26. It claims
     `origin/main = 7239335` with three unpushed local commits. Actual state:
     `origin/main` is `d7d3fb3`, **0 unpushed**, and four commits landed after
     that block was written (`53822a7`, `62cc4de`, `40df3ec`, `f8a4d5a`,
     `d7d3fb3`). Re-run `git log --oneline -5`, `git rev-parse --short origin/main`,
     and `npm test` and write down what you actually observe — do not copy these
     numbers on my word.

**Out of scope:**

- **`docs/build-spec.md:14` and `docs/build-status.md:152`** also contain the
  wrong `preflight --phase=N` form. Both are `<!-- TEMPLATE_PLACEHOLDER -->`
  docs. Template mode says leave those untouched, and whether the template's own
  scaffolding prose inside a placeholder doc is fixable is my call, not this
  task's. **Do not touch either file.**
- `README.md:70-73` ("including restore and renewal") is a real overclaim but it
  is a §3 monetization item and depends on fixes that do not exist yet. Leave it.
- Any script under `scripts/`, `eslint.config.js`, `package.json`, hooks, or any
  `.tsx` other than the comment block in item 7.
- No reformatting of untouched lines. Prettier may reflow a paragraph you edit;
  it must not reflow paragraphs you did not.

**Acceptance criteria:**

- [x] `grep -rn "FACTORY-PLAN" docs/ README.md` → no output
- [x] `grep -rn -- "preflight --phase" docs/recipes/` → no output (recipes only;
      the two placeholder docs still match and that is expected)
- [x] `grep -rn "check 11" docs/recipes/ads-attribution.md` → no output, and
      `grep -c "check 12" docs/recipes/ads-attribution.md` → `5`
- [x] Every `eas.json` mention in `docs/recipes/` is either `apps/mobile/eas.json`
      or a later bare mention in a file whose first mention carries the path
- [x] `grep -n -i "jq" README.md` and `grep -n "24" README.md` both hit the new
      Requirements section, and it states that missing `jq` breaks Claude Code
- [x] In `README.md` step 2, the `.env.example` → `.env.local` copy instruction
      appears **above** the `npm run init-app` code block
- [x] `apps/mobile/app/(tabs)/library.tsx` header comment names
      `app/(tabs)/_layout.tsx` and the `Tabs.Screen` block
- [x] `git diff --stat` touches only: `docs/recipes/ota-updates.md`,
      `docs/recipes/payments.md`, `docs/recipes/app-store.md`,
      `docs/recipes/eas-build.md`, `docs/recipes/play-store.md`,
      `docs/recipes/ads-attribution.md`, `README.md`,
      `apps/mobile/app/(tabs)/library.tsx` — and nothing else
      (`REPO-EVALUATION.md` is gitignored, so it will not appear here)
- [x] `git diff -- docs/build-spec.md docs/build-status.md docs/PRD.md docs/design-spec.md docs/moonchild.md docs/screens-status.md`
      → empty
- [x] `npm run check` passes
- [x] `npm test` passes (no logic changed, but item 7 edits a `.tsx` file — run
      it to confirm the comment edit did not disturb the module)
- [x] template mode: `REPO-EVALUATION.md` updated per item 8; no `docs/`
      placeholder touched

**Notes / known risks:**

- The standard template-mode proof ("write a deliberate violation, watch it
  fail, revert") does not apply — this task adds no guard. The greps above are
  the proof. Do not invent a lint rule to enforce any of this.
- `npm run check` includes `format:check`. Prettier owns Markdown wrapping here,
  so run `npm run format` if it complains rather than hand-wrapping, but then
  re-check `git diff` for paragraphs you did not intend to touch.
- Item 5 is the one item with real authoring latitude — placement and heading
  are specified, wording is yours. Keep it to a few lines; the README is already
  long and this is a prerequisite note, not a tutorial.
- If any line number above does not match what you find, **stop and report it**
  rather than searching for the nearest similar text. A mismatch means the tree
  moved under this task and I need to know.

---

## Implementation report

_(Cursor fills this in, then sets Owner: `claude` / Status:
`ready-for-review`.)_

**Changed:**

- `docs/recipes/ota-updates.md` — deleted the `FACTORY-PLAN.md` / Stage 3
  Part D bullet; other two Related bullets kept
- `docs/recipes/payments.md` — `preflight --phase=4` → `preflight -- --phase=4`
- `docs/recipes/app-store.md` — first mention and the open-the-file
  instruction now say `apps/mobile/eas.json`
- `docs/recipes/eas-build.md` / `play-store.md` — first `eas.json` mention
  is now `apps/mobile/eas.json`
- `docs/recipes/ads-attribution.md` — all five "check 11" → "check 12"
- `README.md` — `## Requirements` (Node ≥ 24, `jq` + Claude Code
  consequence) immediately before Starting a new app; `.env.example` →
  `.env.local` copy moved above the `init-app` block
- `apps/mobile/app/(tabs)/library.tsx` — header comment names the
  `Tabs.Screen` block in `_layout.tsx`
- `REPO-EVALUATION.md` — those items moved to §1 with the greps; repo-state
  block rewritten from `git log --oneline -5` / `origin/main`; remaining
  §2.2 is only the build-status mitigation and cssInterop/FlashList bullets

**Verification run:**

- `grep -rn "FACTORY-PLAN" docs/ README.md` → empty
- `grep -rn -- "preflight --phase" docs/recipes/` → empty
- `grep -rn "check 11" docs/recipes/ads-attribution.md` → empty
- `grep -c "check 12" docs/recipes/ads-attribution.md` → `5`
- `grep -n -i "jq" README.md` → line 17 (Requirements); `grep -n "24"
  README.md` → line 16
- `git log --oneline -5` → `d7d3fb3` `f8a4d5a` `40df3ec` `62cc4de` `53822a7`
- `git rev-parse --short origin/main` → `d7d3fb3` (0 unpushed)
- `git diff -- docs/build-spec.md docs/build-status.md docs/PRD.md
  docs/design-spec.md docs/moonchild.md docs/screens-status.md` → empty
- `npm run check` exit **0** (format:check passed; no `npm run format` needed)
- `npm test` exit **0** — **17 suites / 73 tests**

**Deviations:** `git diff --stat` also includes `.ai/current-task.md` (this
mailbox). Required by the handoff protocol; not a product/docs file from the
scope list. `REPO-EVALUATION.md` is gitignored and does not appear.

**Blockers / open questions:** None

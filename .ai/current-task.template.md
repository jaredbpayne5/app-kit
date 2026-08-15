# Current task

Agent-to-agent handoff between Claude (plans, reviews) and Cursor
(implements). **One task at a time. No history — overwrite each task.**

This file has no authority. It carries work already authorized elsewhere; it
never defines requirements.

- **Owner:** `none`   <!-- claude | cursor | none -->
- **Status:** `idle`  <!-- idle | ready-for-cursor | in-progress | ready-for-review -->
- **Mode:** `none`    <!-- product | template | none -->
- **Updated:** —

Whoever is not the Owner does not write source files. Mode is set explicitly by
Claude on every handoff, never inferred:

- **product** — building the app in a clone. Authorized by `docs/build-spec.md`;
  `docs/build-status.md` remains the durable execution record and must be
  updated on completion.
- **template** — developing this template itself. Authorized by
  `REPO-UPGRADE.md`; that file is the durable record. Leave
  `docs/build-status.md` and every `<!-- TEMPLATE_PLACEHOLDER -->` doc untouched.

---

## Task

_(None. Claude fills this in, then sets Owner: `cursor` / Status:
`ready-for-cursor`.)_

**Source:** _(product: task id + name from `docs/build-spec.md` — template:
`REPO-UPGRADE.md` section + item)_

**Goal:** _(one or two sentences — what should be true when this is done)_

**Premises — verify these before building:**

The factual claims this task rests on, each with the command that confirms it.
**Run them first.** If any premise is false, set Status `ready-for-review` with
what you found and **stop** — do not adapt the task around it. A false premise
means the task is wrong, not that the implementation needs to be creative.

Claude fills this in from checks already run, so this is confirmation, not
discovery. An empty Premises block means the task was written without verifying
anything — treat that as a defect and say so.

- [ ] _(claim — e.g. "no EXIT trap exists in this script")_ — `(command)`

**Scope:**

- _(files or areas expected to change)_

**Out of scope:**

- _(what not to touch)_

**Acceptance criteria:**

- [ ] _(checkable by someone who did not write the code)_
- [ ] `npm run check` passes
- [ ] `npm test` passes (if logic changed)
- [ ] product mode: `docs/build-status.md` updated
- [ ] template mode: fix proven (deliberate violation fails, revert, tree
      clean); no `docs/` placeholder touched

**Notes / known risks:** _(edge cases, prior attempts, gotchas)_

---

## Implementation report

_(Cursor fills this in, then sets Owner: `claude` / Status:
`ready-for-review`.)_

**Changed:** _(files + what changed in each)_

**Verification run:** _(exact commands + results)_

**Deviations:** _(where the implementation departs from the task, and why)_

**Blockers / open questions:** _(or None)_

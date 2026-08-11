# Current task

Agent-to-agent handoff between Claude (plans, reviews) and Cursor
(implements). **One task at a time. No history — overwrite each task.**

This file has no authority. It carries work already authorized by
`docs/build-spec.md`; it never defines requirements. `docs/build-status.md`
remains the durable execution record — completing a task still means updating
it.

- **Owner:** `none`   <!-- claude | cursor | none -->
- **Status:** `idle`  <!-- idle | ready-for-cursor | in-progress | ready-for-review -->
- **Updated:** —

Whoever is not the Owner does not write source files.

---

## Task

_(None. Claude fills this in, then sets Owner: `cursor` / Status:
`ready-for-cursor`.)_

**Build-spec task:** _(id + name from `docs/build-spec.md`, or "n/a")_

**Goal:** _(one or two sentences — what should be true when this is done)_

**Scope:**

- _(files or areas expected to change)_

**Out of scope:**

- _(what not to touch)_

**Acceptance criteria:**

- [ ] _(checkable by someone who did not write the code)_
- [ ] `npm run check` passes
- [ ] `npm test` passes (if logic changed)
- [ ] `docs/build-status.md` updated

**Notes / known risks:** _(edge cases, prior attempts, gotchas)_

---

## Implementation report

_(Cursor fills this in, then sets Owner: `claude` / Status:
`ready-for-review`.)_

**Changed:** _(files + what changed in each)_

**Verification run:** _(exact commands + results)_

**Deviations:** _(where the implementation departs from the task, and why)_

**Blockers / open questions:** _(or None)_

# Recipe — compile specs (one-time Opus pass)

Use this **once per product clone**, after:

1. `docs/PRD.md` is finished (sentinel removed).
2. Design artifacts are exported into `docs/design-exports/` (or MCP-linked).
3. Identity is set (`npm run init-app`) when you already know the final name.

**Model:** strong / frontier (e.g. Claude Opus).  
**Do not** use a cheap model for this pass.  
**After this pass:** switch to Composer 2.5 Fast (or equivalent) and implement
tasks from `docs/build-spec.md`.

There is no `docs/design-brief.md`. Kickoff prompts for the design tool stay
outside the repo.

---

## Master prompt (copy everything below the line into Cursor)

---

You are compiling product specs for this Expo template clone. Follow
`AGENTS.md` and `docs/recipes/product-pipeline.md`.

### Inputs (read all of these)

1. `docs/PRD.md` — product authority (what / why).
2. Design artifacts under `docs/design-exports/` (and any paths listed in
   `docs/moonchild.md` if already partly filled).
3. This repo’s seams and defaults: `apps/mobile/lib/app-config.ts`,
   `lib/storage.ts`, `lib/purchases.ts`, `AGENTS.md` (no backend, no accounts
   unless stop-and-discuss).

### Your job (one pass)

Write or rewrite these files. Remove every `<!-- TEMPLATE_PLACEHOLDER -->`
sentinel from files you finish. Do **not** invent product scope or visual
design beyond the PRD and the exported artifacts.

1. **`docs/moonchild.md`**
   - Tool of record (Moonchild, Figma, etc.).
   - Project / file ids if known.
   - **Committed exports** path: `docs/design-exports/` (list what is there).

2. **`docs/screens-status.md`**
   - One row per screen/flow in the exports.
   - **Designed** = `yes` only when an artifact exists.
   - Artifact name / id / path column filled.

3. **`docs/design-spec.md`**
   - Faithful transcription of approved UX/UI from the artifacts + PRD
     constraints (IA, components, per-screen layout/states, a11y).
   - Do **not** redesign or add screens that are not in the exports.
   - Follow the section structure already in that file.

4. **`docs/build-spec.md`**
   - Compile once from PRD + design-spec + this repo.
   - Phases matching `docs/build-status.md` (0–8).
   - Tasks with clear acceptance criteria.
   - **Every task's acceptance criteria must end with:** “`docs/build-status.md`
     updated (current task, verification, any deviations).” The implementing
     model is a cheaper/faster one that follows per-task acceptance criteria far
     more reliably than a general instruction in `AGENTS.md` — and if the status
     file goes stale, the next session resumes from a false picture.
   - Do **not** add product requirements or redesign the UX.
   - Prefer existing `ui/` primitives and `lib/` seams.
   - Write each task in mailbox shape so it can be pasted into
     `.ai/current-task.md`: Goal, Scope, Out of scope, Acceptance criteria.
   - **Required Phase 2 tasks** (name them explicitly):
     1. Set `APP_CONFIG.MONETIZATION` and `STORAGE` in
        `apps/mobile/lib/app-config.ts` from the PRD. Leave
        `PURCHASES_MODE: 'mock'` until live keys exist.
     2. Replace or remove demo `app/(tabs)/index.tsx` and `library.tsx` per
        `screens-status.md`, including the Library tab in `(tabs)/_layout.tsx`.
     3. Rewrite `apps/mobile/maestro/smoke.yaml` for the product's real tabs
        (do not leave assertions on the demo Library CRUD).
     4. A later prune task listing unused `ui/` / seams the PRD will never
        use — do not delete inventory during screen work.

5. **`docs/build-status.md`**
   - Remove the template sentinel.
   - Set Current status to Phase 0 or Phase 2 as appropriate.
   - Check off Phase 0 / Phase 1 items that are done.
   - Leave implementation tasks unchecked.

### Explicitly out of scope for this pass

- Implementing screens or changing app code (except if `init-app` was
  already run — do not re-stamp identity).
- Authoring store metadata, brand masters, or EAS ids.
- Freestyle UI not present in the exports.

### When done

Report: files written, screen count, first incomplete build-spec task, and
any blockers (missing exports, PRD gaps, template-default conflicts).

---

## After the compile pass

1. Skim `docs/design-spec.md` and `docs/build-spec.md` for inventiveness —
   if the model added screens or features not in the PRD/exports, delete those
   parts and re-run or edit by hand.
2. Switch Cursor to **Composer 2.5 Fast**.
3. Planning model: copy the first incomplete build-spec task into
   `.ai/current-task.md` (Owner `cursor`, Status `ready-for-cursor`).
4. Implementing model: follow `AGENTS.md` → *Task loop* (mailbox, not
   self-serve from `build-spec.md`).
5. After review approval, assign the next task the same way.
6. Keep updating `docs/build-status.md` as tasks complete.

# AGENTS.md

Shared instructions for every AI agent working in this repo: what this project
is, and the rules that hold no matter which agent is working. Cursor reads this
file natively; `CLAUDE.md` imports it. Both agents get everything here.

Agent-specific *roles* live elsewhere — `CLAUDE.md` for Claude, `.cursor/rules/`
for Cursor. Those files describe how each agent works and how the two hand work
to each other; they never override the project rules here. Do not restate
project conventions in either of them.

## What this is

A local-first Expo template that ships the same product to the App Store,
Google Play, and a marketing lander. Cloned per app.

- `apps/mobile` — Expo Router app (the product)
- `apps/web` — static marketing lander + hosted privacy/terms
- `apps/product.json` — shared identity (name, URLs, contact email)
- `scripts/` — dev, store, and lander automation

**No backend.** Data lives on-device via `expo-sqlite`. Purchases go through
RevenueCat. If a feature needs accounts or server-side sync, stop and discuss
it rather than adding a backend.

## Authority hierarchy

When sources disagree, this is the order:

1. **This file** — repo invariants: no backend, the `lib/` seams, the "Ask
   before" list, security. These outrank the product spec. A PRD that needs
   accounts or server-side sync means *stop and discuss*, not implement.
2. `docs/PRD.md` — what the product must do, and why.
3. `docs/design-spec.md` plus the design artifact it points at — the approved
   UX/UI.
4. `docs/build-spec.md` — how it gets built: phases, tasks, acceptance criteria.
5. `docs/build-status.md` — current execution state.
6. Existing source code — what is actually there today.

`.ai/current-task.md` is not in this hierarchy. It is agent-to-agent messaging
about work already authorized by the build spec — never a source of
requirements. If it conflicts with anything above, the file above wins and the
task file is wrong.

Never silently override a higher authority. If the conflict is material, stop
and report it. If it is a minor implementation detail, make the smallest change
that preserves the higher-level requirement and record it under **Deviations**
in `docs/build-status.md`.

## Product & design reference

Build order for a product clone: finish `docs/PRD.md` (the only repo file
given to the design tool), generate the design system and flows in the design
tool, export artifacts into `docs/design-exports/`, then one strong-model pass
using the master prompt in `docs/recipes/compile-specs.md` fills
`docs/design-spec.md` + `docs/moonchild.md` + `docs/screens-status.md` +
`docs/build-spec.md` and initializes `docs/build-status.md`. Implement from
the build spec. Full loop: `docs/recipes/product-pipeline.md`.

There is **no** `docs/design-brief.md`. Kickoff prompts for the design tool
stay outside the repo (chat paste only).

- `docs/PRD.md` — authoritative for *what* to build. If a request goes beyond
  it, flag rather than expanding scope.
- `docs/design-spec.md` — the approved UX/UI as prose. Compiled **once** by a
  strong model from the PRD + committed (or MCP-pullable) design artifacts —
  a faithful transcription, not a redesign. Authoritative for design intent,
  states, and accessibility. After it exists, agents must not invent or extend
  it; if something needed is missing, stop and tell the user.
- `docs/moonchild.md` — the design tool of record for this clone, project ids,
  and/or paths to committed exports. Unfilled means no design source is linked.
- `docs/screens-status.md` — design inventory for this product. Treat
  **Designed** = `yes` as fact. Do not infer design readiness from memory or a
  vague MCP reply alone.
- `docs/build-spec.md` — phases, tasks, and acceptance criteria. Compiled once
  from the PRD + design spec + repo. Authoritative for *how* it gets built.
- `docs/build-status.md` — phase checklist and session handoff. Read it at
  the start of every session before doing anything else. Update Current
  status and Where we left off before ending a session, or whenever a phase
  (or meaningful chunk) is completed.

If any of these files still contains `<!-- TEMPLATE_PLACEHOLDER -->`, stop
and tell the user. Do not invent an MVP, design system, screen list, or build
plan.

Two carve-outs, both narrow:

1. The one-time strong-model **compile** pass that creates `design-spec.md` /
   `build-spec.md` / inventory docs from PRD + exports may clear those
   placeholders as it writes them.
2. Reading and ticking the **Phase 0–1 checklist** in `docs/build-status.md`
   while its own sentinel is still present is allowed — that is the bootstrap
   path described under Task loop below, not a licence to invent content.

What stays forbidden in both cases: inventing product scope, screens, design
tokens, or a build plan that the PRD and design exports do not support.

## Design system & design tool

An external design tool — recorded in `docs/moonchild.md` — owns the
**structured** design system (color roles, type scale, spacing) and
screen/flow layouts. The PRD is the only repo input to that tool. Repo token
files (`apps/mobile/global.css`, `ui/`) are the downstream sync of that system
for NativeWind — see Stack below.

`docs/design-spec.md` is the design *authority* in prose. It is not a
substitute for the artifact: prose is lossy next to a frame, so a screen still
needs its real design fetched before anyone writes its layout.

### Before writing any UI code

1. Confirm the target screen is listed in `docs/screens-status.md` with
   Designed = `yes`. If not, stop and tell the user — do not implement it.
2. Confirm `docs/design-spec.md` actually specifies that screen. If it is
   missing or too thin to implement from, stop and tell the user.
3. Retrieve the screen’s artifact — pull it from the design tool via MCP, or
   read an export committed to the repo.
4. If the pull fails, errors, returns nothing, or the design tool’s MCP is not
   available in this session and no committed export exists: stop and tell the
   user. Do not generate a layout yourself under any circumstance.

### When implementing a pulled screen

- Sync tokens from the design system into `apps/mobile/global.css` and `ui/`
  as needed. Components must use those tokens — never invent colors, spacing,
  or type, and never leave design values only inlined on one screen.
  After changing color tokens, run `npm run gen-theme` — `lib/theme-tokens.ts`
  is generated from `global.css` and feeds the tab bar, navigation chrome,
  bottom sheets, and charts. `npm run check` fails if it is stale.
- Adapt into this repo’s patterns (Expo Router, NativeWind, `ui/`
  primitives, `lib/` seams). Do not paste design-tool-generated code
  verbatim.
- The design tool is UI/UX only. Data modeling and on-device logic go through
  `lib/storage.ts` and the other seams as you implement each screen
  (Phase 4 in `docs/build-status.md`).
- Update `docs/build-status.md` (Where we left off / phase checkboxes).
  Update `docs/screens-status.md` only when the design inventory itself
  changes.

Design-tool MCP calls here are read/pull-only (fetch designs and tokens, not
modify anything external). Prefer leaving those tools on auto-allow rather
than confirming every pull during screen-by-screen builds.

Non-UI work (storage, purchases, copy) and edits to already-built screens
that only use already-synced tokens are allowed without a new design
pull — still no new freehand layouts or new screens.

## Stack

Expo SDK 56 · Expo Router · NativeWind v4 · React Native Reusables ·
Reanimated · RevenueCat · TypeScript strict.

- Styling is NativeWind classes. No `StyleSheet.create`.
- Colors come from CSS variables in `apps/mobile/global.css`. Never hardcode
  a hex value in a component.
- Type sizes come from `ui/text.tsx` variants. Never write `text-[15px]`.
- Prefer an existing `ui/` primitive over hand-rolling. Add new ones with
  `npx @react-native-reusables/cli@latest add <component>`.
- Animation is Reanimated. Do not use the legacy `Animated` API.
- Data lists use `@shopify/flash-list`, not `FlatList`. A fixed-length
  horizontal pager (e.g. onboarding slides) may keep `FlatList`.
- Never call `cssInterop` on a component a library also renders (for example
  Reanimated's `Animated.View`). It mutates that component globally. Register
  a private copy instead — see `ui/motion.tsx`.

## External docs

When Context7 MCP is available, use it for library/framework/SDK docs
(Expo, NativeWind, RevenueCat, etc.) before relying on training memory.
If Context7 isn’t available in the session, proceed normally.

## Seams — use these, don't go around them

| Need | Use | Not |
| --- | --- | --- |
| Persistence | `lib/storage.ts` | `expo-sqlite` directly |
| Purchases / entitlements | `lib/purchases.ts` | `react-native-purchases` directly |
| Error reporting | `lib/report-error.ts` | `console.error`, Sentry directly |
| Haptics | `lib/haptics.ts` | `expo-haptics` directly |
| Local reminders | `lib/local-notifications.ts` | `expo-notifications` directly |

**Lint-enforced.** `eslint.config.js` blocks these imports outside their seam
via `no-restricted-imports`, along with `StyleSheet` / `Animated` / `FlatList`
from `react-native` (see Stack above). It also blocks `console.error` /
`console.log` / etc. via `no-console` (with `console.warn` allowed) so errors
go through `lib/report-error.ts`. `npm run lint` fails on a violation. The seam
files themselves and tests are exempt; `app/onboarding.tsx` is exempt for
`FlatList` only; `lib/report-error.ts` is exempt for `no-console`. If you have
a genuine reason to bypass a seam, add an `eslint-disable-next-line` with that
reason rather than editing the config.

## Capability flags

`apps/mobile/lib/app-config.ts` holds the product's shape:

- `STORAGE`: `kv` (default) or `sql`
- `MONETIZATION`: `free` (default), `subscription`, or `one-time`
- `PURCHASES_MODE`: `mock` (default) or `live`
- `MOCK_ENTITLED`: drives locked/unlocked UI without any store account

`mock` mode means you can build and test the entire paywall before paying
Apple or Google anything. Keep it that way until the app is nearly done.

## Adding native capability

This template ships a deliberately small set of native modules. Camera,
location, microphone, motion, biometrics, and photo library are **not**
installed, because each one adds a permission prompt and an App Review
question. Add one only when the product actually needs it:

```
npx expo install expo-camera
```

Then add its config plugin to `app.json` and update
`apps/mobile/store/data-practices.json` if the data leaves the device.

See `docs/CAPABILITIES.md` for what each module costs in permissions, and its
"Starter kit vs shipped code" section for which unused modules are deliberate
inventory (do not delete them as dead code) versus prune-on-clone.

## Security

- No secrets in source, commits, or `EXPO_PUBLIC_*` variables. Those are
  compiled into the app bundle and readable by anyone who downloads it.
- Never log tokens, keys, or purchase receipts.
- Keystores and Play service-account JSON stay out of the repo.
- On-device data stays on-device unless the product explicitly adds a
  network feature.

## Ask before

- `eas build`, `eas submit`, `eas update`, `npx expo prebuild` — these cost
  money or are irreversible
- `web:deploy`, `store:push`, `domain-attach`
- Adding a dependency, a config plugin, or any backend service
- Committing or editing `apps/mobile/android/` or `apps/mobile/ios/` — those
  are generated, never hand-maintained
- Changing `android.package` or `ios.bundleIdentifier` after a store upload
- `git push`
- Shutting down the local stack (`npm run session:down`) — Metro, sims, and
  emulators may be in use by another agent

## Session teardown

Do **not** invent ad-hoc kill commands. Use the existing session script
(details: `scripts/dev/session.sh`):

```bash
npm run session:down              # Metro, iOS sim, Android emu, Gradle, adb
npm run session:down -- --watch   # same + re-kill for ~20s if agents relaunch
npm run session:status            # what's still running
```

## Task loop

At session start, read `docs/build-status.md` before anything else.

Then, per task:

1. Find the current phase and the next incomplete task in `docs/build-spec.md`.
2. Implement **only that task**, plus any prerequisite it directly requires.
3. Run the checks that task names (see Verify below).
4. Verify against the task’s acceptance criteria. Compiling is not passing.
5. Update `docs/build-status.md` — current task, verification, deviations.
6. Move to the next task only when the current one is genuinely complete.

Before `docs/build-spec.md` exists (Phase 0–1 — compiling specs from PRD +
design exports), work from `docs/build-status.md`’s phase checklist instead.
That is the one case where a missing build spec is not a stop.

Work on this template repo itself — hardening the scaffolding rather than
building a product in a clone — is not product work, and this loop does not
apply to it. Its backlog lives outside `docs/`. Do not fill in placeholders,
and do not record template work in `docs/build-status.md`; those files ship
blank to every clone. The sentinel rule above still stands for product work.

No unrelated refactors mid-task, and no reformatting untouched files. Reuse
existing `ui/` primitives, `lib/` seams, components, and dependencies before
adding anything new. Do not ask the user for information already in the repo.

On completion, report what changed, what was verified, any deviations, and the
next task. If blocked, name the specific blocker and the decision or
information needed to clear it.

## Verify

Run `npm run check` after edits (format, lint, typecheck, contrast, design
lint). Run `npm test` for logic changes. Run `npm run verify` before
considering work done. `npm run test:e2e` drives Maestro against a simulator.

## Delegate to a cheaper model

Default: hand mechanical work to a cheaper subagent — builds, tests, decided
fixes, renames, searches, logs, git, deps. That tier is Composer 2.5 in
Cursor and the `runner` agent (Sonnet) in Claude Code — never Haiku. Leave
Claude Code's built-in Explore alone. Keep the stronger model for
unknown-cause bugs, design trade-offs, purchase and entitlement logic, and
library internals.

If you can phrase it as "run X, then change Y to Z", delegate. If it
starts with "figure out why", don't.

Some work looks routine but stays on the stronger model anyway: implementing a
freshly pulled screen, purchase and entitlement logic, and any design
trade-off. Escalate back to the stronger model mid-task when:

- requirements conflict, or a higher authority contradicts a lower one
- an architecture decision has to be made rather than followed
- debugging is genuinely difficult
- implementation reveals a real problem in the PRD, design spec, or build spec

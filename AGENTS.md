# AGENTS.md

Shared rules for every agent in this repo. Cursor reads this file natively;
`CLAUDE.md` imports it.

A **role** is the hat for the whole chat. `/` means run that **skill** (a
playbook). Seats are fixed: Claude is thinker, Cursor is builder. Each app
has its own `/` menu. Do not tell Claude to open a Cursor skill file. The
agent picks the next allowed skill.

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

## Roles

| Role | Seat | Allowed skills | Forbidden |
| --- | --- | --- | --- |
| **thinker** | Claude Code | `/product` `/design` `/plan` `/review` | App code. `/code`. `/improve`. `/critic`. `/test`. `/harden`. Submit, pay, publish. |
| **builder** | Cursor | `/critic` `/code` `/improve` `/test` `/harden` | Invent the product. Rewrite `docs/PRD.md` or `docs/design.md`. `/review`. `/ship` unless Matt opened shipper. Invent a screen with no named export. |
| **shipper** | Matt opens this on purpose | `/ship` only | Feature work. Redesigning the product. |

`/critic` is Cursor only. Design critic is Grok only. `/review` is Claude
only. A chat must not review or rubber-stamp what it just wrote.

**Claude `/` menu** (`.claude/skills/`): `/product` `/design` `/plan`
`/review`. `/architecture` stays on disk for a shipped app that needs
`ARCHITECTURE.md`. It is not a first-app stage.

**Cursor `/` menu** (`.cursor/skills/`): `/critic` `/code` `/improve`
`/test` `/harden` `/ship`, plus `pull-design` and `maestro-e2e`

No `.agents/skills`. No role-folder tree under `.cursor/skills`. No
repo-wide role toggle.

## Authority

When sources disagree, this is the order:

1. **This file** — no backend, the `lib/` seams, the "Ask before" list,
   security, roles. These outrank the product. A product file that needs
   accounts or server-side sync means *stop and discuss*, not implement.
2. `docs/PRD.md` — what the product must do, and why. Filled by `/product`.
3. A named export in `docs/design-exports/` — the approved UX/UI.
4. `docs/design.md` — how we build it (storage, purchases, failures).
   Written by `/design`. Frozen once Matt agrees.
5. Existing source code — what is actually there today.

The **letter** (the work) lives in git: branch + commit. That is the
product file, `docs/design.md`, `docs/critic.md`, `docs/plan.md`, and
the code.

Never silently override a higher authority. If the conflict is material, stop
and report it. If it is a minor implementation detail, make the smallest
change that preserves the higher-level requirement.

After the first store ship, the running source is the living spec for what
the app actually does. Do not revert a correct fix to satisfy a stale doc.

If `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`, stop. Do not
invent an MVP, design system, screen list, or build plan.

## First-app path

v1 is one complete app: one PRD, one design, one critic, one plan, then
jobs. Do not restart product → design → critic per screen.

1. Claude `/product` until `docs/PRD.md` is filled.
2. Matt takes that file to a UI/UX tool. Drops exports in
   `docs/design-exports/`.
3. New Claude chat → `/design`. Writes `docs/design.md`. Cites export
   frames. No app code.
4. New Cursor chat → `/critic`. Writes `docs/critic.md`. Claude does
   not run `/critic`.
5. On FAIL: new Claude chat fixes `docs/design.md` from the critic
   findings. Cursor `/critic` again (appends a round). Max 2 rounds.
6. After PASS and Matt agrees: new Claude chat → `/plan`. Writes
   `docs/plan.md`.
7. New Cursor chat → `/code` on the next unchecked job
   (`code → test → improve → test`). Commit. Ask before `git push`.
8. New Claude chat → `/review` on that job. Starts from `docs/PRD.md`,
   the job's `AC-n`/`INV-n`, and the diff. On PASS, Claude checks the
   box. On FAIL, the job returns to Cursor.
9. Repeat 7–8 until `docs/plan.md` is complete.
10. Release gate: Cursor `/harden`, Claude whole-app `/review`,
    then `npm run verify` and `npm run preflight`. Matt opens `/ship`.

There is **no** `docs/design-brief.md`. Kickoff prompts for the design tool
stay outside the repo (chat paste only). Exports in `docs/design-exports/`
are first-class.

## Design system & screens

An external design tool owns the structured design system (color roles, type
scale, spacing) and screen/flow layouts. The PRD is the only repo file given
to that tool. Repo token files (`apps/mobile/global.css`, `ui/`) are the
downstream sync for NativeWind — see Stack below.

A frame beats prose. `design.md` is not a substitute for the export.

No new screen layout without the `pull-design` skill and a named export in
`docs/design-exports/`. If the pull fails, stop — do not invent a layout.
Non-UI work (storage, purchases, copy) and edits to already-built screens
that only use already-synced tokens are allowed without a new pull — still
no new freehand layouts or new screens.

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
- New files belong in `app/` (routes), `components/` (compose), `ui/`
  (primitives), or `lib/` (seams). Do not invent `features/`, `hooks/`, or
  `screens/` — lint and NativeWind now compile extra globs as a backstop,
  not as an invitation.

## External docs

When Context7 MCP is available, use it for library/framework/SDK docs
(Expo, NativeWind, RevenueCat, etc.) before relying on training memory.
If Context7 isn’t available in the session, proceed normally.

## Seams — use these, don't go around them

| Need | Use | Not |
| --- | --- | --- |
| Persistence | `lib/storage.ts` | `expo-sqlite` directly |
| Secrets / tokens | `lib/secure-storage.ts` | `expo-secure-store` directly, or `lib/storage.ts` |
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

The matcher (`scripts/lib/guard-deploy-match.sh`) is a speed bump for spend, push, deps, `session:down`, and hook bypass — not a security boundary. Common shell writes to guard files (`rm` / redirect / `tee` / `cp` / `mv`) are the same kind of bump. File-write hooks deny secrets and guard files, and pause on identity files and generated `ios/`/`android/`. The rest of this list is prose-only.

## Session teardown

Do **not** invent ad-hoc kill commands. Use the existing session script
(details: `scripts/dev/session.sh`):

```bash
npm run session:down              # Metro, iOS sim, Android emu, Gradle, adb
npm run session:down -- --watch   # same + re-kill for ~20s if agents relaunch
npm run session:status            # what's still running
```

## How to work

One skill outcome at a time. Do not also start the next job. A small
change requested in chat is not a planned job.

No unrelated refactors mid-task, and no reformatting untouched files. Reuse
existing `ui/` primitives, `lib/` seams, components, and dependencies before
adding anything new. Do not ask the user for information already in the repo.

On completion, report what changed, what was verified, any deviations, and
the next allowed skill. If blocked, name the specific blocker and the
decision or information needed to clear it.

## Verify

Run `npm run check` after edits (format, lint, typecheck, contrast, design
lint). Run `npm test` for logic changes. Run `npm run verify` before
considering work done. `npm run test:e2e` drives Maestro against a simulator.

## On-demand procedures

Skills load when the user names them in that app's `/` menu. Recipes in
`docs/recipes/` are the human source — do not paste them into always-on
files.

Still on disk and still valid:

- Pull a screen artifact (builder) — `pull-design`
- Maestro e2e — `maestro-e2e`
- Document today's code (Claude, on demand) — `/architecture`. Not a
  first-app stage.

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
- implementation reveals a real problem in the product file, a named export,
  or `design.md`

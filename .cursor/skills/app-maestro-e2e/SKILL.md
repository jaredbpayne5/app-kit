---
name: app-maestro-e2e
description: >-
  Runs Maestro e2e via project scripts with debug output contained.
  Use when running npm run test:e2e, maestro test, screenshots, or
  writing Maestro flows.
---

# Maestro e2e

Local only. CI does not run Maestro.

## Do this

1. `cd` to the repo root. Never run Maestro from `$HOME`.
2. Prefer project scripts:

```bash
npm run test:e2e
npm run test:e2e -- --mode=expo-go --flow=onboarding
npm run test:e2e -- --platform=android --mode=native
npm run test:e2e -- --port 8082
```

3. If you must call `maestro test` directly, pass `--test-output-dir` and
   `--debug-output` under `.maestro-debug/`. See the recipe.
4. Pass `--port` explicitly. Interactive port prompts fail unattended.

## Do not

- Rewrite the committed YAML (`apps/mobile/maestro/smoke.yaml`).
- Leave probe flows (`probe-*`, `task*`, `verify-*`) in the repo root.
- Put Maestro in default CI.

## Source

`docs/recipes/maestro-e2e.md` — modes, prerequisites, quirks.

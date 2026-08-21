# Backlog

Contract: docs/CONTRACT.md (frozen 2026-01-01)

- [x] 1. Add the reminder storage seam
      Done when: a reminder survives an app restart; INV-2.
      Files: apps/mobile/lib/storage.ts
      Tests: logic
      Deps: none
      Check: npm run check, npm test
      Notes: goes through lib/storage.ts, never expo-sqlite directly.

- [ ] 2. Show saved reminders on the home screen
      Done when: a saved reminder appears in the list after restart; AC-3.
      Files: apps/mobile/app/(tabs)/index.tsx, apps/mobile/components/reminder-row.tsx
      Tests: logic, screen
      Deps: job 1
      Check: npm run check, npm test
      Notes: named export home.png. Use FlashList, not FlatList.

- [ ] 3. Prove the reminder journey on a device
      Done when: create, see, and delete a reminder in one Maestro run; AC-4.
      Files: apps/mobile/maestro/smoke.yaml
      Tests: flow
      Deps: 1, 2
      Check: npm run check, npm run test:e2e
      Notes: no --allow-skip.

- [ ] 4. Update the lander copy for reminders
      Done when: the lander describes reminders in plain words.
      Files: apps/web/template/index.html
      Tests: none
      Deps: none
      Check: npm run check
      Notes: copy only, no behavior change, so no test tier applies.

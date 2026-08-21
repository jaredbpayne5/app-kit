# Performance: measure first, then fix one thing

**Do not add `useMemo`, `useCallback`, or `React.memo` because a render looks
expensive.** Each one costs a dependency array that can go stale, and most add
nothing. The rule for this repo is: measure, make the smallest change, measure
again, and revert the change if the number did not move.

That last clause is the one people skip. A speculative optimization that cannot
be shown to help is not neutral — it is added complexity plus a new correctness
risk, kept forever because nobody can prove it is useless.

## 1. Measure before touching anything

| Symptom | Tool |
|---------|------|
| Janky scroll or animation | Dev menu > Perf monitor; watch the JS thread FPS |
| Slow screen open | React DevTools Profiler; record the transition, read commit durations |
| Slow cold start | Time from launch to first interaction on a **release** build |
| Suspected re-render storm | Add a temporary render counter, or the Profiler's ranked chart |

Two rules that make the numbers mean something:

- **Measure a release build for anything start-up related.** Dev builds carry
  the bundler and the bridge in debug mode, so dev timings are fiction.
- **Measure on the slowest device you support**, not the simulator. A simulator
  uses your Mac's CPU and hides exactly the problems users report.

Write the number down before you change code. Without a before, there is no after.

## 2. Fix in this order

Cheapest and most effective first. Stop as soon as the number moves.

1. **Render less.** A list of 500 rows should use `@shopify/flash-list`, which
   this repo already requires over `FlatList`. Check `estimatedItemSize` is set
   and roughly correct — a wrong estimate causes blank flashes during scroll.
2. **Move work off the render path.** Parsing, sorting, or date formatting inside
   a component body runs on every render. Do it once where the data enters, or in
   the `lib/` seam that owns it.
3. **Move animation off the JS thread.** Reanimated worklets run on the UI
   thread, so a dropped JS frame does not stutter the animation. A `useState`
   updated per frame is the usual culprit.
4. **Cut image cost.** `expo-image` with a correctly sized source beats a 4000px
   asset scaled down in a 48px avatar.
5. **Only now consider memoization**, and only where the Profiler named the
   component. Re-measure. If the number did not move, take it back out.

## 3. Prove it, then keep it proved

Record the before and after in the job report. If the fix depends on a
non-obvious property (a stable callback identity, a keyExtractor that is really
unique), add a `logic`-tier test that fails when it breaks. A performance fix
with no test is a performance fix with a short life.

## 4. Things that are not performance problems

- A render that runs twice in development: React Strict Mode does that on
  purpose, and it does not happen in release.
- A one-off 200ms cost during a transition the user cannot perceive.
- Bundle size, unless you have measured start-up against it. Start-up is what
  users feel; the byte count is a proxy.

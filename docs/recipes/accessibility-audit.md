# Accessibility audit

Run this before a store submission, and after any job that adds a screen or a
new interactive element. `npm run check` only enforces a floor: it reports a file
that renders something tappable with no accessibility affordance anywhere. That
catches a whole unlabelled screen. It does not catch a badly labelled one.

## 1. What the automated checks already cover

| Check | Where | Catches |
|-------|-------|---------|
| Accessibility affordance present per file | `design-lint` section 8 (warn-only) | A new screen with zero labels |
| Label assertions on specific screens | `apps/mobile/__tests__/*-a11y.test.tsx` | A regression on a screen that has a test |
| Contrast of every token pair | `npm run contrast-check` | Body copy below AA |

Nothing above reads a label and asks whether it makes sense out of context. That
is this recipe.

## 2. Labels

Read every `accessibilityLabel` aloud with no surrounding UI. It must say what
the control does, not what it looks like.

| Bad | Good | Why |
|-----|------|-----|
| `"Button"` | `"Add reminder"` | Names the action |
| `"Trash icon"` | `"Delete reminder"` | Names the outcome, not the glyph |
| `"Tap here"` | `"Open settings"` | Screen readers already say "button" |
| `"X"` | `"Close"` | A glyph is not a word |

A `Pressable` wrapping visible `<Text>` usually needs no separate label — the
text is the label. Adding one that repeats the text makes VoiceOver say it twice.
An icon-only control always needs one.

## 3. Roles and state

- Interactive elements get `accessibilityRole` (`button`, `link`, `switch`,
  `header`).
- A toggle reports state with `accessibilityState={{ checked }}` — a label of
  `"Dark mode on"` that never changes is a lie once it is off.
- A disabled control reports `accessibilityState={{ disabled: true }}` rather
  than only looking faded.
- Decorative images get `accessibilityElementsHidden` / `importantForAccessibility="no"`
  so they are skipped, not announced as "image".

## 4. Touch targets

Apple asks for 44x44pt, Android for 48x48dp. Deliberately not linted: the size
often comes from padding on a parent, so a class-name check produces false
positives in both directions.

Check by hand on the small icon buttons — header actions, close buttons, and
list-row accessories are where this fails. Add `hitSlop` when the visual size
must stay small.

## 5. Device pass (the part that finds real bugs)

```bash
npm run open:ios          # or open:android
```

**iOS:** Settings > Accessibility > VoiceOver, then swipe right through every
screen.
**Android:** Settings > Accessibility > TalkBack.

Ask, on each screen:

1. Can you reach every control by swiping, without touching a specific pixel?
2. Does focus order match reading order, top to bottom?
3. When a sheet or dialog opens, does focus move into it — and does the content
   behind it stop being reachable?
4. After a destructive action, is the result announced, or does it feel silent?
5. With Settings > Display > Text Size at maximum, does any text clip or overlap?

## 6. Record the result

Add a `screen`-tier test asserting the labels you just fixed, so the fix cannot
silently regress. `apps/mobile/__tests__/onboarding-a11y.test.tsx` is the
pattern.

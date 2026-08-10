# Recipe — picking a brand palette from the catalog

Every palette below has been run through the same WCAG contrast math as
`scripts/dev/contrast-check.ts` (relative-luminance formula, AA threshold
4.5:1) for its Primary/Accent/Secondary-foreground pairs and its Text-on-
Background pair, using each palette's own ink/background colors as the
foreground candidates — the same approach that fixed a real contrast bug
in an earlier product build (a light cream `primary-foreground` on a
medium-brightness `primary` measured 2.71:1, failing AA on every default
button). Picking from here instead of inventing hex values from scratch
turns the single highest-variance creative step in kickoff into a
mechanical choice.

## How this fits Moonchild

Moonchild is the source of truth for the **structured** design system
(color roles, type scale, spacing) that ends up in `apps/mobile/global.css`
and `ui/`. This catalog is for **kickoff direction only** — feed mood and
hex into the design tool (via an external kickoff prompt, not a repo file) and brand assets, then let Moonchild specialize.
Do **not** paste catalog hex straight into `global.css` as final tokens
and skip Moonchild.

## How to use this during kickoff

1. From the PRD, form a one-line "mood" for the product (e.g. "calm,
   trustworthy, health-focused" or "bold, fast, dev-tools").
2. Pick the closest-matching palette below. If none fit, you may invent a
   new one — but then you **must** run `npm run contrast-check` before
   treating it as a safe starting point.
3. Copy the palette into:
   - The design tool kickoff prompt (outside the repo) — mood + these hex
     values under "Rough color direction" (still a *starting* direction for
     Moonchild, not final).
   - `apps/mobile/assets/brand/brand.json` — at least `background`,
     `primary`, `accent`, `secondary` (used by icon/splash generation).
   - Optionally `apps/product.json` `brandColor` if the lander needs a
     single brand swatch.
4. Do **not** shift hues "to make it feel more custom" before contrast is
   re-checked — the validation below was done against these exact values.
5. Each palette's `foreground` column tells you which color to use as
   `--primary-foreground` / `--accent-foreground` / `--secondary-foreground`
   **when you later sync Moonchild tokens** into `apps/mobile/global.css` —
   either the palette's own `background` hex or its own `text` hex,
   whichever the table says. Getting this backwards is exactly the mistake
   that caused the 2.71:1 bug mentioned above.
6. After Moonchild generates the design system, sync tokens into
   `global.css` / `ui/` per `AGENTS.md`. Re-run `npm run contrast-check`.

## The catalog

### 1. Forest & Brass — warm, natural, trustworthy
Avoid: the "cream + terracotta" cliché this mood usually defaults to —
this leans more saturated forest green to differentiate.

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#1F3D2E` | `background` (`#F6F2E9`) |
| Accent | `#C98A2E` | `text` (`#241F1A`) |
| Secondary | `#8F4D35` | `background` (`#F6F2E9`) |
| Background | `#F6F2E9` | — |
| Text / ink | `#241F1A` | — |

### 2. Midnight & Coral — modern, energetic, tech-forward

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#1B2A4A` | `background` (`#F7F6F3`) |
| Accent | `#E8664F` | `text` (`#1A1D26`) |
| Secondary | `#356969` | `background` (`#F7F6F3`) |
| Background | `#F7F6F3` | — |
| Text / ink | `#1A1D26` | — |

### 3. Slate & Amber — professional, calm, productivity

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#3E4C5E` | `background` (`#F5F6F7`) |
| Accent | `#D99A2B` | `text` (`#20262D`) |
| Secondary | `#426862` | `background` (`#F5F6F7`) |
| Background | `#F5F6F7` | — |
| Text / ink | `#20262D` | — |

### 4. Plum & Gold — premium, considered, wellness/finance

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#3B1F35` | `background` (`#F7F0EC`) |
| Accent | `#C79A3E` | `text` (`#241522`) |
| Secondary | `#8C5A6B` | `background` (`#F7F0EC`) |
| Background | `#F7F0EC` | — |
| Text / ink | `#241522` | — |

### 5. Ocean & Citrus — fresh, energetic, health/fitness

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#144D52` | `background` (`#F1F7F4`) |
| Accent | `#E07A3E` | `text` (`#132420`) |
| Secondary | `#5FA88A` | `text` (`#132420`) |
| Background | `#F1F7F4` | — |
| Text / ink | `#132420` | — |

### 6. Charcoal & Electric Blue — bold, technical, dev-tools

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#23262B` | `background` (`#F4F5F7`) |
| Accent | `#355BBE` | `background` (`#F4F5F7`) |
| Secondary | `#5A6472` | `background` (`#F4F5F7`) |
| Background | `#F4F5F7` | — |
| Text / ink | `#1B1D21` | — |

### 7. Terracotta & Sage — earthy, grounded, home/lifestyle

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#9C4A2E` | `background` (`#FBF3E7`) |
| Accent | `#536944` | `background` (`#FBF3E7`) |
| Secondary | `#C9A468` | `text` (`#2E2013`) |
| Background | `#FBF3E7` | — |
| Text / ink | `#2E2013` | — |

### 8. Berry & Cream — playful, warm, social/lifestyle

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#6B1F44` | `background` (`#FBF1E6`) |
| Accent | `#D9A441` | `text` (`#2A1420`) |
| Secondary | `#8A4F63` | `background` (`#FBF1E6`) |
| Background | `#FBF1E6` | — |
| Text / ink | `#2A1420` | — |

### 9. Pine & Copper — outdoors, rugged, utility

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#1E4034` | `background` (`#F5F1E4`) |
| Accent | `#8C4423` | `background` (`#F5F1E4`) |
| Secondary | `#8A9A6B` | `text` (`#1C2420`) |
| Background | `#F5F1E4` | — |
| Text / ink | `#1C2420` | — |

### 10. Indigo & Marigold — creative, curious, education

| Role | Hex | Foreground uses |
| --- | --- | --- |
| Primary | `#2E2A5C` | `background` (`#F6F4F7`) |
| Accent | `#E0A028` | `text` (`#1E1B33`) |
| Secondary | `#69638F` | `background` (`#F6F4F7`) |
| Background | `#F6F4F7` | — |
| Text / ink | `#1E1B33` | — |

## Dark mode

None of these palettes include a dark-mode variant — that's still a
judgment call per product (see `apps/mobile/global.css`'s `.dark:root`
block for the pattern: generally darken `background` significantly,
lighten `text`, and nudge `primary`'s lightness up ~4-8% so it still
reads against a dark surface). Prefer whatever Moonchild emits for dark
roles when available. Run `npm run contrast-check` after drafting
dark-mode tokens — it checks both themes.

## Related

- Product pipeline: `docs/recipes/product-pipeline.md`
- Brand assets / icon generation: `docs/recipes/brand-assets.md`
- Agent rules (Moonchild SSOT): `AGENTS.md`

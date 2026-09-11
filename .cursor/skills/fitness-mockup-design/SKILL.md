---
name: fitness-mockup-design
description: Design system, architecture and conventions for the fitness tracker wireframe mockup in wiremock/index.html. Use when adding or editing any screen, component, colour, data set or copy in this repo, when rendering screenshots of the canvas, or when the user mentions the mockup, wireframe, a screen name (Dashboard, Nutrition, Exercise, Plan, Log meal, Edit meals), or asks to add a new screen or state.
---

# Fitness tracker mockup

A multi-screen phone wireframe. Everything lives in one file: `wiremock/index.html`.
The PNGs beside it are generated output, not sources. This skill stays at the repo
root under `.cursor/skills/` so it is discovered regardless of which folder you are
working in.

## Hard constraints

1. **One file.** All CSS in the single `<style>`, all JS in the single `<script>` of
   `wiremock/index.html`. Never create a `.css` or `.js` file. The user asked for
   this explicitly.
2. **Never hardcode a displayed number.** Every figure on screen derives from a
   source array. If you type `622 kcal` into markup you have introduced a bug.
3. **Never duplicate a screen's markup.** Reuse the render function, share the
   generated HTML string, or clone the DOM (see Confirm dialog below).
4. Edit with the `StrReplace` tool. PowerShell file I/O corrupts the `·` and `→`
   characters used throughout.

## Canvas layout

`.canvas` is a flex row of `.column` lanes. Each lane is one feature; its
sub-screens stack downward **in flow order, not numeric order**.

| Lane | Screens |
|------|---------|
| 1 | Dashboard |
| 2 | Nutrition → remove entry → Log meal → searching → how much → edit meals → add food |
| 3 | Exercise |
| 4 | Plan → Weigh in → Build a plan |

The tab bar is four tabs (Dashboard / Nutrition / Exercise / Plan) and is written
out in each screen's markup, as the status bar is. A new screen copies both.

A screen is `.frame` (label + phone) wrapping `.phone` (390×844, `position: relative`).
Adding a lane means adding a `<div class="column">` sibling — verify div balance
afterwards, the nesting is easy to break.

## Data model

Source arrays, all indexed to the same 7 days ending `TODAY = 3 Sep 2026`:

- `LOG[]` — a day is `{ food: [ {t, n, p, c, f} | {t, n, w} ] }`, `null` = not logged
- `MEALS[]` — `{ n, items: [...same shape] }`
- `EX[]` — `{ steps, w: [ {t, n, k, min, kcal} ] }`, `null` = rest day
- `RESULTS[]` — search matches, each with a `src` provenance string

Derive with `kcalOfItem`, `totalOf(day, key)`, `kcalOf(day)`, `minsOf`, `minsOfKind`.
Calories are always `p*4 + c*4 + f*9` — never stored.

- `PROFILE` — `{ sex, age, height, weight, act }` behind the Plan screen, with
  `weight` read off the end of the Dashboard's weight series and `act` indexing
  `ACTIVITY[]`. Plan is the one screen that computes rather than records:
  Mifflin-St Jeor for resting metabolism, then the activity multiplier.
- `data[]` — the 14 weigh-ins the Dashboard charts, one a day ending `TODAY`, so
  `data[i]` is `TODAY − (13 − i)`. Weigh in reads its day and week changes out of
  it and `PHOTO_AT` indexes the few of them that have a progress photo.

- `PLAN` / `TARGETS` — `{ dir, months }` plus a target weight per direction, behind
  Build a plan. `maintenanceOf(PROFILE)` is the single entry point for what a day
  costs; both Plan and the builder call it, so a profile edit moves both.

Three globals are already taken at the top level of the script: `plus` and `minus`
are the shared glyphs and `target` is the Dashboard's weight trajectory. Do not
shadow them in a new block — a duplicate `const` at that scope is a parse error
that kills every screen, not just yours.

`renderPlan()` cascades into `renderBuild()`, so its first call sits at the foot of
the builder, after `PLAN` exists. Moving it back up puts that const in the temporal
dead zone and the whole script throws.

Goals: `KCAL_GOAL 2400`, `WATER_GOAL 2.5`, `MIN_GOAL 45`, `STEP_GOAL 10000`.
Bars are drawn against a fixed ceiling (`KCAL_SCALE 3200`, `MIN_SCALE 75`) so the
goal marker stays put when you switch days.

**Cross-screen agreement matters.** A search result feeds the portion screen which
feeds the projection bars. Thursday's two workouts are the two the Dashboard shows
ticked. Meal totals are summed from meal items. Keep it that way.

The Plan defaults are chosen so the whole app agrees: 36 / 180 cm / 82.4 kg / male
gives a 1,774 kcal BMR, and Heavy (×1.725) puts maintenance at 3,060. That is 660
above `KCAL_GOAL`, which at 7,700 kcal per kg is exactly the 0.6 kg a week the
Dashboard's target line is drawn at. Changing any default breaks that chain.

## Colour

Accents come from `THEMES` (`?theme=berry` swaps them). Roles are fixed:

| Var | Role | Used by |
|-----|------|---------|
| `--a1` | brand / primary data | carbs, cardio, activity heatmap, weight line |
| `--a2` | interactive | active tab, links, goal line, protein, strength |
| `--a3` | third series | fat, mobility |
| `--a4` | passive accumulation | water, steps |

Semantic: `--ink` `--muted` `--track` `--hair`.

`STATUS` = green `#16A34A` / yellow `#EAB308` / red `#DC2626` for **fills**.
`STATUS_TEXT` = darker variants for **small text** — the fill yellow fails contrast
at 9px, so never reuse it for a label.

**The sign flips between features.** On Nutrition, exceeding a goal is a miss and
turns red. On Exercise, exceeding it is the point: two states only (met / not met),
no red anywhere, and the bar runs past the goal marker instead of capping.

Purple, not pink. Pink read as a period tracker and was rejected.

## Component vocabulary

Reuse these before inventing anything.

**`.food` row** — the workhorse. Grid of `[control] [time] [name] [.d]`, where `.d`
stacks a primary figure over a muted detail line. Variants:
- `.pick` — plus button, used in pick lists (`pickRow()` builds these)
- `.logged` — minus button, used for entries already recorded

A minus is **always the leftmost thing in a row**. Nested lists indent by 32px
(one control width) so a child's minus sits inboard of its parent's.

**`.mrow`** — labelled progress bar (`[name] [.mtrack] [value]`). `.mtrack.split`
holds two fills: solid for current, `tint(colour, 0.35)` for a projected addition.

**`.toggle`** — collapsible section header with rotating `.chev`. Toggles
`hidden` on the element named by `data-target`.

**`.cta`** — full-width square black button pinned above the tab bar or home
indicator. One per screen, the primary action.

**`.note`** — grey rounded box with an (i) icon. Used for data provenance and
constraints only, never reassurance.

**`.scrim` / `.dialog`** — centred modal over a dimmed screen.

**`.day` / `.day .chip`** — the 7-day week strip. Colour-coded by status, dashed
outline when nothing was logged.

## Layout conventions

- `main` is `flex column; gap: 16px; padding: 20px`
- Sections hug content (`flex: 0 0 auto`); the entry list takes the remainder
  (`flex: 1 1 auto`)
- **No card borders outside the Dashboard.** Bordered widgets are the Dashboard's
  language; Nutrition and Exercise use plain stacked groups separated by hairlines.
- **No section titles** on the Nutrition/Exercise panels. They were removed to keep
  the day tight.

## Typography and copy

Archivo, with Archivo Black via `.display` for headlines, big numbers and buttons.
`h1` 28px. Small labels are 9px, weight 700, uppercase, letter-spaced.

- Screen titles are short declarative sentences: "Progress is built on the plate.",
  "Strength is built on repeat."
- Buttons say what they do: "Keep" / "Remove", not "Cancel" / "OK"
- Confirmations and notes name the consequence or the constraint. No filler.

## CSS traps hit in this file

The stylesheet is long and single-pass, so **later same-specificity rules win**.
Three bugs came from this; check before adding a modifier class:

- `.add` (black) overrode `.minus` (grey) → written as `.add.minus`
- `.toggle { padding: 0 }` silently killed `.mealhead`'s padding → `.toggle.mealhead`
- a bare `.chip` for portion buttons leaked into the week strip → renamed `.portion`

Avoid generic bare class names. Scope or double up.

## Rendering screenshots

```powershell
cd wiremock
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$url = "file:///$($PWD.Path -replace '\\','/')/index.html"
& $chrome --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=5000 `
  --force-device-scale-factor=1.5 --window-size=1800,6450 `
  --screenshot="$(Join-Path $PWD.Path 'mockup.png')" $url
```

The window has to be at least `40 + lanes * 430` wide or the last lane is clipped.

For a single-screen crop, re-shoot at `--force-device-scale-factor=2` and cut with
`Add-Type -AssemblyName System.Drawing`. In that 2x image a lane starts at
`x = 80 + laneIndex * 860`, the first screen's top edge is `y = 118`, and each
screen below it is `+1816`. Crop `800 × 1710`. When the screen you want is near the
top of its lane, shoot a short wide window (`--window-size=1800,1000`) rather than
the whole canvas. Verify the crop actually shows the intended screen — the offsets
shift whenever a screen is inserted.

Always look at the render before reporting a change as done.

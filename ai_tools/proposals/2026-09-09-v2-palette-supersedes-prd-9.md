---
title: Decide whether the v2 canvas palette replaces PRD §9
status: open
date: 2026-09-09
owner: product / design
tags: [design-system, blocker, theme]
links: []
---

## What

The **Onboarding v2 restyle** canvas and PRD §9 specify two different design
systems. Pick one.

| | PRD §9 / `AppTheme` | v2 canvas / `AppTokens` |
|---|---|---|
| Accent | Amber `#EF9F27`, **amber-forward** | Blue `#0B6BFF`, one flat accent |
| Structure | Teal `#0F6E56`, ink `#0E2F2B`, ice | Near-white `#F7F8FA`, ink `#0D0F12` |
| Depth | Material elevation | 1 px hairline, `elevation: none in-app` |
| Type | Poppins + Anek | General Sans + Noto Sans Tamil + JetBrains Mono |

## Why now

The login screens are built against the canvas, because that is what was handed
over to implement. So the app currently contains both: `AppTheme` still themes
`MaterialApp` and the placeholder home screen, while `AppTokens` styles the
login flow. That is tolerable for one flow and untenable for twenty.

## Cost of not doing it

Every screen built from here inherits the ambiguity, and the two systems drift
in opposite directions — amber-forward is not a tweak away from blue-accent.
The moment a screen mixes them, the fix stops being a token swap and becomes a
redesign.

CLAUDE.md §6 currently states the amber-forward rule as settled and says "do not
introduce a sixth colour without changing that document first". The canvas
introduces eleven. One of the two documents is now wrong.

## Options

1. **Preferred — the canvas wins.** It is newer, it is what was handed over for
   implementation, and its reasoning is explicit and device-aware (fill over
   border for scratched screens, near-white for sunlight, hairlines over
   shadows). Promote `AppTokens` into `AppTheme`, restyle the placeholder home,
   and update CLAUDE.md §6 and PRD §9 to match.
2. PRD §9 wins and the canvas is restyled to amber-forward. Costs the canvas's
   work and its device reasoning.
3. Leave both. Not a real option — it just defers the choice to whoever builds
   screen three.

## Decision

<!-- pending -->

## Note on fonts

Neither system's faces are bundled. `AppTheme` has a TODO for Poppins/Anek;
`AppTokens` has the same gap for General Sans (Fontshare, not Google Fonts).
The app currently renders in the platform font either way. Whichever palette
wins, the fonts are a separate ~1–2 MB decision against the 25 MB APK budget.

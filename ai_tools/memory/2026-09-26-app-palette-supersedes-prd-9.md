---
title: Colour comes from AppPalette — light and dark — not PRD §9 or the canvas tokens
status: active
date: 2026-09-26
decided_by: Shakthi (app palette handed over 2026-09-26)
tags: [design-system, theme]
supersedes: [../archives/2026-09-09-v2-palette-supersedes-prd-9.md]
superseded_by: []
links: []
---

## The rule

Every colour a screen uses comes from `AppPalette.of(context)` (or
`ShiftCardColors` for the shift card). No hex literals in `presentation/`, and
no new use of the PRD §9 amber/teal set or the `AppTokens` colour constants.

The palette's own rules are part of this decision:

- pastels (`sky`, `aqua`, `mint`, `lilac`) are surfaces only, never text;
- `sos` red is for the SOS control and safety escalation only — errors use
  `danger`;
- every listed text/background pair is ≥ 4.5:1;
- the shift card is identical in both themes: white body, blue band.

## Why

PRD §9 (amber-forward) and the onboarding canvas (`AppTokens`, `#0B6BFF`)
disagreed, and the proposal to pick one was still open. The app palette
resolves it with a single blue primary (`#1976D2` light / `#8FAEFF` dark) and,
new, a complete dark theme. A Partner can choose light, dark or "same as phone"
from Profile; the choice persists and applies without a restart.

Given up: PRD §9's amber-forward weighting. Pay figures no longer carry amber —
they carry weight and size instead.

## What it looks like in the code

- `lib/core/theme/app_palette.dart` — the values, as a `ThemeExtension`.
- `lib/core/theme/app_theme.dart` — maps them onto Material for both modes.
- `lib/core/theme/theme_controller.dart` — the persisted mode, restored before
  first render like the locale.
- `test/theme_test.dart` — fails if an edit breaks a 4.5:1 pair, or if
  `colorScheme.error` ever becomes the SOS red.

The login flow was migrated the same day: every colour reads from the palette
and follows the theme, except the language screen (S-01), which is dark in both
themes and reads `AppPalette.dark` directly — the Partner has not picked a theme
yet. `AppTokens` now holds shape, target and type only; its colour constants
are gone, so the old canvas blue cannot creep back in.

## When to revisit

When PRD §9 is rewritten to match, drop the "supersedes" framing. If a field
test shows dark mode is hard to read in direct sun, reconsider whether dark
should be offered at all versus only following the phone.

# presentation

Screens and blocs, one directory per feature.

**May import:** `presentation/`, `domain/`, `core/`, `l10n/`, and `app/` (for
`getIt`). **Not** `data/` or `sources/` — a screen never touches Drift, Dio, GPS
or the camera directly.

## The rules that matter here

**No hardcoded user-facing strings.** Every string a Partner can read lives in
`lib/l10n/app_en.arb` with a translator description, and has a Tamil counterpart
in `app_ta.arb`. Enforced two ways: `tool/check_conventions.dart` fails the build
on literals, and `test/l10n_parity_test.dart` fails it on missing translations.

**Layout survives Tamil.** No fixed-height text containers, no `maxLines: 1` on a
primary action, minimum 48 dp targets (NFR-06 — the theme enforces the floor, but
custom widgets have to honour it themselves). Tamil renders materially longer
than English; a pseudo-localisation build that inflates strings 40% is the way to
catch overflow before a Partner does.

**Blocs write to the outbox, not the network.** A tap on "accept" produces a
committed outbox row and an immediate UI response. It does not await HTTP. The
screen shows what was queued, not what the server confirmed — reconciliation
arrives later via sync.

**Client-side checks are for wording only.** Computing distance to the shift
location to decide *which message to show* is correct. Computing it to decide
whether check-in is *allowed* is not — the server does that (TRD §2.1, §7.3).

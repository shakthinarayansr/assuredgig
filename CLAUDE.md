# CLAUDE.md — AssuredGig (Worker App, Android)

> Persistent project context for Claude Code. Read before proposing architecture,
> writing features, or naming things. When something is ambiguous, default to the
> principles here and ask rather than guessing.

## Companion documents, in precedence order

All three live at the repo root. When they disagree, the one higher in this list wins.

| Doc | Owns | Status |
|---|---|---|
| `assuredcrew_pilot_brd_v2.md` | Pilot scope, business rules, open decisions | v2.0, 28 Aug 2026 — **supersedes** the v0.1 BRD set |
| `assuredcrew_pilot_prd_v2.md` | Screens, journeys, states, copy intent, design system | v2.0, 28 Aug 2026 — **supersedes** the v0.1 PRD set |
| `assuredgig_worker_app_trd_mvp.md` | How it is engineered: architecture, subsystems, API contract | v0.1, 10 Aug 2026 — **still valid**, see below |

**The TRD was not superseded.** PRD v2 says so explicitly: v2 changes *what* is built and *what it
looks like*, not *how* it is engineered. So the TRD remains authoritative on the outbox, the sync
engine, the attendance integrity subsystem, auth and the API contract — except where §7 of this
file records a v2 override.

This file is the *standing context and decisions*. Deviations recorded here are deliberate
amendments, not drift. Add new ones here rather than silently diverging.

---

## 1. What this repo is

**AssuredGig is the worker app: the Android app a worker uses to get and do shifts.**
Onboarding, profile, availability, offers, confirmations, attendance capture, history, safety,
support.

**It is one of three parts of the pilot system** (BRD §4.1), and the only one in this repo:

| Part | Where it lives |
|---|---|
| **Worker app** (AssuredGig, Android) | **This repo** |
| **Operations console** (web) | Not here. Separate build. |
| **Business channel** (AssuredCrew) | WhatsApp + ops phone. **No business app is built** (BRD §4.2) |

- **Backend and console are separate.** This repo consumes a REST/OpenAPI backend it does not own.
  The API contract it depends on is TRD §9.
- **Android only.** The `ios/`, `web/`, `macos/`, `linux/`, `windows/` directories are
  `flutter create` residue. Do not spend effort on them.
- **The console is the product for everyone except the worker** (PRD §7). Anything an operator
  does — matching, redeployment, replacement, verification, integrity adjudication,
  instrumentation — is console scope, not app scope. Do not build it here.

### ⚠ Unresolved: the relationship to `../assuredcrew`

The sibling repo `../assuredcrew` describes itself as a multi-flavour Flutter codebase for
partner + company + admin. **BRD v2 §4.2 says no business app is built**, and names the second
surface as a *web operations console*. These cannot both be true. Either `assuredcrew` is being
repurposed as the ops console, or it predates v2 and is stale. Resolve before either repo grows.
Until then: do not import from, mirror, or refactor across it.

### Vocabulary

BRD and PRD v2 say **worker** and **business** throughout, and every requirement ID is written
that way. The `assuredcrew` repo declares a 2026 rename to **Partner** / **Company**.

**Decision: use Partner and Company in code** — entity names, bloc names, route names, `.arb` keys.
Quote requirement IDs and document prose verbatim (`AUTH-07`, "worker app"). The two vocabularies
denote the same entities.

> Worth confirming, because it is now three documents against one convention, and renaming `.arb`
> keys after translation is the annoying kind of cheap.

---

## 2. The five things this app must get right

Everything else is scaffolding. If a change makes one of them weaker, it is the wrong change
regardless of what it improves.

1. **The outbox is the spine.** Every state-changing action is a row in one Drift outbox table with
   a stable idempotency key, never a direct API call from a bloc. Offline is the normal case, not
   the edge case. (TRD §5.2, §6 · CHK-04, now `[D]`)
2. **The attendance signal must be non-spoofable.** Accuracy-gated location, layered mock-location
   detection, the timing triple, direct-camera photo, presigned upload. Highest-risk area in the
   build and the reason the product exists. (TRD §7 · CHK-03, now `[D]`)
3. **The server decides; the client witnesses.** The client never decides eligibility, geofence
   pass/fail, no-show status, or score. Client-side checks pick a message string and are
   re-evaluated server-side. *A client that decides is a client that can be made to lie.*
   (TRD §2.1 · BR-04)
4. **Config, not constants.** Radius, windows, grace, thresholds, wage floors, geography and
   feature flags come from a versioned server config endpoint. Never compile them in.
   (TRD §2.4 · NFR-08, NFR-09)
5. **Safety outranks flow.** New in v2, and it is a *priority rule*, not a feature list: where a
   safety affordance and a conversion metric conflict, safety wins. SOS is one tap from every
   screen or it is not a safety control. (PRD §2.2 · NFR-10, SAFE-01)

### Corollaries worth stating

- **Idempotency keys are generated once at row creation and never regenerated on retry.**
- **Capture is durable before any network attempt** — photo on disk and outbox row committed
  before the app reaches for the network.
- **Attendance records are never dropped.** A permanently failing check-in escalates to ops.
- **Blocked check-ins are the most valuable telemetry in the product.** They distinguish a spoofing
  attempt from a GPS-poor shop. Both must reach ops.
- **The offline check-in state is a success state, not an error** (PRD §4.3). Neither the wording
  nor the visual treatment may resemble a failure. A worker who reads "failed" at a venue with no
  signal will retry, panic, or leave.
- **The integrity-flagged state does not accuse.** False positives on legitimate low-end devices
  are likely. Say the check-in needs review; ops adjudicates.
- **Business identity is not stored before acceptance** (BR-03). The server does not send it and
  the client has no field populated to leak.

---

## 3. Stack

Per TRD §3, with the deviations noted.

| Layer | Choice |
|---|---|
| Framework | Flutter stable, Dart 3 |
| State | `flutter_bloc` + `freezed` |
| DI | `get_it` + `injectable` |
| Routing | `go_router` |
| Network | `Dio` + generated OpenAPI client — **generated, never hand-written** |
| Local store | `Drift` (SQLite) — cache + outbox |
| Secure store | `flutter_secure_storage` — tokens only |
| Location | `geolocator` — foreground only |
| Camera | `camera` — direct capture, no gallery import |
| Push | `firebase_messaging` |
| i18n | `intl` + `.arb` — English default, Tamil selectable |
| Crashes | `firebase_crashlytics` — **deviation, see below** |

### Deviations from the TRD — decided, deliberate

- **Crashlytics instead of Sentry.** TRD §3/§14 specifies `sentry_flutter`. We use Firebase
  Crashlytics: already wired, already on Firebase for FCM, and a second vendor costs ~2 MB against
  a 25 MB APK budget for duplicate alerting. **The PII-scrubbing obligation carries over
  unchanged.** Everywhere the TRD says "Sentry", read "Crashlytics".
- **No behavioural analytics SDK** (TRD §14 stands, BRD NFR-07 reinforces). Do not add Firebase
  Analytics or any third-party SDK that phones home with user data.
- **No flavours.** TRD §16 assumes a multi-flavour codebase with `partner` as the only shipped
  flavour. This repo *is* the worker app; a flavour dimension buys nothing.

### Decided build config

- **`minSdk = 26`** (Android 8.0) — TRD T-1 / BRD Open Decision 8, resolved.
- **`targetSdk` / `compileSdk`** — current Play requirement at submission.
- **`applicationId`** — still `com.example.assuredgig`. Must change before any Play or release
  work; `android/app/google-services.json` is bound to it, so changing it means re-registering the
  Firebase Android app.

### Deferred, on purpose — do not add without a decision

- **Play Integrity attestation** (T-3) — fast-follow, not MVP.
- **Certificate pinning** (T-4) — self-inflicted outage risk at pilot scale.
- **Background sync worker** (T-5) — unreliable on budget Android with aggressive OEM battery
  management, and correctness does not depend on it (the server's grace-window job is authoritative
  for no-show). Accepted consequence: a worker who checks in offline and never reopens the app may
  sync late.

---

## 4. Architecture

Four layers, strict dependency direction downward, enforced by `tool/check_conventions.dart`:

```
presentation   screens, blocs
     ↓
domain         entities, use cases, state machine mirrors
     ↓
data           repositories, mappers
     ↓
sources        api (generated) · local (drift) · device (gps, camera) · secure store
```

- **Cache-first reads.** Every read returns cached data immediately, then refreshes. The shifts
  list must render from disk with no network, under 500 ms.
- **No business rule is duplicated from the backend into the domain layer.** The client mirrors the
  booking state machine only to render correct UI. Server state is truth on every sync.
- **Blocs do not call the API for writes.** They write outbox rows. The sync engine owns the
  network.

---

## 5. Current state of the repo

**Foundation is done.** The counter demo is gone, the §3 stack is installed, and the app builds and
runs on device.

- Build config: `minSdk 26` pinned explicitly, core library desugaring enabled (required by
  `flutter_local_notifications` for `java.time` below API 34).
- The four-layer structure under `lib/`, each layer carrying a `README.md` stating its rule.
  `app/` is the composition root; `core/` is cross-cutting.
- DI via `get_it` + `injectable`, awaited in `main` before `runApp`.
- `go_router` with named route constants, so deep links and pushes cannot drift apart.
- Theme carrying the v2 design system and enforcing the 48 dp target floor globally.
- `.arb` en/ta, locale restored before first render and switchable at runtime without restart or
  state loss.
- `tool/check_conventions.dart` — fails the build on hardcoded user-facing strings *and* on a layer
  importing upward. Both checks verified to actually fire.
- `.github/workflows/ci.yaml` — generate, format, analyze, conventions, test, debug APK.

Generated code (`*.g.dart`, `*.freezed.dart`, `*.config.dart`, `app_localizations*.dart`) is
**not committed**. After a fresh clone:

```
flutter pub get && flutter gen-l10n && dart run build_runner build
```

### Known loose ends

- **`applicationId` is still `com.example.assuredgig`.** Blocked on a decision.
- **`freezed` is on `4.0.0-dev.3`, deliberately.** Its stable line pins `analyzer <11` while
  `drift_dev` and `injectable_generator` require `^13`; no stable combination exists. Codegen is
  dev-only. Revisit when freezed 4.0.0 ships.
- **`flutter_secure_storage` held at 10.x.** 11.x pulls a `compileSdk 37` requirement, and the SDK
  ships that platform as `android-37.0` while Gradle looks for `android-37`.
- **Release builds still sign with the debug key.** Signing belongs to Codemagic (TRD §16).
- **There is no OpenAPI spec in this repo or a sibling.** Since the Dart client is generated and
  never hand-written, no networked feature can be finished until it exists. Work against a
  checked-in stub spec so the generator and the CI contract test are real from day one.

### Build order

1. **Foundation** — done.
2. **Outbox + sync engine, standalone** — schema, retry/backoff with jitter, FIFO-per-shift
   ordering, status machine. Unit-tested against a fake API *before any UI exists*.
   Idempotency-key stability across retries and no-duplicate-on-double-send are the tests that
   matter, and they are far easier to write now than through a screen.
3. **Auth + config** — phone/OTP, secure-storage tokens, single-flight silent refresh,
   device-bound single session, the terminal age gate. Then config and feature flags, so every
   later screen reads its thresholds from the server.
4. **Shifts, offers, confirmations** — cache-first reads, state-machine mirror, actions riding the
   phase-2 outbox.
5. **Attendance integrity** — the high-risk block, deliberately after the outbox is proven.
6. **Safety** — SOS, trusted contact. Small surface, high consequence; do not let it slip to last.
7. **Profile, availability, history, disputes, hardening** — then performance budgets and the test
   matrix on real hardware.

---

## 6. Conventions

- **Never hard-code user-facing strings.** English default, Tamil selectable at runtime without
  restart or data loss. CI fails the build on literal user-facing text.
- **Layout for Tamil from the start.** **Nothing containing text has a fixed height** (NFR-04).
  Indian scripts run **30–50% longer and taller** than the English source — this is the single most
  common cause of layout breakage in a product like this. No `maxLines: 1` on primary actions,
  minimum 48 dp targets. A pseudo-localisation build inflates strings to catch overflow before
  Tamil does.
- **Design for the real device**: 2 GB RAM, entry-level chipset, patchy 2G, weak GPS. Workers are
  mobile-first, vernacular-first, often low-to-moderate literacy — big targets, icons with labels,
  minimal typing. Assume the reader is slow, the sun is bright, the phone is cheap.
- **Never leave the worker without a next step.** Errors name the action, not the fault.
- **No city, wage or threshold is ever hardcoded.** Geography is a served hierarchy
  (state → district → city → locality); wage floors are config on a state-and-role pair
  (NFR-08, NFR-09).
- **No PII in logs, crash reports, or breadcrumbs** — scrub phone numbers, names, coordinates,
  tokens.
- **Photos go to app-private storage**, never external storage or the media store.
- **Location is collected at attendance events only**, foreground only. No background location.
  The Play data-safety declaration must match actual behaviour — and must be re-checked against
  the SOS decision below, because it changes the answer.

### Design system (PRD §9)

| Token | Hex |
|---|---|
| Ink | `#0E2F2B` |
| Teal | `#0F6E56` |
| Mint | `#1D9E75` |
| Amber | `#EF9F27` |
| Ice | `#CFE0DB` |

**AssuredGig is amber-forward** — amber carries pay figures and primary actions; teal recedes to
structure. Poppins for display; the Anek family for body and all Indian scripts.

### Performance budgets (TRD §13)

APK ≤ 25 MB · cold start ≤ 2.5 s on 2 GB RAM · shifts list from cache ≤ 500 ms with no network ·
check-in capture to durable commit ≤ 3 s excluding user photo time · photo payload ≤ 200 KB ·
peak memory ≤ 200 MB.

### Testing that is not optional

- Full offline check-in → airplane mode → reconnect → sync, asserting the original timestamp and
  location are preserved and a forced double-send creates nothing duplicate.
- **Session expiry must not destroy the outbox** — queued attendance survives re-auth.
- Rooted-device and mock-location-app runs, asserting block-and-report (not block-and-hide).
- The unhappy paths ops will actually hit: seat filled during accept, overlapping shifts, session
  superseded mid-shift, permanently failing upload.
- Tamil walkthrough of the full acceptance path, plus a pseudo-localisation build.

---

## 7. What v2 changed for this app

The TRD predates BRD/PRD v2. Where they differ, v2 wins on *what* is built. Concretely:

### Removed

- **`browse_enabled` is deleted, not defaulted off** (PRD §1, §10). The app is offer-driven. Do not
  build the flag, the fourth tab, or the two browse screens. TRD §9 still lists `browse_enabled` —
  that line is stale.
- **No home dashboard** — it would push expiring offers below a fold. The Shifts tab *is* the
  action list.

### Added — app scope the TRD does not describe

| Area | Requirement |
|---|---|
| **SOS** | One tap from *every* screen, persistent in the app bar. One confirm step (pocket triggers). On failure, show a dialable ops number in plain text. (SAFE-01, NFR-10, S-19) |
| **Trusted contact** | One nominated number. SMS fires **server-side on check-in**, not from the device. The screen must explain what is sent and when. (PROF-08, SAFE-02, S-20) |
| **Age gate** | 18+, verified against documents, never self-declared. Rejection is **terminal** — no appeal affordance, no "contact support". (AUTH-07, LEG-01, S-09) |
| **Student fit** | Recurring weekly availability pattern, date-range blackout windows, shift-duration filter. Pattern and blackout each settable in under 30 s. (PROF-05/06, OFFER-06, S-22/S-23) |
| **Recruitment source** | One fixed-list dropdown at signup. (PROF-04, S-07) |
| **Account deletion** | In-app request. **Google Play listing requirement — a launch blocker, not a feature.** (AUTH-09, S-31) |
| **Offer content** | Headcount ("You + 5 others booked"), end time given its own weight, duration badge, verified-venue mark, women-only mark. (OFFER-06/07/08, SAFE-04/05) |
| **Reliability standing** | Inactive during pilot (BRD §3). Showing a bare zero reads as a bad rating — say plainly that standing builds as shifts complete. (PROF-09, S-25) |

### Outbox row types

TRD §5.2 lists eight. v2 adds work that must ride the same table: availability pattern, blackout
windows, trusted contact, recruitment source, account-deletion request. Most fold into
`profile_update`; decide deliberately rather than by accident when building phase 2.

**SOS does not belong in the outbox.** A safety alert queued behind a retry backoff is not a safety
alert. It needs its own immediate path with a visible failure state and a dialable fallback.

### ⚠ Unresolved: does SOS capture location?

A direct conflict between two requirements, not an ambiguity:

- **CHK-08 `[D]`** — "Location requested only in the context of a shift. No tracking outside
  check-in and check-out." TRD §2.5 restates it as "foreground location at two events only".
- **SAFE-01 `[P]`** — SOS raises an alert "with last known location and shift context", from *any*
  screen, including when the worker is not on a shift.

The decided rule currently wins over the proposed one, so this must be resolved before SOS is
built. Two readings:

1. **Cached only.** SOS sends the location captured at check-in. Strictly honours CHK-08 and needs
   no declaration change — but off-shift, there is no location to send, which is plausibly when it
   matters most.
2. **Fresh capture on tap.** A third capture event, user-initiated and foreground. This is not
   tracking, but it *is* a third event: TRD §2.5, the CHK-08 wording, this file's conventions, and
   the **Play data-safety declaration** all have to change to match.

Principle 5 (safety outranks flow) points at option 2. It is not a decision to make silently.

### Screens

PRD §4 specifies S-01 to S-31 with their states, and §5 the seven journeys. That is the build
list — do not invent screens outside it. IA is three tabs (Shifts, History, Profile) plus shift
detail and attendance, one level deep, plus global SOS.

---

## 8. Open items

BRD §13 is the register of record. Engineering-owned, or blocking app work:

| # | Item | Status |
|---|---|---|
| 8 | Minimum supported Android version | **Resolved: API 26** |
| 5 | Geofence radius, check-in window, no-show grace, check-out grace | Config-served, so this is config not code. Lean: 150 m / 30 min before / 15 min grace |
| 4 | Identity documents in-app or offline | **Default while unresolved: offline. Build no capture screens.** Gates AUTH-07 mechanics and the whole DPDP surface |
| 6 | Late-hour threshold (transport, group deployment) | Config-served |
| 7 | Ratings individual or aggregate | Default: aggregate — less discouraging at pilot scale |
| 10 | Maps provider | Independent of GPS check-in, which is settled |
| 1, 2 | Labour-law opinions (women's night shifts; facilitator vs employer) | Ops guideline, not a system block, unless #1 resolves otherwise |

Carried from TRD §17: **T-6** face-verification threshold (server-side; define before check-in
ships) and **T-7** photo retention after sync (48 h, for dispute support).

Feature flags served from config: `reliability_visible`, `rating_display_mode`, `docs_in_app`.
Build the screens behind the flags, defaulted to the recommended branch, flippable without a
release. **`browse_enabled` is not among them — it is gone.**

---

### Maintaining this file

Update it when a decision changes, a deviation is added, or the repo's relationship to
`assuredcrew` shifts. It is the source of truth for *why*; the BRD/PRD/TRD are the source of truth
for *what*. Keep detail in those rather than duplicating it here.

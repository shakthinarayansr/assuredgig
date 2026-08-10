# CLAUDE.md — AssuredGig (Partner App, Android)

> Persistent project context for Claude Code. Read before proposing architecture,
> writing features, or naming things. When something is ambiguous, default to the
> principles here and ask rather than guessing.

**Companion doc:** `assuredgig_worker_app_trd_mvp.md` (repo root) is the Technical
Requirements Document. This file is the *standing context and decisions*; the TRD is the
*detailed specification*. Where they disagree, the deviations recorded in §3 below win —
they are deliberate amendments, not drift. Add new deviations here rather than silently
diverging from the TRD.

---

## 1. What this repo is

**AssuredGig is the supply-side Android app: the app a Partner uses to get work.**
Profile, shift offers, accept/decline, attendance confirmations, geo + photo check-in/out,
history, ratings, disputes.

**It is not the whole product.** The sibling repo `../assuredcrew` is the **demand side** —
the app Companies use to request staff. Two separate repos, two separate apps, one shared
backend. Do not import from, mirror, or refactor across `assuredcrew` — read it for business
context if useful, but this repo stands alone.

- **Backend and admin console are separate.** This repo consumes a REST/OpenAPI backend it
  does not own. The API contract it depends on is TRD §9.
- **Android only.** The `ios/`, `web/`, `macos/`, `linux/`, `windows/` directories are
  `flutter create` residue. Do not spend effort on them. Do not let a change be justified by
  "it also helps web".

### Vocabulary — use these, consistently

| Use | Not |
|---|---|
| **Partner** — the individual who works shifts | Worker, labourer, employee, user |
| **Company** — the business that requests staff | Business, client, employer, vendor |

The TRD's prose says "worker" and "business"; those are the older terms for the same
entities. Entity names, bloc names, route names, and `.arb` keys all use Partner/Company.
This matters most for `.arb` keys — renaming string keys after translation is the annoying
kind of cheap.

---

## 2. The four things this app must get right

Everything else is scaffolding around these. If a change makes one of them weaker, it is
the wrong change regardless of what it improves.

1. **The outbox is the spine.** Every state-changing action — accept, decline, confirm,
   cancel, check-in, check-out, profile update, dispute — is a row in one Drift outbox table
   with a stable idempotency key, never a direct API call from a bloc. Offline is the normal
   case, not the edge case. (TRD §5.2, §6)
2. **The attendance signal must be non-spoofable.** Location with an accuracy gate, layered
   mock-location detection, the timing triple, direct-camera photo, presigned upload. This is
   the highest-risk area in the build and the reason the product exists. (TRD §7)
3. **The server decides; the client witnesses.** The client never decides eligibility,
   geofence pass/fail, no-show status, or score. Client-side checks exist to pick a message
   string and are re-evaluated server-side. *A client that decides is a client that can be
   made to lie.* (TRD §2.1)
4. **Config, not constants.** Radius, time windows, grace period, accuracy thresholds and
   feature flags come from a versioned server config endpoint. Never compile them in. This is
   what lets open product decisions not block the build. (TRD §2.4, §9)

### Corollaries worth stating

- **Idempotency keys are generated once at row creation and never regenerated on retry.**
  Every write will eventually be sent twice; duplicate submission must be structurally
  incapable of becoming duplicate state.
- **Capture is durable before any network attempt.** The photo is on disk and the outbox row
  is committed before the app tries to reach the network.
- **Attendance records are never dropped.** A permanently failing check-in escalates to ops;
  it does not get discarded after N attempts like other row types.
- **Blocked check-ins are the most valuable telemetry in the product.** They distinguish a
  spoofing attempt from a GPS-poor shop. Both must reach ops.
- **Business identity is not stored before acceptance** (BR-03). The server does not send it
  and the client has no field populated to leak.

---

## 3. Stack

Per TRD §3, with the deviations noted. Nothing below is installed yet except Firebase — see
§5.

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
  Crashlytics: it is already wired up, we are on Firebase for FCM regardless, and a second
  vendor costs ~2 MB against a 25 MB APK budget for duplicate alerting. **The PII-scrubbing
  obligation carries over unchanged** — no phone numbers, names, coordinates or tokens in
  Crashlytics logs or keys. Everywhere the TRD says "Sentry", read "Crashlytics".
- **No behavioural analytics SDK** (TRD §14 stands). Crashlytics is for crashes and handled
  errors. The minimal event set in TRD §14 is the whole telemetry surface. Do not add
  Firebase Analytics or any third-party SDK that phones home with user data.

### Decided build config

- **`minSdk = 26`** (Android 8.0) — TRD item T-1, resolved. Below 26, notification channels
  and background execution limits diverge enough to cost real engineering time.
- **`targetSdk` / `compileSdk`** — current Play requirement at submission.
- **`applicationId`** — must be changed off `com.example.assuredgig` before any Play or
  release work. Note `android/app/google-services.json` is bound to it; changing it means
  re-registering the Firebase Android app.
- **Flavours** — the TRD (§16) assumes a multi-flavour codebase with `partner` as the only
  shipped flavour. Since this repo *is* the partner app, a flavour dimension buys nothing.
  Ship a single unflavoured app unless a second audience actually lands here.

### Deferred, on purpose — do not add without a decision

- **Play Integrity attestation** (T-3) — fast-follow, not MVP. Adds a Play dependency and a
  failure mode for legitimate low-end devices.
- **Certificate pinning** (T-4) — pinning against a managed origin with rotating certs is a
  self-inflicted outage risk at pilot scale.
- **Background sync worker** (T-5) — WorkManager on budget Android with aggressive OEM
  battery management is unreliable, and correctness does not depend on it (the server's
  grace-window job is authoritative for no-show). Accepted consequence: a Partner who checks
  in offline and never reopens the app may sync late.

---

## 4. Architecture

Four layers, strict dependency direction downward:

```
presentation   screens, blocs
     ↓
domain         entities, use cases, state machine mirrors
     ↓
data           repositories, mappers
     ↓
sources        api (generated) · local (drift) · device (gps, camera) · secure store
```

- **Cache-first reads.** Every read returns cached data immediately, then refreshes. The
  shifts list must render from disk with no network, in under 500 ms.
- **No business rule is duplicated from the backend into the domain layer.** The client
  mirrors the booking state machine only to render correct UI, and treats server state as
  truth on every sync. Server wins on all shift state.
- **Blocs do not call the API for writes.** They write outbox rows. The sync engine owns the
  network.

---

## 5. Current state of the repo

As of this file being written, the repo is a `flutter create` scaffold plus Firebase.
`lib/` contains only the stock counter demo in `main.dart` and `firebase_options.dart`.
None of the §3 stack is installed beyond `firebase_core` and `firebase_crashlytics`.
`minSdk` still inherits the Flutter default (24) and `applicationId` is still
`com.example.assuredgig`.

**There is no OpenAPI spec in this repo or a sibling.** Since the Dart client is generated
and never hand-written, no networked feature can be finished until that spec exists. Work
against a checked-in stub spec so the generator and the CI contract test are real from day
one, and replace it when the backend publishes.

### Build order

1. **Foundation** — build config, dependency set, four-layer structure, DI bootstrap,
   router, theme, `.arb` en/ta plus the CI lint that fails on literal user-facing text.
   That lint is worth having *before* there are strings to catch.
2. **Outbox + sync engine, standalone** — schema, retry/backoff with jitter, FIFO-per-shift
   ordering, status machine. Unit-tested against a fake API *before any UI exists*.
   Idempotency-key stability across retries and no-duplicate-on-double-send are the tests
   that matter, and they are far easier to write now than through a screen.
3. **Auth + config** — phone/OTP, secure-storage tokens, single-flight silent refresh,
   device-bound single session. Then config and feature flags, so every later screen reads
   its thresholds from the server.
4. **Shifts, offers, confirmations** — cache-first reads, state-machine mirror, actions
   riding the phase-2 outbox.
5. **Attendance integrity** — the high-risk block, deliberately after the outbox is proven.
6. **Notifications, history, disputes, hardening** — then the performance budgets and the
   test matrix on real hardware.

---

## 6. Conventions

- **Never hard-code user-facing strings.** English default, Tamil selectable at runtime
  without restart or data loss. A CI check fails the build on literal user-facing text.
- **Layout for Tamil from the start**: no fixed-height text containers, no `maxLines: 1` on
  primary actions, minimum 48 dp tap targets. A pseudo-localisation build inflates strings
  40% to catch overflow before Tamil does.
- **Design for the real device**: 2 GB RAM, entry-level chipset, patchy 2G, weak GPS. Not a
  flagship emulator. Partners are mobile-first, vernacular-first, and often
  low-to-moderate literacy — big targets, icons with labels, minimal typing.
- **No PII in logs, crash reports, or breadcrumbs** — scrub phone numbers, names,
  coordinates, tokens.
- **Photos go to app-private storage**, never external storage or the media store. Check-in
  photos must not appear in the gallery.
- **Location is collected at exactly two events**, foreground only. No background location.
  The Play data-safety declaration must match actual behaviour.

### Performance budgets (TRD §13)

APK ≤ 25 MB · cold start ≤ 2.5 s on 2 GB RAM · shifts list from cache ≤ 500 ms with no
network · check-in capture to durable commit ≤ 3 s excluding user photo time · photo payload
≤ 200 KB · peak memory ≤ 200 MB.

### Testing that is not optional

- Full offline check-in → airplane mode → reconnect → sync, asserting the original timestamp
  and location are preserved and a forced double-send creates nothing duplicate.
- **Session expiry must not destroy the outbox** — queued attendance survives re-auth.
- Rooted-device and mock-location-app runs, asserting block-and-report (not block-and-hide).
- The unhappy paths ops will actually hit: seat filled during accept, overlapping shifts,
  session superseded mid-shift, permanently failing upload.

---

## 7. Open items

Tracked in TRD §17. T-1 (minSdk) and the Sentry/Crashlytics question are resolved above.
Remaining, none of which block the build:

| # | Item | Current lean |
|---|---|---|
| T-2 | Geofence radius, windows, grace | 150 m / 30 min before / 15 min grace — server-configured, so this is config not code |
| T-6 | Face verification threshold and failure handling | Server-side; must be defined before check-in ships |
| T-7 | Photo retention window after sync | 48 h, for dispute support |
| T-8 | Push engagement threshold before SMS fallback | Server-configured |

Product decisions still open upstream are handled by **feature flags served from config**:
`browse_enabled`, `reliability_visible`, `rating_display_mode`, `docs_in_app`. Build the
screens behind the flags, defaulted to the recommended branch, flippable without a release.

---

### Maintaining this file

Update it when a decision changes, a TRD deviation is added, or the repo's relationship to
`assuredcrew` shifts. It is the source of truth for *why*; the TRD is the source of truth for
*what*. Keep detail in the TRD rather than duplicating it here.

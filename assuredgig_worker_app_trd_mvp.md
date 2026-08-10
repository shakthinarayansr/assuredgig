# Technical Requirements Document
## AssuredGig Worker App — MVP (Android)

| | |
|---|---|
| **Product** | AssuredGig worker application (`partner` flavour) |
| **Platform** | Android only, Flutter |
| **Status** | Draft v0.1 — for review |
| **Date** | 10 August 2026 |
| **Derived from** | BRD v0.1 and PRD v0.1, AssuredGig Worker App MVP |
| **Scope** | The Android client. Backend services and the admin console are separate documents; this specifies the contract the client depends on. |

Tags as per BRD: **`[D]`** decided, **`[P]`** proposed and needing a yes/no, **`[O]`** open fork.
Technical proposals in this document are `[P]` by default — they are engineering recommendations,
not agreed facts.

---

## 1. Purpose

Defines how the worker application is built: architecture, subsystems, the contract it expects from
the backend, and the integrity mechanisms that make the attendance signal trustworthy. The BRD says
the signal must be non-spoofable; **that requirement is almost entirely a technical one**, and
most of this document exists to satisfy it.

## 2. Governing technical principles

1. **The server is the authority; the client is a witness.** `[P]` The client captures evidence and
   presents outcomes. It never decides eligibility, geofence pass/fail, no-show status, or score.
   Client-side checks exist for user feedback only and are re-evaluated server-side. A client that
   decides is a client that can be made to lie.
2. **Every state-changing action is idempotent.** `[D]` (NFR-02, CHK-04) Offline queueing plus
   retries means every write will eventually be sent twice. Duplicate submission must be
   structurally impossible to turn into duplicate state.
3. **Capture durability precedes upload.** `[D]` (CHK-04) An attendance event is durable on disk
   the moment it is committed, before any network attempt.
4. **Configuration over constants.** `[D]` (Register #5) Geofence radius, time windows, grace
   period, accuracy thresholds and expiry warnings are server-supplied, never compiled in.
5. **Collect the minimum.** `[D]` (NFR-07, CHK-08) Foreground location at two events only. No
   background location, no analytics on personal content, no third-party SDK that phones home with
   user data.

## 3. Stack `[D]` unless noted

| Layer | Choice | Note |
|---|---|---|
| Framework | Flutter stable, Dart 3 | Shared codebase, `partner` flavour |
| State | `flutter_bloc` + `freezed` | Domain is state-machine heavy |
| DI | `get_it` + `injectable` | |
| Routing | `go_router` | Deep links from notifications |
| Network | `Dio` + generated OpenAPI client | Client is generated, never hand-written |
| Local store | `Drift` (SQLite) | Cache + outbox |
| Secure store | `flutter_secure_storage` | Tokens only (NFR-05) |
| Location | `geolocator` | Foreground only |
| Camera | `camera` | Direct capture, no gallery import |
| Push | `firebase_messaging` | |
| i18n | `intl` + `.arb` | English, Tamil |
| Errors | `sentry_flutter` | PII scrubbed |

**Minimum Android version:** `[O]` Register #6. **Recommendation `[P]`: API 26 (Android 8.0).**
Below 26, notification channels, background execution limits and Play requirements diverge enough
to cost real engineering time. API 26 covers effectively the entire active budget-device base in
2026. Below API 23 the runtime permission model differs and is not worth supporting.

**Target/compile SDK:** current Play requirement at submission. **`[P]`**

## 4. Architecture

Four layers, strict dependency direction downward. `[P]`

```
presentation   screens, blocs
     ↓
domain         entities, use cases, state machine mirrors
     ↓
data           repositories, mappers
     ↓
sources        api (generated) · local (drift) · device (gps, camera) · secure store
```

**Repository pattern with cache-first reads.** `[P]` Every read returns cached data immediately,
then refreshes. The Shifts screen must render from disk with no network (NFR-02).

**No business rule is duplicated from the backend into the domain layer** — the client mirrors the
booking state machine only to render correct UI, and treats server state as truth on every sync.
`[P]`

## 5. Local persistence

### 5.1 Cache tables `[P]`
`shifts` (offers and bookings, with status, times, pay, location, business fields nullable until
accepted per BR-03), `attendance` (local capture records), `profile`, `config` (server-supplied
thresholds), `strings_meta`.

**Business identity is not stored before acceptance.** `[D]` (BR-03) The server does not send it;
the client has no field populated to leak.

### 5.2 Outbox table `[D]`
The heart of offline behaviour (NFR-02, CHK-04).

| Column | Purpose |
|---|---|
| `id` | Local primary key |
| `idempotency_key` | UUID v4, generated at creation, never regenerated on retry |
| `type` | `accept_offer`, `decline_offer`, `confirm_shift`, `cancel_shift`, `check_in`, `check_out`, `profile_update`, `dispute` |
| `payload` | JSON |
| `media_path` | Local file path for check-in photo, null otherwise |
| `captured_at` | Device wall-clock at capture |
| `captured_elapsed_ms` | Monotonic since-boot at capture (see §7.4) |
| `attempts`, `next_attempt_at`, `last_error` | Retry control |
| `status` | `pending`, `in_flight`, `synced`, `failed_permanent` |

**Retry policy `[P]`:** exponential backoff with jitter, 5s base, capped at 15 minutes, unlimited
attempts while the record is attendance-related, 24-hour ceiling for others. Attendance records are
never dropped — a permanently failing check-in is escalated to ops, not discarded.

**Ordering `[P]`:** strictly FIFO per shift. A check-out cannot sync before its check-in.

## 6. Sync engine `[P]`

Triggers: app foreground, connectivity regained, successful auth, push received, and a periodic
timer while the app is foregrounded. **No background sync worker in MVP** — WorkManager scheduling
on budget Android devices with aggressive OEM battery management is unreliable, and the correctness
of the system does not depend on it (the server's grace-window job is authoritative for no-show).
`[P]`

**Consequence to accept:** a worker who checks in offline and never reopens the app may sync late.
Mitigated by: the check-in screen keeping the app foregrounded until sync or explicit dismissal,
and the sync-complete local notification (PRD §7).

**Conflict rule `[D]`:** server wins on all shift state. If a queued accept fails because the seat
is filled, the local record is marked resolved-superseded and the UI reconciles (PRD S-09).

## 7. Attendance integrity subsystem

This section satisfies CHK-01 to CHK-05 and CHK-08, and is the highest-risk area in the build.

### 7.1 Location acquisition `[P]`
Foreground-only, high-accuracy request with a timeout. **Accuracy gate:** reject readings above a
server-configured horizontal accuracy threshold (recommended default 50 m, tunable). Retry with a
visible attempt counter before failing. Capture: latitude, longitude, accuracy, provider, timestamp.

### 7.2 Mock and simulated location `[P]` CHK-03 — strongly recommended
Layered detection, all results attached to the payload and **evaluated server-side**:

- `Location.isFromMockProvider()` (API 18+) / `isMock()` (API 31+) on the reading itself.
- Developer options and "select mock location app" state where readable.
- Provider consistency: a fused reading that disagrees materially with a raw GPS reading.
- Plausibility: implied travel speed since the last known location; identical coordinates repeated
  to full precision across events.

**Client rejects and blocks** on a positive primary signal, per CHK-03, and **also transmits the
attempt** so ops sees it (a client that only blocks teaches the attacker what to bypass). Secondary
signals never block on their own — they are flags for server-side scoring, because false positives
on a real worker standing in a real shop are more costly than a missed spoof.

**Honest limitation `[P]`:** on a rooted device, no client-side check is conclusive. Root/integrity
attestation (Play Integrity) is the only durable answer and is **recommended as a fast-follow, not
MVP** — it adds a Play dependency and a failure mode for legitimate low-end devices. The mitigating
control for MVP is that spoofing requires deliberate setup and every attempt is visible to ops on a
small pilot roster.

### 7.3 Geofence and window evaluation `[D]` CHK-02
Client computes distance to the shift location and compares against server-supplied radius purely
to render the right message (PRD S-14). **The server re-evaluates on receipt and its verdict is
authoritative.** Values are `[O]` Register #5; recommended defaults for pilot `[P]`: radius 150 m,
check-in window opens 30 minutes before start and closes at the grace-window end, grace window 15
minutes after start (CHK-07).

### 7.4 Time integrity `[P]`
Device wall-clock is untrusted. Every capture records **three** values: device wall-clock,
monotonic elapsed-since-boot, and — on sync — server receipt time. The server derives the true
capture instant from elapsed-time delta and flags implausible skew. This is what makes CHK-04's
"preserve the original timestamp" safe rather than an invitation to change the clock and check in
from home.

### 7.5 Photo capture `[D]` CHK-01, `[P]` NFR-03
Direct camera only — no gallery selection, which would allow a stored photo. Front camera default
for the worker selfie. Downscale to a maximum dimension of 1080 px and JPEG quality ~70, targeting
under 200 KB per image. EXIF stripped of everything except orientation; location is transmitted as
structured data, not embedded metadata.

Face verification against the profile photo is a **server-side** concern; the client only supplies
the image. `[P]`

### 7.6 Upload sequence `[P]`
Offline-first ordering:

1. Photo written to app-private storage; outbox row committed. **Capture is now durable.**
2. On sync: request a presigned R2 URL; `PUT` the image directly to R2 — never through the API.
3. `POST` the attendance event with the object key, captured location, integrity signals and
   timing triple, carrying the `Idempotency-Key`.
4. On success, mark synced and delete the local image after a retention window `[P]` (48 hours,
   for dispute support).

Partial failure between steps 2 and 3 is safe: a re-run reuses the same key and the same object.

### 7.7 Check-in code fallback `[D]` CHK-05
Business-supplied code, validated server-side, available only on shifts flagged high-value.
Additional verification or fallback — never the sole route, and never a replacement for location
capture.

## 8. Authentication `[D]` AUTH-02, AUTH-04, AUTH-05

- Phone + OTP via MSG91 — short-lived access JWT + rotating refresh token. `[D]`
- Tokens in `flutter_secure_storage`; never in shared preferences, logs, or Sentry payloads.
  `[P]` (NFR-05)
- Silent refresh on 401, single-flight (concurrent 401s must not trigger parallel refreshes).
  `[P]`
- **Single active session** `[P]` (AUTH-05): the refresh token is bound to a device identifier;
  issuing a new one for the same account invalidates the prior. The displaced device receives an
  explanatory screen on next call, not a silent logout (PRD §10).
- **Session expiry must not destroy the outbox.** `[D]` Queued attendance survives re-auth; this is
  an explicit test case.
- SMS auto-read is optional; manual entry always available. `[P]`

## 9. API surface expected from the backend

The contract the client depends on. Endpoints are indicative; the OpenAPI spec is authoritative and
the Dart client is generated from it. `[P]`

| Purpose | Method | Idempotent | Notes |
|---|---|---|---|
| Request OTP | POST | — | Rate-limited server-side |
| Verify OTP | POST | — | Returns token pair |
| Refresh token | POST | — | Rotates; device-bound |
| Fetch config | GET | — | Radius, windows, grace, thresholds, feature flags |
| Get/update profile | GET/PATCH | Yes | Includes availability, distance, roles |
| List shifts | GET | — | Offers + bookings; business fields omitted pre-acceptance |
| Shift detail | GET | — | |
| Accept / decline offer | POST | **Yes** | Key required; conflict returns a distinct code |
| Respond to confirmation | POST | **Yes** | Evening / morning |
| Cancel booking | POST | **Yes** | With reason |
| Presigned upload URL | POST | — | Scoped to one object key |
| Check-in / check-out | POST | **Yes** | Full evidence payload |
| History | GET | — | Completed, no-shows, ratings |
| Raise dispute | POST | **Yes** | |
| Register push token | POST | Yes | On login and token refresh |
| Reliability summary | GET | — | Gated by Register #2 |

**Required server behaviours `[P]`:** `Idempotency-Key` honoured on every write above; distinct
error codes for seat-filled, shift-cancelled, outside-geofence, outside-window, integrity-rejected
and session-superseded, so the client can render the right message rather than a generic failure;
config endpoint versioned so thresholds can change without a release.

**Feature flags served from config, not compiled:** `browse_enabled` (Register #1),
`reliability_visible` (#2), `rating_display_mode` (#3), `docs_in_app` (#4). This is what keeps the
open decisions from blocking the build — the screens are built behind flags, defaulted to the
recommended branch, flippable without a release. `[P]`

## 10. Notifications `[D]` NOTIF-01–03

FCM with per-device tokens (not topics — every message is worker-specific). Data-only messages with
client-side rendering, so content is localised on device to the selected language `[P]` (NOTIF-03).
Deep links via `go_router` to the exact screen (PRD §7).

Android notification channels: **offers**, **shift reminders**, **urgent** (replacement, cancellation),
**system**. Separate channels let a worker mute the least critical without muting work. `[P]`

**MSG91 fallback is server-side.** `[D]` (NOTIF-02) The client's only obligation is accurate
delivery/engagement reporting so the backend can decide when to fall back.

## 11. Internationalisation `[D]` AUTH-01, `[P]` NFR-04

`.arb` files, English and Tamil, no hardcoded strings — enforced by a lint rule and a CI check that
fails on literal user-facing text. Locale persisted before first render; switchable at runtime
without restart or data loss (AUTH-03).

Layout rules `[P]`: no fixed-height text containers, no `maxLines: 1` on primary actions, minimum
48 dp targets (NFR-06), and a pseudo-localisation test build that inflates string length by 40% to
catch overflow before Tamil does.

## 12. Security and privacy `[P]` NFR-05, NFR-07

- TLS only; certificate pinning **deferred** — pinning against a managed origin with rotating certs
  is a self-inflicted outage risk at pilot scale.
- No PII in logs or Sentry breadcrumbs; scrub phone numbers, names, coordinates and tokens.
- App-private storage for photos; no external storage, no media-store registration (check-in photos
  must not appear in the gallery).
- Screenshot blocking not required; nothing displayed is more sensitive than the worker's own data.
- Data minimisation per NFR-07: location only at the two attendance events, retained locally only
  until synced plus the dispute window.
- Play data-safety declaration must match actual behaviour — location "collected, not shared",
  camera "collected, not shared", tied to identity.

## 13. Performance budgets `[P]` NFR-01

| Metric | Budget |
|---|---|
| APK size (download) | ≤ 25 MB |
| Cold start to first frame | ≤ 2.5 s on a 2 GB RAM device |
| Shifts list render from cache | ≤ 500 ms, no network |
| Check-in capture to durable commit | ≤ 3 s excluding user photo time |
| Photo payload | ≤ 200 KB |
| Memory | ≤ 200 MB peak on core flows |

Test device class: 2 GB RAM, entry-level chipset, Android 10 — the realistic pilot device, not a
flagship emulator.

## 14. Observability `[P]`

Sentry for crashes and handled errors. A minimal event set, no behavioural analytics SDK: app
open, OTP requested/verified, offer viewed/accepted/declined, confirmation responded, check-in
attempted/blocked-with-reason/committed/synced, check-out, sync failure, permission denied.

**Blocked check-ins are the most valuable telemetry in the product** — they distinguish a spoofing
attempt from a GPS-poor shop, and both need to reach ops.

## 15. Testing `[P]`

- Unit: outbox state transitions, retry/backoff, idempotency key stability across retries, distance
  and window computation, integrity signal assembly.
- Integration: full offline check-in → airplane mode → reconnect → sync, asserting original
  timestamp and location preserved and no duplicate created on forced double-send.
- Contract: generated client compiled against the OpenAPI spec in CI; a spec change that breaks the
  client fails the build.
- Device: check-in on the lowest-spec target device, outdoors, on 2G, with weak GPS.
- Localisation: pseudo-localisation build plus a Tamil walkthrough of the full acceptance path.
- Security: rooted-device and mock-location-app runs, asserting block-and-report behaviour.

**Test data must include the unhappy paths ops will actually hit:** seat filled during accept,
overlapping shifts, session superseded mid-shift, permanently failing upload.

## 16. Build and release `[P]`

Flutter flavours with `partner` as the only shipped flavour for this app. GitHub Actions for
analysis/test, Codemagic for signed Android builds. Firebase App Distribution for pilot testers,
then Play internal testing → closed → production. Version and build number derived from CI.

Crash-free session rate and check-in success rate are the two release-gate metrics. `[P]`

## 17. Technical open items

| # | Item | Recommendation | Blocks |
|---|---|---|---|
| T-1 | Minimum Android version (Register #6) | API 26 | Build config, device matrix |
| T-2 | Geofence radius, windows, grace (Register #5) | 150 m / 30 min / 15 min, server-configured | Nothing — config, not code |
| T-3 | Play Integrity attestation | Fast-follow, not MVP | Spoofing resistance ceiling |
| T-4 | Certificate pinning | Defer | — |
| T-5 | Background sync worker | Omit in MVP | Late-sync tolerance |
| T-6 | Face verification threshold and failure handling | Server-side; define before check-in ships | CHK-01 completeness |
| T-7 | Photo retention window after sync | 48 h | Dispute support (HIST-05) |
| T-8 | Push engagement threshold before MSG91 fallback | Server-configured | NOTIF-02 |

T-1 is the only item that must be answered before build starts; the rest are answerable during it.

## 18. Traceability

| BRD area | Satisfied by |
|---|---|
| AUTH-01–06 | §8, §11, PRD S-01–S-07 |
| PROF-01–05 | §5.1, §9, PRD S-04–S-06, S-21 |
| OFFER-01–06 | §6, §9, PRD S-08–S-10, flag `browse_enabled` |
| CONF-01–05 | §10, §9, PRD S-12–S-13 |
| CHK-01–08 | §7 in full |
| HIST-01–05 | §9, PRD S-18–S-20 |
| NOTIF-01–03 | §10 |
| SUP-01–02 | PRD S-23 |
| NFR-01–07 | §12, §13, §11, §5, §8 |
| BR-01–07 | §5.1 (BR-03), §9 (BR-04), server-side (BR-05–07); BR-01 satisfied by the absence of any payment code path |

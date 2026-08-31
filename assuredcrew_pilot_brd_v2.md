# Business Requirements Document
## AssuredCrew Pilot — v2.0

| | |
|---|---|
| **Entity** | Assured Works Technologies Pvt Ltd (proposed) |
| **Scope** | The complete pilot system: worker app, operations console, manual process |
| **Market** | Kanyakumari district, Tamil Nadu — launch city one of N |
| **Status** | Draft v2.0 — supersedes *AssuredGig Worker App BRD MVP v0.1* |
| **Date** | 28 August 2026 |

**Supersedes and consolidates:**
- AssuredGig Worker App BRD — MVP v0.1 (10 Aug)
- Registration, Login & Partner Profile BRD v0.1 (10 Aug)
- Safety & Segment Addendum v0.1 (24 Aug)

The three documents above remain valid for detail; this document is the single reference for
**pilot scope**, and where it conflicts with them, this document wins.

**Provenance tags** carry through unchanged:
- **`[D]` Decided** — locked. Reopening requires a scope change.
- **`[P]` Proposed** — derived from a decided principle, awaiting a yes/no.
- **`[O]` Open** — a genuine fork with no answer. Blocks what it sits on.

---

## 1. What changed since v0.1

Recorded explicitly, because several of these reverse earlier positions.

| # | Change | Effect | Tag |
|---|---|---|---|
| 1 | **Browse closed — offer-only** | Old Open Decision 1 resolved. The app is offer-driven. Marketing copy changes, not the product. Removes an ops approval queue from a pilot whose objective is *reducing* ops minutes. | `[D]` |
| 2 | **First segment chosen: events & weddings, then hospitality peaks** | Role list, bench composition and shop-visit targeting all follow from this. | `[D]` |
| 3 | **Standby is pooled, not per-shift** | Adds a redeployment capability to the ops console. Requires clustering by date, area and interchangeable role. | `[D]` |
| 4 | **Safety module added** | Women's pre-shift, on-shift and ops-rule requirements; student fit and a hard age gate. New scope, deliberately accepted. | `[P]` |
| 5 | **Pilot economics withdrawn** | No price, take rate or margin figure is stated anywhere. The pilot produces them. | `[D]` |
| 6 | **Platform is national, launch is local** | Geography becomes a data hierarchy with a live flag; no city may be hardcoded. | `[D]` |
| 7 | **SEO reclassified** | Not a pilot acquisition channel. The first bench is recruited by hand, which adds source tracking. | `[D]` |
| 8 | **Ops instrumentation added** | Minutes-per-fill and named-worker repeat requests must be captured, because they are the pilot's actual output. | `[P]` |
| 9 | **Entity named** | Assured Works Technologies Pvt Ltd owns both brands as trademarks. One company, not a holding structure. | `[D]` |

## 2. Purpose of the pilot

The pilot is **designed to falsify, not to earn.** It exists to answer four questions:

1. Will a business pay the premium a second time, unprompted?
2. What does the replacement guarantee actually cost, measured over ~50 shifts?
3. How many operations minutes does one filled shift consume?
4. Can a reliable worker be recruited and retained at the wage the market bears?

**Every requirement in this document either serves one of those questions or keeps the pilot
running.** Anything that does neither is out of scope, however reasonable it sounds. This is the
test to apply when someone proposes an addition.

Note that questions 2 and 3 are answered by ops with a stopwatch and a spreadsheet, not by
software. The product's job during the pilot is to make those measurements possible, not to
automate them.

## 3. Operating model — concierge

**A human runs the process; software records it.** `[D]`

Sourcing, matching, confirmation chasing, replacement and support are performed by the operations
team through an admin console and WhatsApp. The worker application is the worker's end of an
operator-run process — it is not a marketplace the worker navigates alone.

This has a consequence worth stating plainly: **the reliability score is inactive during the
pilot.** Every worker starts at zero, so matching is ops judgement, not algorithmic. The pilot
therefore validates the *promise* (a guaranteed fill is worth paying for) and not the *mechanism*
(scoring predicts attendance). Do not design as though the score is doing work it cannot yet do.

## 4. Scope

### 4.1 In scope

| Component | Description |
|---|---|
| **Worker app** (AssuredGig, Android) | Onboarding, profile, availability, offers, confirmations, attendance capture, history, safety features, support |
| **Operations console** (web) | Business and shift management, matching, redeployment, replacement, verification queue, alerts, instrumentation |
| **Business channel** (AssuredCrew) | WhatsApp plus ops phone. **No business app is built.** |
| **Manual process** | Documented ops runbook: sourcing, vetting, matching, chasing, replacement, measurement |

### 4.2 Explicitly not built

| Excluded | Reason | Tag |
|---|---|---|
| iOS application | Android-first market | `[D]` |
| Business mobile app | WhatsApp + console is sufficient at pilot scale | `[D]` |
| In-app payments, wallet, payouts | Wages out of MVP; Phase 2 as facilitator, not employer of record | `[D]` |
| Worker–business direct messaging | Protects against off-platform completion | `[D]` |
| Automated matching | Ops decides during pilot | `[D]` |
| Automated cascading re-offer on no-show | Ops-triggered replacement only | `[D]` |
| Self-service shift browse | Change #1 above | `[D]` |
| In-app identity document capture | See Open Decision 4 | `[O]` |
| Referrals, gamification, leaderboards, worker-to-worker features | Serve none of the four questions | `[D]` |
| Home dashboard | Would push expiring offers below a fold | `[D]` |
| Background location tracking | Trust, battery and privacy liability with no offsetting benefit | `[D]` |

## 5. Users

**Worker (primary).** Does day shifts in event service, catering, hospitality or retail. Earns
₹500–1,000 for a day shift in this market. Budget Android phone, intermittent connection, often
reads Tamil more comfortably than English. Scans for **pay, distance, date** in that order.

**Operations team.** Two to three people running the entire process by hand. Every worker action
must surface to them in time to act on a failure *before* the shift starts.

**Business (indirect).** Owner-manager of a catering firm, venue, hotel, restaurant or shop.
Reaches us by WhatsApp or phone. Never touches the software.

## 6. Segment and roles

### 6.1 Roles served at pilot `[D]`

| Priority | Segment | Why |
|---|---|---|
| Primary | **Events & wedding service** | Auspicious dates concentrate demand; pure headcount; cannot cope by working short |
| Second | **Hotel & restaurant peaks** | Predictable weekend and festival flow; recurring buyers test repeat behaviour faster |
| Seasonal | **Retail festival rushes** | Large dateable spikes at Pongal and Diwali; thin between |

**The three share one worker pool.** `[D]` A worker who serves at a wedding can work a restaurant
on Saturday and a shop floor at Diwali. That interchangeability is what makes a single pooled bench
viable — it is a requirement, not an observation. Roles that break it do not belong in the pilot.

**Excluded from pilot:** security (PSARA licensing), construction (the maistry system already
clears that market), care work (separate trust stack, later phase). `[D]`

### 6.2 Role data `[D]`

Roles are a configurable taxonomy, never hardcoded. A role record carries skill tier, shift shape,
wage band, and any equipment or dress requirement. Adding a role is data entry.

## 7. Functional requirements — worker app

### 7.1 Onboarding and identity (AUTH)

Detail in the *Registration, Login & Partner Profile BRD*; the pilot-relevant subset:

| ID | Requirement | Tag |
|---|---|---|
| AUTH-01 | Language selection on first launch, before any other screen — English and Tamil, each in its own script. | `[D]` |
| AUTH-02 | Authentication by mobile number and OTP via MSG91. No password is ever set. | `[D]` |
| AUTH-03 | One screen serves both registration and returning login; the worker is not asked to choose. | `[P]` |
| AUTH-04 | Before the number is entered, the screen states that joining is free and we never take a cut of pay. | `[P]` |
| AUTH-05 | One active device session per worker. A new sign-in ends the previous session. | `[P]` |
| AUTH-06 | Session persists across launches until explicit sign-out. | `[P]` |
| AUTH-07 | **Age verification: 18 or older, verified against identity documentation, not self-declared.** No exception path exists in the application. Rejection is a hard stop and must not be presented as appealable. | `[D]` — statutory (Child and Adolescent Labour Act); no responsible version of this product leaves it open |
| AUTH-08 | Explicit, separately recorded consent to receive operational messages by SMS and WhatsApp. | `[P]` |
| AUTH-09 | In-app account deletion request. | `[P]` — **Google Play listing requirement**; treat as a launch blocker, not a feature |

### 7.2 Profile and availability (PROF)

| ID | Requirement | Tag |
|---|---|---|
| PROF-01 | Name, photograph, home area, and roles willing to work. | `[D]` |
| PROF-02 | Home area selected from a list of areas within the live city, never free text. | `[P]` |
| PROF-03 | Photograph captured in-app, not selected from gallery. | `[P]` |
| PROF-04 | **Recruitment source recorded at signup** — referral, WhatsApp group, field recruitment, walk-in, other — from a short fixed list. | `[P]` — **new in v2.** The bench is hand-recruited; if referred workers show up better than cold ones, that is the cheapest reliability lever available and it changes how the bench scales. One dropdown, real answer |
| PROF-05 | Recurring weekly availability pattern — e.g. weekday evenings, weekends only — set once, not per shift. | `[P]` |
| PROF-06 | One or more date-range blackout windows during which no offers are sent. | `[P]` — serves students at exam time and anyone with a fixed commitment |
| PROF-07 | Maximum distance willing to travel. | `[P]` |
| PROF-08 | Nominated **trusted contact** — one phone number. | `[P]` — see SAFE-02 |
| PROF-09 | Worker can view their own reliability score with a plain-language explanation of what raises and lowers it. | `[P]` — transparency is what makes the score behaviour-changing rather than merely predictive. Note §3: the score does nothing during the pilot |

### 7.3 Offers (OFFER)

| ID | Requirement | Tag |
|---|---|---|
| OFFER-01 | Offers are created by ops and delivered by push, visible in the app. | `[D]` |
| OFFER-02 | An offer displays: role, **area (never street address)**, date, start and end time, duration, pay amount, requirements to bring or wear. | `[D]` |
| OFFER-03 | Accept or decline. | `[D]` |
| OFFER-04 | Offers carry an expiry; on lapse, ops is notified. | `[P]` |
| OFFER-05 | Declining optionally captures a reason from a short fixed list. | `[P]` — reason data is what improves matching |
| OFFER-06 | **Shift duration is visible and filterable**, distinguishing short shifts (3–4h) from full-day engagements. | `[P]` — a student fitting work around classes should not have to read every time range |
| OFFER-07 | **Confirmed headcount for the shift is shown on the offer.** | `[P]` — nobody should accept into an unknown group size; matters most for women evaluating a night shift |
| OFFER-08 | **Scheduled end time is shown prominently**, not only as part of a time range. | `[P]` |
| OFFER-09 | Business identity and precise location are not exposed before booking is confirmed. Area only. | `[P]` — protects against the match completing off-platform |

**Browse is not built.** `[D]` See change #1.

### 7.4 Confirmations (CONF)

| ID | Requirement | Tag |
|---|---|---|
| CONF-01 | Prompt to confirm attendance the evening before a booked shift. | `[D]` |
| CONF-02 | Prompt to confirm attendance on the morning of the shift. | `[D]` |
| CONF-03 | Prompts also delivered outside the app via MSG91, so a worker who has not opened the app is still reached. | `[D]` |
| CONF-04 | Non-response or negative response surfaces to ops **immediately**, so a replacement can be arranged before the shift starts. | `[D]` |
| CONF-05 | Worker can cancel a booked shift, with a reason, at any point before it starts. | `[P]` — an early honest cancellation is far cheaper than a no-show and must not be discouraged |

### 7.5 Attendance capture (CHK)

**This is the reliability signal.** Everything the product claims rests on it.

| ID | Requirement | Tag |
|---|---|---|
| CHK-01 | Check in at the shift location by capturing a photograph together with device location. | `[D]` |
| CHK-02 | Check-in permitted only within a geofence around the location and within a time window around shift start. | `[P]` — values `[O]` |
| CHK-03 | **Detect and reject mock or simulated location; flag the attempt to ops.** | `[D]` — promoted from `[P]` in v2. Spoofing is trivial on Android; without this the score can be silently falsified, which hollows out the only differentiator |
| CHK-04 | **Offline capture and queue**, transmitted when connectivity returns, preserving original capture time and location. | `[D]` — promoted from `[P]` in v2. Shops are where signal is worst; a failed upload would otherwise record a false no-show against a worker's income |
| CHK-05 | Business-supplied code available as fallback or additional verification on high-value shifts. | `[D]` — optional, not required on every shift |
| CHK-06 | Check out at end of shift, capturing location. | `[D]` |
| CHK-07 | A booked shift with no check-in by the end of the grace window is a no-show; ops notified. | `[D]` — window value `[O]` |
| CHK-08 | Location requested only in the context of a shift. No tracking outside check-in and check-out. | `[D]` |

### 7.6 Safety (SAFE)

New in v2. Full detail in the *Safety & Segment Addendum*.

| ID | Requirement | Tag |
|---|---|---|
| SAFE-01 | **One-tap SOS** from any screen, raising a flagged alert to ops with last known location and shift context. | `[P]` — pilot treatment can be simple: a flagged emergency that rings ops directly |
| SAFE-02 | **On check-in, an SMS is sent automatically to the worker's nominated trusted contact** with shift location, business name and scheduled end time. Triggered server-side, not from the device. | `[P]` — highest-leverage safety feature available: one field, one trigger, and someone outside the platform knows where she is without extra effort |
| SAFE-03 | **Missing check-out escalation.** Where check-out does not occur within a grace window after scheduled end, ops receives a **priority alert, distinct from and more urgent than a standard no-show flag.** | `[P]` — a missing check-in means someone didn't come; a missing check-out after a night shift means someone hasn't left. Different urgency, different queue |
| SAFE-04 | Businesses may flag a shift **women-preferred or women-only**. Business-initiated only; never inferred by the system. | `[P]` — a real commercial ask from event clients, and a booking advantage as much as a protection |
| SAFE-05 | Venue vetting status is visibly reflected on the offer, not merely true in the backend. | `[P]` |
| SAFE-06 | Where a shift extends past a defined hour, transport terms are part of the offer and visible before acceptance. | `[P]` — hour value `[O]` |

### 7.7 History and standing (HIST)

| ID | Requirement | Tag |
|---|---|---|
| HIST-01 | View upcoming booked shifts. | `[D]` |
| HIST-02 | View completed shifts with date, role, hours and pay. | `[D]` |
| HIST-03 | Ratings shown. | `[O]` — individually or as an aggregate; individual is more actionable, aggregate less discouraging |
| HIST-04 | No-shows visible to the worker with the recorded reason. | `[P]` — a worker must be able to see a mark that affects their income |
| HIST-05 | Worker can dispute a no-show or a rating. | `[P]` |

### 7.8 Notifications and support (NOTIF, SUP)

| ID | Requirement | Tag |
|---|---|---|
| NOTIF-01 | Push for: new offers, offer expiry, confirmation prompts, shift changes or cancellations, replacement requests. | `[D]` |
| NOTIF-02 | MSG91 fallback where push fails or the worker has not engaged. | `[D]` |
| NOTIF-03 | Notification content in the worker's selected language. | `[P]` |
| SUP-01 | Reach ops via WhatsApp from within the app. | `[D]` |
| SUP-02 | Report a problem against a specific shift. | `[P]` |
| SUP-03 | A support route staffed by a woman team member, for safety concerns a worker may not wish to raise otherwise. | `[P]` |

## 8. Functional requirements — operations console

Under-specified in v0.1, which treated the console as out of scope. At pilot the console **is** the
product for everyone except the worker.

| ID | Requirement | Tag |
|---|---|---|
| OPS-01 | Create and manage businesses, venues and shifts. | `[D]` |
| OPS-02 | Match workers to shifts manually, with the candidate list ordered by ops-relevant signals. | `[D]` |
| OPS-03 | Issue, withdraw and re-issue offers. | `[D]` |
| OPS-04 | See confirmation status for every upcoming shift at a glance, with non-responders surfaced first. | `[P]` — this is the primary no-show prevention surface |
| OPS-05 | **Redeploy a worker** — reassign an idle or checked-in worker from one shift to another mid-session. | `[P]` — **new in v2.** This is the operational primitive that makes pooled standby real. Cheap now, painful to retrofit |
| OPS-06 | Trigger a replacement for a no-show and track it to fill. | `[D]` |
| OPS-07 | Review queue for new worker registrations, with approve and reject plus reason. | `[P]` |
| OPS-08 | **Duplicate-account flagging** on name, photograph, area and device, for human review — never automatic action. | `[P]` — multiple SIMs are cheap; if a poor score can be discarded by re-registering, the score measures nothing. Shared devices are legitimate, so this is a review signal, not a block |
| OPS-09 | Mock-location and integrity flags surfaced for review. | `[P]` |
| OPS-10 | **Priority alert queue** distinguishing safety escalations (SAFE-01, SAFE-03) from routine operational alerts. | `[P]` |
| OPS-11 | **Log a named-worker repeat request** — when a business asks for a specific worker again. | `[P]` — **new in v2.** See §9 |
| OPS-12 | **Record ops handling time per fill.** | `[P]` — **new in v2.** See §9 |
| OPS-13 | Merge or link accounts identified as the same person, preserving combined history. | `[P]` |

## 9. Instrumentation — the pilot's actual output

New in v2, and the most commonly skipped section in documents like this. `[P]` throughout.

| ID | What is measured | Why it cannot be skipped |
|---|---|---|
| INST-01 | **Ops minutes per fill**, stopwatched end to end for at least the first 30 fills | Decides whether automation is optional or existential. Founder time counts even though you don't invoice yourselves |
| INST-02 | **Named-worker repeat requests**, logged by ops when they arrive by WhatsApp | In phase 1 no money flows through us, so a delighted business that hires our worker directly is indistinguishable from a churned one. **Repeat rate will read as failure when it is actually success.** This log is the correction |
| INST-03 | **Reason every business stops booking**, asked directly | Same reason as INST-02 |
| INST-04 | **No-show rate**, per worker and overall | Sets the true size of the standby bench, which sets the cost of the guarantee |
| INST-05 | **Standby utilisation** — how many standby workers were held versus deployed, per cluster | The pooled-bench ratio is assumed today; this replaces the assumption |
| INST-06 | **Recruitment source against subsequent reliability** | Tests whether referral is the cheap reliability lever it appears to be |
| INST-07 | **Fill rate and time to fill** | Basic operational health |

Nothing here needs to be a dashboard. A spreadsheet is sufficient and probably better. The
requirement is that the data exists and is captured consistently, not that software presents it.

## 10. Business rules

| ID | Rule | Tag |
|---|---|---|
| BR-01 | No payment is processed in the application. Payment between business and worker occurs outside the platform. | `[D]` |
| BR-02 | No direct messaging channel between worker and business. | `[D]` |
| BR-03 | Business identity and precise location are not exposed to the worker before booking confirmation. | `[P]` |
| BR-04 | Matching is performed by ops. The application presents outcomes; it does not decide them. | `[D]` |
| BR-05 | A no-show is recorded against the worker's reliability score. | `[D]` |
| BR-06 | Replacement is initiated by ops, not automatically by the system. | `[D]` |
| BR-07 | The business receives a free replacement on a no-show, at best-effort speed, with a personal call from ops. Service-level windows and credits are a later phase. | `[D]` |
| BR-08 | A worker is never charged for registration, verification, access to shifts, or any platform function. | `[D]` |
| BR-09 | One mobile number maps to one worker account; one worker holds one account. | `[P]` |
| BR-10 | Reliability history attaches to the worker, not the phone number, and survives a device change. | `[P]` |
| BR-11 | Only vetted, active accounts receive offers. | `[P]` |
| BR-12 | **Ops shall not match a lone woman into a shift ending after a defined hour unless at least one other AssuredGig worker is booked on the same shift.** This applies regardless of whether the worker herself would accept a lone booking — it protects ops from being asked to make an exception under pressure. | `[P]` — pending Open Decision 1, may become a hard system constraint rather than an ops guideline |
| BR-13 | Age verification is a precondition of an active account. There is no active account without it. | `[D]` |
| BR-14 | Women-preferred/women-only is set by the business at posting time and never inferred. | `[P]` |

## 11. Non-functional requirements

| ID | Requirement | Tag |
|---|---|---|
| NFR-01 | Usable on low-end Android without perceptible lag on core flows. | `[D]` |
| NFR-02 | Tolerates intermittent connectivity: viewing booked shifts and initiating check-in work offline, syncing on reconnection. | `[D]` |
| NFR-03 | Photographs compressed on-device before upload; data usage modest on metered prepaid plans. | `[P]` |
| NFR-04 | All interface text externalised for translation. **No layout may assume Latin text metrics** — Indian scripts run 30–50% longer and taller. Nothing containing text has a fixed height. | `[P]` — required by the Tamil-first, then South-Indian-languages roadmap |
| NFR-05 | Authentication tokens in secure device storage. | `[P]` |
| NFR-06 | Interactive targets ≥48dp, high contrast, usable outdoors and by workers who read slowly. | `[P]` |
| NFR-07 | Personal data limited to what the service requires; location captured only at attendance events. | `[P]` |
| NFR-08 | **Geography is a data hierarchy** — state → district → city → locality, with coordinates, service radius and a live flag. **No city name is hardcoded anywhere.** | `[D]` — adding a city must be a data commit, not a migration |
| NFR-09 | **Wage floors are configuration attached to a state-and-role pair**, never a constant. Minimum wages are notified per state, per employment, per skill grade. | `[D]` |
| NFR-10 | SOS reachable in one tap from any screen, never buried in settings. | `[P]` |

## 12. Legal and compliance constraints

Stated as requirements because they shape the build, not as background.

| ID | Constraint | Tag |
|---|---|---|
| LEG-01 | **Under-18 workers cannot be engaged** in the categories this platform staffs. No parental-consent exception applies. Hard gate at registration. | `[D]` |
| LEG-02 | **Women's night-shift conditions** — group size, transport, written consent — are governed by state Shops and Establishments rules and vary by state. **A labour-law opinion is required before the first night shift involving a woman is matched**, not before a later phase. | `[O]` — blocks BR-12, SAFE-06 |
| LEG-03 | Our position is **facilitator, not employer of record**. Ops selects workers, influences pay, scores performance and penalises no-shows — a meaningful degree of control. This needs testing against PF/ESI and deemed-employment risk. | `[O]` |
| LEG-04 | If identity documents are collected, DPDP Act obligations arise. This is part of the same decision as Open Decision 4. | `[O]` |
| LEG-05 | Both brands are trademarks owned by a single company. Class 35 (employment agency and staffing services). | `[D]` |

## 13. Open decisions register

| # | Decision | Blocks | Owner |
|---|---|---|---|
| 1 | **Labour-law opinion: women's night-shift conditions, per state** | BR-12, SAFE-06, and whether night rules are ops guidance or hard system constraints | Founders + labour counsel |
| 2 | Facilitator vs deemed-employer status; PF/ESI exposure | LEG-03, and Phase 2 design | Founders + CA + labour counsel |
| 3 | How money moves in Phase 2 (the step-6 decision) | Confirms BR-01 holds; gates payouts | Founders |
| 4 | Identity documents — captured in-app or handled offline by ops | AUTH-07 mechanics, OPS-07, LEG-04, and the whole data-protection surface | Founders |
| 5 | Geofence radius, check-in window, no-show grace period, check-out grace period | CHK-02, CHK-07, SAFE-03 | Founders + ops |
| 6 | The "late hour" threshold triggering transport and group-deployment rules | SAFE-06, BR-12 | Founders + counsel |
| 7 | Ratings shown individually or in aggregate | HIST-03 | Founders |
| 8 | Minimum supported Android version | NFR-01 | Engineering |
| 9 | Per-role wage bands for Kanyakumari | Offer content, bench recruitment, site copy | Founders — **needs field data** |
| 10 | Maps provider | Independent of GPS check-in, which is settled | Engineering |

## 14. Acceptance criteria

The pilot system is accepted when all of the following hold.

**Worker journey.** A worker who has never used the application can, in Tamil, unaided, on a slow
connection: choose their language, understand before entering anything that the platform is free,
register with their mobile number, complete a profile, be verified, receive an offer, accept it,
respond to both confirmation prompts, check in at the location with a photograph, check out, and
see the completed shift in history.

**Safety.** She can nominate a trusted contact who is notified automatically on her check-in, and
reach an SOS action in one tap from anywhere in the app.

**Student fit.** A worker can set a recurring availability pattern and a blackout window in under
30 seconds, and receives no offers during that window.

**Age gate.** No worker under 18 can reach an active account by any path.

**Operations.** Ops can see every worker event in the console in time to act on a failure **before
the shift starts**; can redeploy a worker between shifts; receives a priority alert distinct from a
routine no-show when a check-out is missed; and can log a named-worker repeat request and record
handling time per fill.

**Instrumentation.** At the end of the pilot, the four questions in §2 can be answered with recorded
data rather than recollection.

## 15. Glossary

**Shift** — a single time-boxed engagement at one business. **Offer** — a shift presented to a
specific worker. **Booking** — an accepted offer. **Check-in** — the geolocated, photographed
arrival event. **No-show** — a booking with no check-in by the end of the grace window.
**Replacement** — a substitute booking created after a no-show. **Reliability score** — the derived
measure of a worker's attendance and performance history. **Concierge** — a process performed by a
human operator that will later be automated. **Cluster** — shifts grouped by date, area and
interchangeable role, across which one standby bench can serve. **Redeployment** — moving an idle
or checked-in worker from one shift to another mid-session.

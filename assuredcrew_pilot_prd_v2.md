# Product Requirements Document
## AssuredCrew Pilot — v2.0

| | |
|---|---|
| **Entity** | Assured Works Technologies Pvt Ltd (proposed) |
| **Scope** | Worker app (AssuredGig, Android) + Operations console (web) |
| **Status** | Draft v2.0 — supersedes the v0.1 PRD set |
| **Date** | 28 August 2026 |
| **Derived from** | AssuredCrew Pilot BRD v2.0 |

**Supersedes:** AssuredGig Worker App PRD v0.1, Frontend PRD v0.1, and the console-shaped portions
of the Backend PRD v0.1. The Backend and Frontend **TRDs** remain valid — this document changes
*what* is built and *what it looks like*, not *how* it is engineered, except where noted in §1.

**Ownership boundary.** This document owns screens, journeys, states and copy intent. It does not
own validation logic, threshold values or scoring definitions — those belong to the backend
documents and are referenced here, never restated. Any value appearing in this document is
illustrative and served from configuration at runtime.

**Tags:** **`[D]`** decided · **`[P]`** proposed, needs a yes/no · **`[O]`** open fork.

---

## 1. What changed since v0.1

| # | Change | Product effect |
|---|---|---|
| 1 | **Browse closed** | The `browse_enabled` flag and the fourth tab are removed, not defaulted off. Two screens deleted. Website copy changes instead. |
| 2 | **Safety module added** | New: SOS affordance, trusted contact, headcount and end-time on offers, missing-check-out escalation. Affects 6 screens. |
| 3 | **Student fit added** | New: availability pattern, blackout windows, duration filter. Affects 3 screens. |
| 4 | **Age gate hardened** | Registration gains a terminal rejection state that must not read as appealable. |
| 5 | **Recruitment source captured** | One field added to onboarding. |
| 6 | **Ops console promoted to first-class** | v0.1 treated it as out of scope. At pilot it is the product for everyone except the worker. §7 is new. |
| 7 | **Redeployment** | New console capability; the primitive that makes pooled standby work. |
| 8 | **Instrumentation surfaces** | Repeat-request logging and per-fill timing become console affordances. |
| 9 | **CHK-03 and CHK-04 promoted to `[D]`** | Mock-location detection and offline queueing are no longer optional. Affects the attendance flow's error states. |

## 2. Product principles

Tie-breakers, in priority order, for questions no requirement answers.

1. **The signal is sacred.** `[D]` Any trade-off between convenience and check-in integrity resolves
   toward integrity.
2. **Safety outranks flow.** `[P]` **New in v2.** Where a safety affordance and a conversion metric
   conflict, safety wins. A slower onboarding that a woman trusts beats a faster one she abandons.
3. **One end of an operator-run process.** `[D]` The worker is never asked to decide what ops has
   already decided.
4. **Offer-driven, not search-driven.** `[D]` The default surface is what has been offered, not what
   exists.
5. **Assume the connection is broken.** `[D]` Offline is the expected state at check-in.
6. **Assume the reader is slow, the sun is bright, the phone is cheap.** `[P]`
7. **Never leave the worker without a next step.** `[P]` Errors name the action, not the fault.
8. **Money and distance first.** `[P]` The decision order is pay, distance, date.
9. **Trust is the conversion barrier, not persuasion.** `[P]` **New in v2.** This audience has been
   targeted by registration-fee scams. "We never charge you" does more work than any benefit copy.

## 3. Information architecture — worker app `[P]`

Three tabs, one level deep, plus two contextual flows. **The fourth Browse tab from v0.1 is
removed.**

| Destination | Contains | Entry |
|---|---|---|
| **Shifts** (home) | Offers, upcoming bookings, active shift | Default tab |
| **History** | Completed shifts, no-shows, standing | Tab |
| **Profile** | Identity, work settings, safety settings, language, support | Tab |
| **Shift detail** | The action surface for one shift | From any list |
| **Attendance** | Check-in and check-out capture | From shift detail, time-gated |

**No home dashboard.** `[D]` A summary would push expiring offers below a fold. The home tab *is*
the action list.

**SOS is global.** `[P]` Reachable in one tap from every screen — a persistent affordance in the
app bar, not an item inside Profile. This is the one exception to the three-tab structure and it is
deliberate: a safety control that requires navigation is not a safety control (NFR-10).

## 4. Worker screens

### 4.1 Onboarding

| ID | Screen | Purpose | States | Traces |
|---|---|---|---|---|
| S-01 | Language select | First screen, before anything else | Default | AUTH-01 |
| S-02 | Free-to-join + number entry | Establish legitimacy, then collect number | Idle · invalid · submitting · rate-limited | AUTH-02, AUTH-04 |
| S-03 | OTP entry | Verify | Waiting · auto-filled · wrong · expired · resend cooldown · locked out | AUTH-02 |
| S-04 | Consent | Terms, privacy, and separate messaging opt-in | Default · declined | AUTH-08 |
| S-05 | Name + area | Minimum identity | Idle · invalid · submitting | PROF-01, PROF-02 |
| S-06 | Roles | What they'll work | Idle · none selected | PROF-01 |
| S-07 | **Recruitment source** | How they heard of us | Default | PROF-04 |
| S-08 | Photograph | In-app capture only | Camera · captured · retake · permission denied | PROF-03 |
| S-09 | **Age verification** | Confirm 18+ | Pending · **rejected (terminal)** | AUTH-07, LEG-01 |
| S-10 | Awaiting verification | Post-submission holding state | Pending · approved · rejected-with-reason | OPS-07 |

**S-01 carries no branding-heavy copy.** `[P]` Two large, high-contrast choices in their own
scripts. Nothing precedes it.

**S-02 states the free-to-join promise before the number field, not after.** `[P]` This is where
scam-wariness peaks; placing it below the fold wastes it.

**S-09 rejection is terminal and must read that way.** `[D]` No "contact support," no appeal
affordance, no wording implying ops can override. An under-18 applicant who believes a phone call
will change the outcome will make that call, and ops will have to refuse it. Design the copy so
the refusal happens once, in the app.

**S-10 is where this funnel most likely leaks.** `[P]` Vetting is a human step that may take a day.
A worker who submits and sees nothing concludes the app is fake — the exact suspicion the flow
exists to overcome. The screen must state what happens next, roughly how long, and offer a
**WhatsApp route to a human**.

### 4.2 Shifts (home)

| ID | Screen | Purpose | States | Traces |
|---|---|---|---|---|
| S-11 | Shifts list | Offers and bookings | Empty · offers only · bookings only · mixed · loading · offline | OFFER-01 |
| S-12 | Offer detail | Accept or decline | Open · accepting · declining · expired · withdrawn | OFFER-02/03 |
| S-13 | Decline reason | Capture why | Default | OFFER-05 |
| S-14 | Booking detail | The confirmed shift | Upcoming · confirm-due · check-in-window-open · active · complete | CONF-01/02 |
| S-15 | Cancel booking | Early honest exit | Confirm · reason · submitting | CONF-05 |

**Offer card content and hierarchy** `[P]` — the single most-repeated element in the product:

1. **Pay** — largest element, tabular lining numerals, unit beneath in small muted text
2. **Role**
3. **Area** — never street address (BR-03, OFFER-09)
4. **Date and hours**, with **end time given its own weight** (OFFER-08)
5. **Duration badge** — short shift vs full day (OFFER-06)
6. **Headcount** — "You + 5 others booked" (OFFER-07)
7. **Requirements** as small pills, only if present
8. **Verified-venue mark** (SAFE-05)
9. **Women-only mark**, where flagged (SAFE-04)

**Empty state matters more than it looks.** `[P]` At pilot there will frequently be no live offers.
The empty state must not read as abandonment: state plainly that offers arrive by notification,
confirm availability settings are active, and give a route to ops. Never pad with fake shifts.

### 4.3 Attendance

| ID | Screen | Purpose | States | Traces |
|---|---|---|---|---|
| S-16 | Check-in | Photograph + location capture | Too early · in window · capturing · **queued offline** · uploading · accepted · **outside geofence** · **integrity flagged** · permission denied | CHK-01/02/03/04 |
| S-17 | Check-in fallback | Business code entry, high-value shifts | Default · invalid | CHK-05 |
| S-18 | Check-out | End-of-shift capture | Available · capturing · queued · complete | CHK-06 |

**The queued-offline state is a success state, not an error.** `[D]` (CHK-04) Copy must say the
check-in is recorded and will send when signal returns. A worker who sees a failure message at a
venue with no signal will try again, or panic, or leave. Neither the visual treatment nor the
wording should resemble the error states.

**The integrity-flagged state does not accuse.** `[P]` (CHK-03) A false positive on a legitimate
low-end device is likely. The worker is told the check-in needs review and ops has been notified —
not that they were caught cheating. Ops adjudicates.

**Outside-geofence offers a route, not a wall.** `[P]` Contact ops, since a venue's recorded
coordinates may simply be wrong.

### 4.4 Safety

| ID | Screen | Purpose | States | Traces |
|---|---|---|---|---|
| S-19 | **SOS** | One-tap emergency | Confirm · sending · sent · failed-with-fallback-number | SAFE-01 |
| S-20 | **Trusted contact** | Nominate one number | Empty · set · editing | PROF-08, SAFE-02 |

**SOS needs one confirmation step, not zero.** `[P]` A control this prominent will be triggered
accidentally in a pocket. One large confirm, no more. On failure, show the ops number in plain
text so it can be dialled directly — an SOS that fails silently is worse than none.

**The trusted-contact screen must explain what is sent and when.** `[P]` A worker who does not
understand that her contact receives her work location may nominate someone she'd rather not, or
skip it entirely.

### 4.5 Profile, availability, history

| ID | Screen | Purpose | States | Traces |
|---|---|---|---|---|
| S-21 | Profile home | Identity and standing | Default | PROF-01 |
| S-22 | **Availability pattern** | Recurring weekly windows | Default · none set | PROF-05 |
| S-23 | **Blackout windows** | Date ranges with no offers | Empty · one or more set · active now | PROF-06 |
| S-24 | Travel distance | Maximum willing | Default | PROF-07 |
| S-25 | Reliability standing | Score + plain-language explanation | **Inactive (pilot)** · active | PROF-09 |
| S-26 | History list | Completed and missed | Empty · populated | HIST-01/02 |
| S-27 | Shift record | One completed shift | Complete · no-show · disputed | HIST-04 |
| S-28 | Raise dispute | Contest a mark | Default · submitting · submitted | HIST-05 |
| S-29 | Language | Change anytime | Default | AUTH-03 |
| S-30 | Support | WhatsApp to ops | Default | SUP-01/02/03 |
| S-31 | Account deletion | Request removal | Explain · confirm · requested | AUTH-09 |

**S-22 and S-23 must be completable in under 30 seconds.** `[P]` A student sets these once a
semester and should not have to relearn the flow.

**S-25 needs an honest pilot state.** `[P]` During the pilot the score does nothing (BRD §3).
Showing a zero with no explanation invites the conclusion that the worker is rated badly. State
plainly that standing builds as shifts are completed.

**S-30 surfaces the women's support route** (SUP-03) as a distinct, labelled option — not buried in
a general contact form.

## 5. Core journeys

| # | Journey | Path | Failure handling |
|---|---|---|---|
| J-1 | First-time registration | S-01 → S-10 | Any step resumable; partial profile survives app closure |
| J-2 | Offer to booking | Push → S-12 → accept → S-14 | Expiry and withdrawal both surface plainly |
| J-3 | Pre-shift confirmation | Push/SMS → S-14 → confirm | Non-response escalates to ops (CONF-04) |
| J-4 | Attendance | S-14 → S-16 → work → S-18 | Offline queue; integrity flag; geofence failure |
| J-5 | **Safety escalation** | Any screen → S-19 → ops alert | Fallback number shown on send failure |
| J-6 | Cancellation | S-14 → S-15 | Reason captured; ops notified in time to replace |
| J-7 | Dispute | S-27 → S-28 | Ops adjudicates in console |

## 6. Notification matrix `[P]`

| Trigger | Push | SMS/WhatsApp fallback | Traces |
|---|---|---|---|
| New offer | Yes | On non-engagement | NOTIF-01/02 |
| Offer expiring | Yes | No | OFFER-04 |
| Evening-before confirmation | Yes | **Always** | CONF-01/03 |
| Morning-of confirmation | Yes | **Always** | CONF-02/03 |
| Shift changed or cancelled | Yes | Yes | NOTIF-01 |
| Replacement request | Yes | Yes | NOTIF-01 |
| Verification approved/rejected | Yes | Yes | VET-04 |
| **Trusted-contact notice** | — | **SMS to third party, server-triggered** | SAFE-02 |

Confirmation prompts always go out-of-app because a worker who has not opened the app is precisely
the one most likely to no-show. All content in the worker's selected language (NOTIF-03).

## 7. Operations console — new in v2

The console is the product for everyone except the worker. Specified by surface rather than screen,
since the build target is function over polish.

### 7.1 Surfaces

| ID | Surface | Purpose | Traces |
|---|---|---|---|
| C-01 | **Today** | Every shift today with confirmation and check-in status; non-responders and unfilled shifts first | OPS-04 |
| C-02 | Shift board | Create, edit, staff shifts; grouped by date and area to make clusters visible | OPS-01 |
| C-03 | Matching | Candidate list for a shift, with availability, distance, history and flags | OPS-02/03 |
| C-04 | **Redeployment** | Move an idle or checked-in worker from one shift to another mid-session | OPS-05 |
| C-05 | Replacement | Trigger and track a replacement to fill | OPS-06 |
| C-06 | Verification queue | Approve/reject registrations, with duplicate and device flags | OPS-07/08 |
| C-07 | **Priority alerts** | SOS and missing-check-out, visually and audibly distinct from routine alerts | OPS-10, SAFE-01/03 |
| C-08 | Integrity review | Mock-location and duplicate flags for human adjudication | OPS-09, OPS-13 |
| C-09 | Businesses | Venues, contacts, vetting status, shift history | OPS-01 |
| C-10 | **Repeat request log** | Record when a business asks for a named worker again | OPS-11, INST-02 |
| C-11 | **Fill timer** | Record ops handling time per fill | OPS-12, INST-01 |
| C-12 | Disputes | Adjudicate contested no-shows and ratings | HIST-05 |

### 7.2 Console design constraints

**C-01 is the screen ops lives in.** `[P]` It must answer one question at a glance: *which shift
today is at risk?* Ordering is by risk, not by time — unconfirmed and unfilled float to the top.

**C-07 must be impossible to miss.** `[P]` A safety alert in the same visual register as a routine
no-show will be missed on a busy Saturday. Distinct colour, distinct sound, and a persistent state
that requires acknowledgement rather than clearing on view.

**C-04 exists because pooled standby needs it.** `[P]` Without redeployment, a standby worker is
idle capacity that cannot be moved, which collapses the pooled model back to per-shift.

**C-10 and C-11 must be one action each.** `[P]` Instrumentation that takes effort during a busy
shift does not get recorded, and unrecorded instrumentation is the pilot failing at its only job.
A single button, not a form.

## 8. Explicitly not built

From BRD §4.2: iOS, business app, in-app payments, worker–business chat, automated matching,
cascading re-offer, referrals, gamification, worker-to-worker features. Added by product decision:
no home dashboard, no leaderboard, no background location, **no self-service shift browse**, and —
pending Open Decision 4 — no in-app document capture.

**The Work Passport is not in pilot scope.** `[O]` It is a strong idea, strongest for students, and
it sits on check-in data already being captured. But it serves none of the pilot's four questions,
so it belongs in the next phase unless the team decides otherwise deliberately.

## 9. Design system

Inherited, unchanged. Ink `#0E2F2B` · teal `#0F6E56` · mint `#1D9E75` · amber `#EF9F27` · ice
`#CFE0DB`. **AssuredGig is amber-forward** — amber carries pay figures and primary actions, teal
recedes to structure. Poppins for display, the Anek family for body and all Indian scripts.

**Nothing containing text has a fixed height** (NFR-04). Tamil strings run 30–50% longer than the
English source, and this is the single most common cause of layout breakage in a product like this.

## 10. Open decisions — product-surface impact

| # (BRD) | Decision | Screens affected | Default while unresolved |
|---|---|---|---|
| 4 | Documents in-app or offline | S-09, C-06 | Build offline; no capture screens |
| 5 | Geofence, windows, grace periods | S-16, S-18, C-07 | Config-served; no hardcoded values |
| 6 | Late-hour threshold | S-12, C-03 | Config-served |
| 7 | Ratings individual or aggregate | S-25, S-27 | Aggregate — less discouraging at pilot scale |
| 1, 2 | Labour-law opinions | C-03 matching rules | Ops guideline, not a system block |

Feature flags served from config — `reliability_visible`, `rating_display_mode`, `docs_in_app` —
keep these forks from stalling the build. **`browse_enabled` is removed**, not defaulted off.

## 11. Acceptance criteria

Inherited from BRD §14, with the product-surface additions:

- SOS is reachable in one tap from every screen, and shows a dialable number on failure.
- The offline check-in state is visually and verbally a success, not an error.
- The under-18 rejection contains no affordance implying appeal.
- Availability pattern and blackout window are each settable in under 30 seconds.
- The ops **Today** surface answers "which shift is at risk?" without filtering or scrolling.
- Logging a repeat request and recording a fill time are each one action.

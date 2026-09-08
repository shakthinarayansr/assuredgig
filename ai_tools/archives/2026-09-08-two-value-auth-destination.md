---
title: AuthenticatedDestination has two values — ready and onboarding
status: superseded
date: 2026-09-08
original_date: 2026-09-08
archived_from: memory
superseded_by: [../memory/2026-09-08-unknown-server-state-is-never-eligible.md]
tags: [auth, onboarding]
---

## The original decision

Where a Partner lands after verifying an OTP is a two-value enum: `ready` if the
profile is complete, `onboarding` if it isn't. The server decides; the client
routes.

## Why it was archived

It survived exactly as long as it took to see a real `otp/verify` response:

```json
{ "status": "PENDING_VETTING", "profileComplete": false, … }
```

`status` is a third axis the enum had no room for. A Partner who has completed
their profile but has not been vetted is neither `ready` — no offers arrive, so
the shifts list is a blank screen with no explanation — nor `onboarding`, since
there is nothing left for them to fill in.

Replaced by a three-value enum with `pendingVetting`, which also became the
landing place for statuses this build does not recognise.

## Worth keeping

The shape of the mistake: the enum was designed from the *requirement* (route
people to the right screen) before the *payload* was seen. One curl first would
have produced the right enum immediately.

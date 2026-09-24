---
title: An unrecognised server state is never read as cleared
status: active
date: 2026-09-08
decided_by: shipped in PR #1 (login-api)
tags: [server-decides, onboarding, safety]
supersedes: [../archives/2026-09-08-two-value-auth-destination.md]
superseded_by: []
links: [../proposals/2026-09-08-confirm-worker-status-vocabulary.md]
---

## The rule

When the server sends a status or requirement this build does not recognise, the
client resolves it to the *less* privileged reading:

- an unknown `status` → `WorkerStatus.unknown` → the waiting screen, never the
  shifts list
- an unknown `missingFields` entry → `ProfileRequirement.unknown`, and it stays
  **in the list**, never dropped

## Why

Principle 3 says the server decides and the client witnesses. Witnessing has a
failure mode nobody writes down: what to do when the verdict is in a vocabulary
you don't speak.

Both directions are wrong, but not equally. Guessing "cleared" puts an unvetted
Partner in front of live offers. Guessing "not yet" shows a vetted Partner a
waiting screen — annoying, visible, and fixed by one line in a mapper. Drop an
unknown requirement and an incomplete profile reads as complete, which strands
someone on an onboarding step the app cannot see.

## What it looks like in the code

`lib/data/mappers/worker_mappers.dart` — both `fromWire` functions end in a
`_ =>` case that lands on the conservative value. Login and profile share this
mapper deliberately, so the two cannot disagree about what `PENDING_VETTING`
means.

## When to revisit

Not the rule — but it should come with telemetry, so a mapping gap is loud
rather than silent. See the linked proposal.

---
title: Confirm the full worker status vocabulary
status: open
date: 2026-09-08
owner: backend
tags: [api, profile, onboarding]
links: []
---

## What

Get the complete list of values `status` can take on `GET /v1/workers/me` and in
the `otp/verify` response.

## Why now

Only `PENDING_VETTING` has ever been observed. `WorkerStatusWire.fromWire` in
`lib/data/mappers/worker_mappers.dart` currently maps `ACTIVE`, `VERIFIED`,
`SUSPENDED`, `BLOCKED`, `REJECTED` and `DELETED` — **all of them guesses**.

## Cost of not doing it

Every unrecognised status falls through to `WorkerStatus.unknown` and routes the
Partner to the "waiting to be vetted" screen. So the failure mode is safe but
silent: a fully vetted Partner whose status is spelled `ACTIVE_WORKER` would sit
on a waiting screen forever, and nothing would log that anything was wrong.

The mapper is one line per value. The cost is entirely in not knowing.

## Options

1. **Preferred** — get the enum from whoever owns the worker model, and while
   we're there decide which statuses mean "can receive offers".
2. Add telemetry for unrecognised statuses so we at least learn about it. Worth
   doing regardless of 1, and it does not need the backend's cooperation.

## Decision

<!-- pending -->

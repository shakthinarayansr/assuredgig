---
title: The device id is a generated UUID, never a hardware identifier
status: active
date: 2026-09-08
decided_by: shipped in PR #1 (login-api)
tags: [auth, privacy, play-compliance]
supersedes: []
superseded_by: []
links: []
---

## The rule

`deviceId` is a v4 UUID minted on first use and kept in secure storage. No IMEI,
no `ANDROID_ID`, no advertising id, no device fingerprint.

## Why

It is exactly as good for the job. The server uses `deviceId` to bind a session
to a handset so a login elsewhere supersedes it — that needs an identifier that
is *stable and unique*, not one that is *derived from the hardware*.

A hardware id would add nothing and cost a great deal: it is PII under DPDP, it
changes the Play data-safety declaration, and it is the kind of thing that is
trivial to add and painful to remove once a backend depends on it.

Accepted consequence: it resets on reinstall or if secure storage is cleared.
That reads to the server as a new device and supersedes the old session —
correct, if occasionally surprising to a Partner who reinstalled.

## What it looks like in the code

`lib/sources/device/device_id_provider.dart`. The first-call result is cached in
a `Future` field so concurrent callers on first launch cannot mint two.

## When to revisit

If fraud patterns show one person cycling installs to evade a block — and even
then, Play Integrity attestation (TRD T-3) is the sanctioned answer, not a
hardware id.

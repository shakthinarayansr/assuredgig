---
title: Give a wrong OTP and an expired OTP different error codes
status: open
date: 2026-09-08
owner: backend
tags: [auth, error-mapping, copy]
links: [../reasoning/2026-09-08-verify-otp-answers-422.md]
---

## What

Return distinct machine-readable codes for "that code is wrong" and "that code
has expired", instead of `INVALID_CODE` for both.

## Why now

The client is currently forced to show one sentence for two different situations,
and the server's own message makes it worse — it says *"That code has expired,
request a new one"* for a code that was merely mistyped.

## Cost of not doing it

A Partner who typos a digit is told to request a new code. So they wait for a
second SMS they did not need, on a 2 G connection, with a cooldown in between —
when the fix was to correct one digit. Every wrong keystroke costs an SMS and
about a minute.

Modest cost, high frequency: mistyped codes are the single most common failure in
any OTP flow.

## Options

1. **Preferred** — `INVALID_CODE` and `CODE_EXPIRED` as separate codes, and fix
   the `INVALID_CODE` message so it stops asserting expiry.
2. Keep one code and soften the message to cover both. Cheaper, but the client
   still cannot offer "check the code" versus "get a new one" as different
   next steps.

## Decision

<!-- pending -->

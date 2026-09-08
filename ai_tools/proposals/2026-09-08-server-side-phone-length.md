---
title: Enforce national phone-number length on the server
status: open
date: 2026-09-08
owner: backend
tags: [auth, validation, server-decides]
links: [../reasoning/2026-09-08-backend-accepts-short-phone-numbers.md]
---

## What

Validate the national number length, not just the E.164 shape, on
`POST /v1/auth/otp/request`.

## Why now

`+91900356001` (nine digits) is accepted with a 201 and an SMS attempt. The only
thing catching a malformed number today is the app's own 10-digit check.

## Cost of not doing it

Two things, one principled and one financial:

- It inverts principle 3 — the client is deciding a rule the server should own,
  and any client that decides can be bypassed by one that doesn't.
- Every malformed number is a paid SMS to nowhere, and an OTP screen the Partner
  waits on for a code that can never arrive.

## Options

1. **Preferred** — validate length per dial code server-side, returning the
   existing 400 `VALIDATION_FAILED`. No client change; the app's check stays as
   a wording decision.
2. Serve the expected length from the config endpoint and keep the client check
   authoritative. Wrong direction — it is still the client deciding, just with
   better inputs.

## Decision

<!-- pending -->

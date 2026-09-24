---
title: The OTP endpoint accepts a 9-digit Indian number
status: confirmed
date: 2026-09-08
found_by: live probe of POST /v1/auth/otp/request
tags: [api, auth, validation, server-decides]
links: [../proposals/2026-09-08-server-side-phone-length.md]
---

## What we assumed

That the server's E.164 validation would reject a malformed Indian mobile
number, so the client's 10-digit check was a UI nicety and not a load-bearing
rule.

## What actually happened

`+91900356001` — nine national digits — returned **201** and the server
attempted to send an SMS. The E.164 check validates the `+` and the dial code
but not the national number length.

## Why it was wrong

It inverts principle 3. Today the *client's* length check is the only thing
stopping a malformed number, which means the client is deciding — and a client
that decides is a client that can be made to lie.

## What changed

Nothing in the app: the client-side check is correct as a *wording* decision and
stays. Raised as a backend proposal instead.

## How we'd catch it earlier

Probe validators with values that are wrong in a *different dimension* than the
obvious one. `"12"` tests the format; `+91900356001` tests the length, and only
the second one found anything.

---
title: Add a token refresh endpoint to the backend
status: open
date: 2026-09-08
owner: backend
tags: [auth, session, blocker]
links: [../reasoning/2026-09-08-401-is-undifferentiated.md]
---

## What

Add an endpoint that exchanges a refresh token for a new access token, and make
the 401 on an *expired* token distinguishable from the 401 on a rejected one.

## Why now

TRD §8 requires single-flight silent refresh. It cannot be built: `AuthApis`
knows three paths (`otp/request`, `otp/verify`, `workers/me`) and none of them
mints a token from a refresh token. `verifyOtp` hands back a `refreshToken` that
the app stores and currently has nothing to do with.

## Cost of not doing it

The access token lives **900 seconds**. Without refresh, a Partner re-enters an
SMS code every 15 minutes — during a shift, at a venue, on a bad connection.
That is not a rough edge; it makes the app unusable for its actual purpose.

It also blocks the phase-3 exit criteria: "device-bound single session" and
"session expiry must not destroy the outbox" are both untestable without it.

## Options

1. **Preferred** — `POST /v1/auth/token/refresh` taking the refresh token,
   returning the same envelope as `otp/verify`. Plus a distinct error code for
   an expired access token (e.g. `TOKEN_EXPIRED`) so the client knows to refresh
   rather than sign out.
2. Lengthen the access token to hours. Cheaper today, worse security, and it
   only moves the re-login rather than removing it.

## Decision

<!-- pending -->

## Where it lands in the app

`_AuthInterceptor` in `lib/sources/api/api_client.dart` — the retry belongs
there, and there is a comment in the file marking the spot.

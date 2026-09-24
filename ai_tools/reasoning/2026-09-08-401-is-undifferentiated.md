---
title: The server returns one 401 for missing, malformed and expired tokens
status: confirmed
date: 2026-09-08
found_by: live probe of GET /v1/workers/me
tags: [api, auth, session]
links: [../proposals/2026-09-08-token-refresh-endpoint.md]
---

## What we assumed

That an expired token could be told apart from a rejected one, so the client
could refresh silently in the first case and sign out in the second — which is
what TRD §8 asks for.

## What actually happened

All four probes returned byte-identical bodies:

```
expired token · no Authorization header · garbage token · valid-shape token
→ 401 {"code":"UNAUTHENTICATED","message":"Authentication required","requestId":…}
```

## Why it was wrong

The distinction TRD §8 depends on is not expressible in the response. The client
cannot implement "refresh on expiry, sign out on rejection" against an API that
does not say which happened.

## What changed

`worker_profile_repository.dart` maps 401 to `AuthFailure.sessionExpired` and
sends the Partner back to login — the conservative reading, since treating a
revoked session as refreshable would loop.

## How we'd catch it earlier

When a requirement depends on distinguishing two failure modes, probe both
before designing around the distinction.

## Compounding factor

There is no refresh endpoint at all — see the linked proposal. With a 900 s
access token, this currently means a re-login every 15 minutes.

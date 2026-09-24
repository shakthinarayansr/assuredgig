---
title: Tokens stop in data/ — nothing above it ever holds one
status: active
date: 2026-09-08
decided_by: shipped in PR #1 (login-api)
tags: [auth, security, layering]
supersedes: []
superseded_by: []
links: []
---

## The rule

`VerifyOtp` writes the session to `TokenStore` and returns only an
`AuthenticatedDestination`. No token appears in a bloc, a state object, a route
argument, or a log line. Requests are authenticated by an interceptor reading
storage — never by a caller passing a token down.

## Why

Anything held in bloc state is reachable by a crash reporter, a devtools
inspector, and every future `toString()`. NFR-05/07 and CLAUDE.md §6 forbid PII
and tokens in crash reports, and the reliable way to honour that is to make it
structurally impossible rather than remembering to scrub.

The cost is that a caller cannot inspect the token it just obtained. Nothing
needs to, and if something ever does, that is the moment to re-examine this
rather than route around it.

## What it looks like in the code

- `lib/sources/secure/token_store.dart` — the only reader and writer
- `_AuthInterceptor` in `lib/sources/api/api_client.dart` — attaches the header
- `lib/data/repositories/verify_otp_repository.dart` — stores, then returns a
  destination

A violation looks like a token-typed field on a state class, or a provider
method taking a token parameter.

## Related

`TokenStore.clear()` deletes five named keys rather than wiping storage —
queued attendance must survive re-auth (CLAUDE.md §6). A blanket wipe here is
the one bug in that file that would cost a Partner a day's pay.

## When to revisit

If silent refresh needs the token in a place this forbids — it shouldn't; the
interceptor is inside the boundary.

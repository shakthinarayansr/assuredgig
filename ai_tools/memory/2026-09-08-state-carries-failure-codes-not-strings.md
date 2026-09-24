---
title: State carries failure codes; only the screen knows words
status: active
date: 2026-09-08
decided_by: shipped in PR #1 (login-api)
tags: [i18n, bloc, layering]
supersedes: []
superseded_by: []
links: []
---

## The rule

`LoginState.failure` is an `AuthFailure` enum, never a message. The screen maps
each code to an `.arb` string. Server-supplied `message` and `issues` text is
diagnostic only and is never shown to a Partner.

## Why

Three reasons, all of which point the same way:

- The domain has no `BuildContext` and no locale, so it cannot produce a Tamil
  string even if it wanted to.
- CI fails the build on user-facing literals anywhere in `lib/`, so a message in
  a state object cannot be translated *and* cannot pass review.
- The server's `message` field is English, written for developers, and sometimes
  wrong — it says "That code has expired" for a code that was mistyped. Piping
  it to the screen would put the backend in charge of copy nobody reviewed.

## What it looks like in the code

`lib/domain/entities/auth_failure.dart` is the vocabulary; the repositories in
`lib/data/repositories/` do the mapping. `AuthFailure.underAge` is marked
terminal (`LoginState.isTerminal`) because AUTH-07 rejection has no appeal
affordance.

## When to revisit

When a failure genuinely needs a server-authored, localised message — which
would mean the server sending a translated string per locale, not English prose.

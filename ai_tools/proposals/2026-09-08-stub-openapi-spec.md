---
title: Check in a stub OpenAPI spec and generate the API client from it
status: open
date: 2026-09-08
owner: app
tags: [api, tooling, trd-compliance]
links: []
---

## What

Write an OpenAPI spec for the three auth/worker endpoints we have already
reverse-engineered, commit it, and generate the Dart client from it — replacing
the hand-written `AuthApiProvider` and `WorkerApiProvider`.

## Why now

TRD §3 says the client is **generated, never hand-written**, and CLAUDE.md §5
already records that no networked feature is finished until the spec exists. We
now have three endpoints' worth of verified, documented behaviour sitting in
`ai_tools/reasoning/` — which is most of a spec already.

## Cost of not doing it

It compounds. Every endpoint added by hand is another file to delete later, and
another chance for the app's idea of the contract to drift from the server's
with nothing to catch it. Right now the drift detector is "someone runs curl and
notices".

Doing it at three endpoints is a morning. At twenty it is a project.

## Options

1. **Preferred** — hand-write the stub spec from what we've probed, generate,
   and wire the CI contract test. The spec is ours until the backend publishes
   one, then we swap sources.
2. Wait for the backend team's spec. Unbounded, and phase 4 (shifts, offers)
   starts adding endpoints regardless.

## Decision

<!-- pending -->

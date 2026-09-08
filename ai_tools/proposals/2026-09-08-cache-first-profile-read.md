---
title: Make the profile read cache-first once Drift lands
status: deferred
date: 2026-09-08
owner: app
tags: [profile, cache, phase-2]
links: []
---

## What

`GetWorkerProfile` should return cached data immediately and refresh behind it,
as CLAUDE.md §4 requires of every read. It currently hits the network on every
call.

## Why now

It doesn't — this is deliberately deferred, and recorded so it is not forgotten.
The Drift cache is phase 2 and does not exist yet.

## Cost of not doing it

Today, low: the profile is read at login on a warm connection. It becomes real
when the profile is read on app open, where a network round trip against a
sleeping backend is the difference between a 300 ms launch and a 52 s one.

## Options

1. **Preferred** — implement inside `GetWorkerProfileFromApi` when the Drift
   cache lands. The seam is already there; no caller changes.

## Decision

Deferred to build phase 2 by the build order in CLAUDE.md §5. Noted on the
`GetWorkerProfile` use case in code as well, so it is visible from both sides.

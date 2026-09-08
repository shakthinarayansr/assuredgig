---
title: The pilot backend takes ~52 s to answer its first request
status: confirmed
date: 2026-09-08
found_by: live probe of POST /v1/auth/otp/request
tags: [api, performance, timeouts]
links: []
---

## What we assumed

That Dio's default timeouts were fine for a pilot backend, and that a slow
request meant a slow *network*.

## What actually happened

The first call of the day to `/v1/auth/otp/request` returned **201 in 52.5 s**.
Every warm call afterwards returned in well under a second. It is a free-tier
Render instance that sleeps when idle.

## Why it was wrong

Nothing about the client was wrong — the assumption about the *dependency* was.
A default connect timeout would have shown the first Partner of the morning
"no internet connection" on a working connection, on the single screen where
they have no way to route around it.

## What changed

`buildDio` sets connect 30 s, receive 90 s, send 30 s, with the reason written
next to the numbers. Warm calls are unaffected, so the ceiling costs nothing in
the normal case.

## How we'd catch it earlier

Time the *first* call to any endpoint, after an idle period, not the tenth. And
treat "how does this dependency behave when cold" as part of reading a contract.

## Still open

A 52 s wait needs a UI answer, not just a timeout: the login screen should say
something is happening. Not built yet.

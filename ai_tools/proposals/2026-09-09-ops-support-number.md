---
title: Supply an ops phone number, and a way to dial it
status: open
date: 2026-09-09
owner: ops / backend
tags: [onboarding, support, safety, config]
links: []
---

## What

Two things the app needs and does not have: a phone number for ops, served from
config; and a way to place the call from inside the app.

## Why now

The canvas's stuck-code screen ("The code isn't working. We'll do it by phone.")
has **Call our team** as its primary action. I built that screen without the
button, because no ops number exists in the BRD, the PRD, the TRD, or any config
endpoint — and a button that dials a number nobody answers is worse than no
button.

## Cost of not doing it

The Partner most likely to reach this screen is the one least able to leave it:
bad SMS reception, a borrowed handset, a number typed from memory. "Send a new
code" and "Change my number" both work, so nobody is stranded — but the designed
way out of a genuinely stuck code is missing, and that is the one that was
supposed to catch the people the automated path fails.

It is also the same number SOS needs on failure (SAFE-01 requires a **dialable**
ops number in plain text), so this blocks two screens, not one.

## Options

1. **Preferred** — serve `supportPhone` from the config endpoint (NFR-08: never
   compiled in — it will change, and changing it must not need a release), and
   add `url_launcher` for the `tel:` intent.
2. Ship the number as plain selectable text with no dial action. No new
   dependency, but it asks a low-literacy Partner to retype a number by hand.

## Decision

<!-- pending -->

## Where it lands in the app

`lib/presentation/login/widgets/otp_stuck_view.dart` — the comment at the top of
that file marks the gap.

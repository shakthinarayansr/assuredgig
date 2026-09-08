---
title: The canvas's phone screen drops the free-to-join promise
status: open
date: 2026-09-09
owner: product
tags: [onboarding, copy, trust]
links: []
---

## What

PRD §4 S-02 is "**Free-to-join** + number entry", with an explicit note:

> **S-02 states the free-to-join promise before the number field, not after.**
> `[P]` This is where scam-wariness peaks; placing it below the fold wastes it.

The v2 canvas's phone screen has no such line. It opens on "Your phone number"
and goes straight to the field.

## Why now

I implemented the canvas as drawn, so the promise is currently absent from the
app. That was a deliberate choice — the canvas is what was handed over — but it
silently drops a stated requirement, and silent is the wrong way for that to
happen.

## Cost of not doing it

Unmeasured, and plausibly the highest-leverage copy in the flow. A worker being
asked for their phone number by an unfamiliar app is deciding whether this is a
scam. The PRD's claim is that the moment before the field is when that decision
is made.

Against that: the canvas is tighter without it, and every line above the field
pushes the keypad down.

## Options

1. **Preferred** — add one line under the "We send a code by SMS" subtitle. Cheap
   to try, and the screen is built to take it without reflowing.
2. Accept the canvas as the newer decision and mark the PRD note superseded.
   Fine, as long as it is a decision rather than an oversight — which is the
   whole reason this entry exists.

## Decision

<!-- pending -->

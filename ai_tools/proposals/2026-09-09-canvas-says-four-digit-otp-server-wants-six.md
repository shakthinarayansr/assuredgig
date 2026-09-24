---
title: The canvas says 4-digit OTP; the server requires 6
status: open
date: 2026-09-09
owner: product / backend
tags: [auth, design, copy]
links: [../reasoning/2026-09-08-verify-otp-answers-422.md]
---

## What

Agree on the code length, then make the canvas and the backend say the same
thing.

## Why now

The canvas draws four boxes, its copy reads "We send a **4**-digit code by SMS",
and its `otpLength` prop offers `[4, 6]` defaulting to 4. The live API rejects
anything shorter than six:

```
POST /v1/auth/otp/verify  {"code":"12", …}
→ 400 VALIDATION_FAILED  ["code must be longer than or equal to 6 characters"]
```

## Cost of not doing it

Low today and self-correcting, because the app already renders whatever the
server asks for: `LoginState.codeLength` comes from `OtpChallenge`, the boxes
count off it, and the copy interpolates it. Nobody sees a wrong number.

It costs something when the canvas is used as the spec for a *second*
implementation, or when someone "fixes" the app to match the drawing.

## Options

1. **Preferred** — decide the length once (6 is what the server enforces today),
   update the canvas copy and box count, and have `otp/request` return the
   length in its response so the client stops defaulting.
2. Move the server to 4. Shorter to type on a cheap keypad, meaningfully easier
   to brute-force. If this is chosen, say so explicitly rather than by relaxing
   a validator.

## Decision

<!-- pending -->

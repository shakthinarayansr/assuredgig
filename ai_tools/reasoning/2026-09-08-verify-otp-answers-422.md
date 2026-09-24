---
title: OTP verify rejects a wrong code with 422, not 400
status: confirmed
date: 2026-09-08
found_by: live probe of POST /v1/auth/otp/verify
tags: [api, auth, error-mapping]
links: [../proposals/2026-09-08-distinguish-expired-from-wrong-otp.md]
---

## What we assumed

That a bad OTP would come back as a 400, like every other bad input on this
backend does.

## What actually happened

```
POST /v1/auth/otp/verify  {"phone":"+919003560015","code":"000000",…}
→ 422 {"code":"INVALID_CODE",
       "message":"That code has expired, request a new one","requestId":…}
```

422, with a message claiming *expiry* for a code that was simply wrong. An
unknown phone gets the same `INVALID_CODE` with a different message
("Request a new code").

Confirmed alongside: `code` must be ≥ 6 chars and `deviceId` ≥ 8 chars, both
enforced as 400 `VALIDATION_FAILED`.

## Why it was wrong

The error interceptor mapped a fixed list of statuses and let everything else
fall through to `unexpected` — so the single most common failure in the whole
login flow was landing in the bucket meant for the unclassifiable.

## What changed

Added `ApiFailureKind.rejected` for 422 and mapped it to `AuthFailure.invalidOtp`
in `verify_otp_repository.dart`. Wrong and expired both map to `invalidOtp`,
because the server does not let the client tell them apart.

## How we'd catch it earlier

Probe the failure paths of an endpoint before writing its client, not after. One
curl with a deliberately wrong code would have shown this before the mapping
existed. This is now `ai_tools/skills/endpoint-probe`.

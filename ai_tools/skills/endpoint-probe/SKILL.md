---
name: endpoint-probe
description: Probe a backend endpoint with curl to learn its real contract — success shape, error envelope, status codes, validators, cold-start timing — before writing any Dart against it. Use whenever adding or debugging a call to the AssuredGig backend, or when a curl is pasted into the conversation.
---

# Probe before you write

This backend is undocumented — there is no OpenAPI spec (CLAUDE.md §5). Every
fact about it in this repo was obtained by calling it. A curl in hand is a
happy path, not a contract, and every entry in `ai_tools/reasoning/` exists
because a happy path was mistaken for one.

Base URL: `Constants.appUrl` in `lib/core/constants/api_endpoints.dart`.

## The probe set

Run the happy path first, then deliberately break it in each dimension. Time the
first call — this backend sleeps.

```sh
U='https://assuredgig-backend-6jox.onrender.com/v1/...'

# 1. Happy path, timed. First call of the day is the cold start.
curl -s -w '\n[HTTP %{http_code} in %{time_total}s]\n' -X POST "$U" \
  -H 'Content-Type: application/json' --data '{...}' --max-time 90

# 2. Malformed field    → the format validator
# 3. Missing field      → which fields are actually required
# 4. Wrong-but-well-formed value → the semantic rejection (often a different status)
# 5. Boundary value: right format, wrong length/range
# 6. Authenticated endpoints: no header · garbage token · expired token
```

Probe 4 and 5 are the ones that find things. Probe 2 tells you what you already
assumed; probe 5 found that this server accepts a nine-digit Indian number.

## What to write down

Before any Dart, record:

- **Success**: exact status (`201`, not "2xx") and the verbatim body
- **Error envelope**: `{code, message, details.issues[], requestId}` on this
  backend — `code` is the only field safe to branch on, `message` is English
  developer prose and is sometimes wrong
- **Status per failure**: do not assume. Verify answers `422` for a bad OTP
  while everything else validates with `400`
- **Validator rules** the errors reveal (`code` ≥ 6 chars, `deviceId` ≥ 8)
- **Cold-start time**, if it is the first call in a while

## Rules

**Never send an OTP to a real number to test a success path.** It costs an SMS
and burns the code. Probe error paths, which need no valid code, and parse the
success shape from a body someone captured.

**Prefer probes that cannot mutate.** A wrong OTP is free; a valid one consumes
a code and may rate-limit the number for the next attempt.

**A token from a pasted curl is probably expired.** These live 900 s. Check
before concluding the endpoint is broken:

```sh
python3 -c "import datetime;print(datetime.datetime.utcfromtimestamp(<exp>))"
```

**Record what you find in `ai_tools/reasoning/`** when it contradicts an
assumption already in the code — that is what the folder is for.

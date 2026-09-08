# domain

Entities, use cases, and the booking state-machine mirror.

**May import:** `domain/`, `core/`. Nothing else — no Flutter widgets, no Drift,
no Dio, no generated API models. Enforced by `tool/check_conventions.dart`.

## The rule that matters here

**No business rule is duplicated from the backend into this layer** (TRD §4).

The client mirrors the booking state machine *only* to render the correct UI. It
does not decide eligibility, geofence pass/fail, no-show status, or score — the
server decides all of those and its verdict is authoritative on every sync
(TRD §2.1). A client that decides is a client that can be made to lie.

So a `Shift` here knows how to describe what state it is in. It does not know
whether that state is *allowed*.

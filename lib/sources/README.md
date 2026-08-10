# sources

The edges of the app. Nothing here makes decisions; it fetches, stores, and
captures.

**May import:** `sources/`, `core/`.

| Directory | Holds |
|---|---|
| `api/` | The **generated** OpenAPI client and Dio configuration. Never hand-write a client here (TRD §3). |
| `local/` | Drift: the cache tables and the outbox (TRD §5.1, §5.2). |
| `device/` | GPS and camera. Foreground location only; direct camera capture only, never gallery import (TRD §7.1, §7.5). |
| `secure/` | `flutter_secure_storage`. **Tokens only** — never shared preferences, never logs, never crash reports (NFR-05). |

## Things that are easy to get wrong here

- **Photos go to app-private storage**, never external storage and never the
  media store. A check-in photo must not appear in the Partner's gallery.
- **Location is captured at exactly two events** — check-in and check-out. No
  background location, ever. The Play data-safety declaration has to match what
  this directory actually does.
- **Device wall-clock is untrusted.** Every attendance capture records three
  values: wall-clock, monotonic elapsed-since-boot, and (added on sync) server
  receipt time. The server derives the true instant from the elapsed-time delta
  (TRD §7.4).

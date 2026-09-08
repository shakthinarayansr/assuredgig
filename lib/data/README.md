# data

Repositories and mappers. Where cache, network and outbox are reconciled into
something the domain layer can use.

**May import:** `data/`, `domain/`, `sources/`, `core/`.

## The two rules that matter here

**Reads are cache-first** (TRD §4, NFR-02). Every read returns cached data
immediately and *then* refreshes. The shifts list must render from disk with no
network at all, inside 500 ms. A repository that awaits the network before
returning anything is a bug, not a slow path.

**Writes go to the outbox, never straight to the API** (TRD §5.2, §6). A bloc
calling a repository to accept an offer results in a committed outbox row, not
an HTTP request. The sync engine owns the network. This is what makes offline
the normal case rather than an error case, and it is why every write carries an
idempotency key generated once, at row creation, and never regenerated on retry.

**Server wins on all shift state.** When a queued write loses a race — the seat
was filled — the local record is marked resolved-superseded and the UI
reconciles. It is not retried into a conflict.

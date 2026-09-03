/// Where a Partner stands with ops.
///
/// The server owns this value; the client only renders it (TRD §2.1). Only
/// `PENDING_VETTING` has been observed on the live backend — the rest are the
/// shape the app is ready for, and anything unrecognised lands on [unknown]
/// rather than being optimistically read as cleared.
enum WorkerStatus {
  /// Submitted, waiting on ops. No offers arrive yet.
  pendingVetting,

  /// Vetted. Eligible for offers.
  active,

  /// Cleared once, stopped since — suspended, blocked, or deleted. Treated as
  /// not eligible; ops owns the reason and the appeal.
  inactive,

  /// A status this build does not know. Never treated as eligible.
  unknown,
}

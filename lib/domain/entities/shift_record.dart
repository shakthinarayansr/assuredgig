/// How a past shift ended, as the server recorded it.
///
/// Disputed (S-27) joins this when disputes are built.
enum ShiftOutcome {
  /// Worked and checked out.
  completed,

  /// Marked absent. Shown to the Partner with the recorded reason, because it
  /// is a mark that affects their income (HIST-04).
  noShow,
}

/// One past shift in History (S-26) — the fields HIST-02 names: date, role,
/// hours and pay.
///
/// There is no history endpoint yet, so this is shaped by the requirement, not
/// by a wire contract. Expect the mapper, not this class, to absorb whatever
/// the server ends up sending.
class ShiftRecord {
  const ShiftRecord({
    required this.id,
    required this.roleLabel,
    required this.startsAt,
    required this.endsAt,
    required this.outcome,
    this.venueName,
    this.payPaise,
    this.noShowReason,
  });

  final String id;

  /// Display label, already localised by the server — role codes are data,
  /// and a new role must not need an app release to be named.
  final String roleLabel;

  /// Known only after acceptance (BR-03), which every past shift has passed.
  final String? venueName;

  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftOutcome outcome;

  /// In paise, never a double — money does not survive floating point. Null
  /// for a no-show, or while the amount is still being settled.
  final int? payPaise;

  /// The reason ops recorded for a no-show (HIST-04). Server text.
  final String? noShowReason;

  Duration get duration => endsAt.difference(startsAt);
}

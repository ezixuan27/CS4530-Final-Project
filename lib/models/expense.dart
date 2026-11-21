/// A shared expense, e.g. "Tickets €48, paid by Ben" (Story 8).
class Expense {
  final String id;
  final String tripId;
  final String description;

  /// Whole cents (4800 = €48.00). Integers avoid floating-point rounding drift.
  final int amountInCents;

  final String paidBy;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amountInCents,
    required this.paidBy,
  });
}

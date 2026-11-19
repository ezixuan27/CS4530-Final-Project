/// A shared expense, e.g. "Tickets €48, paid by Ben" (Story 8).
class Expense {
  final String id;
  final String tripId;
  final String description;
  final double amount;
  final String paidBy;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.paidBy,
  });
}

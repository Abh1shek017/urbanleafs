class TransactionEntry {
  final String id;
  final String type; // 'sold' or 'expense'
  final String description; // This replaces `customerName`
  final double amount;
  final DateTime addedAt;
  final String? itemType;

  TransactionEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.addedAt,
    this.itemType,
  });
}

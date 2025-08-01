import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Add these factory constructors to your existing model
  factory TransactionEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Determine the transaction type based on collection and data
    String transactionType;
    if (doc.reference.parent.id == 'orders') {
      transactionType = 'sold';
    } else if (doc.reference.parent.id == 'expenses') {
      transactionType = 'expense';
    } else {
      transactionType = data['type'] ?? 'expense';
    }

    print('Converting document: ${doc.id}');
    print('  - Collection: ${doc.reference.parent.id}');
    print('  - Data type: ${data['type']}');
    print('  - Assigned transaction type: $transactionType');

    return TransactionEntry(
      id: doc.id,
      type: transactionType,
      description: data['description'] ?? data['customerName'] ?? '',
      amount: (data['amount'] ?? data['totalAmount'] ?? 0).toDouble(),
      addedAt:
          (data['date'] ?? data['addedAt'] ?? data['orderTime'] as Timestamp?)
              ?.toDate() ??
          DateTime.now(),
      itemType: data['type'], // Use the 'type' field from expenses for itemType
    );
  }

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] ?? 0),
      itemType: json['itemType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'itemType': itemType,
    };
  }

  // Helper methods
  bool get isSold => type == 'sold';
  bool get isExpense => type == 'expense';

  TransactionEntry copyWith({
    String? id,
    String? type,
    String? description,
    double? amount,
    DateTime? addedAt,
    String? itemType,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      addedAt: addedAt ?? this.addedAt,
      itemType: itemType ?? this.itemType,
    );
  }
}

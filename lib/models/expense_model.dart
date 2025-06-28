import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String type;
  final DateTime date;
  final String addedBy;
  final DateTime addedAt;
  final String? editedBy;
  final DateTime? editedAt;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.addedBy,
    required this.addedAt,
    this.editedBy,
    this.editedAt,
  });

  factory ExpenseModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return ExpenseModel(
      id: snapshot.id,
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] ?? 'other',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: data['addedBy'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedBy: data['editedBy'],
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date),
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
      if (editedBy != null) 'editedBy': editedBy,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
    };
  }
}

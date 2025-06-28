import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final double amount;
  final String customerName;
  final DateTime receivedTime;
  final String receivedBy;
  final String type; // cash or online

  PaymentModel({
    required this.id,
    required this.amount,
    required this.customerName,
    required this.receivedTime,
    required this.receivedBy,
    required this.type,
  });

  factory PaymentModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return PaymentModel(
      id: snapshot.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      customerName: data['customerName'] as String? ?? '',
      receivedTime:
          (data['receivedTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receivedBy: data['receivedBy'] as String? ?? '',
      type: data['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'customerName': customerName,
      'receivedTime': receivedTime,
      'receivedBy': receivedBy,
      'type': type,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final double amount;
  final String customerName;
  final DateTime receivedTime;
  final String receivedBy;
  final String type; // e.g., 'cash' or 'online'
  final String customerId; // 🔥 required for collectionGroup queries
  final String paymentId;

  PaymentModel({
    required this.id,
    required this.amount,
    required this.customerName,
    required this.receivedTime,
    required this.receivedBy,
    required this.type,
    required this.customerId,
    required this.paymentId
  });

  /// ✅ Factory for DocumentSnapshot (used when fetching a single doc)
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
    customerId: data['customerId'] as String? ?? '',
    paymentId: data['paymentId'] as String? ?? '', // ✅ added
  );
}


  /// ✅ Factory from plain Map (used with .map(doc => ...))
factory PaymentModel.fromMap(Map<String, dynamic> data, String id) {
  return PaymentModel(
    id: id,
    amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    customerName: data['customerName'] as String? ?? '',
    receivedTime:
        (data['receivedTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    receivedBy: data['receivedBy'] as String? ?? '',
    type: data['type'] as String? ?? '',
    customerId: data['customerId'] as String? ?? '',
    paymentId: data['paymentId'] as String? ?? '', // ✅ added
  );
}
PaymentModel copyWith({
  String? id,
  double? amount,
  String? customerName,
  DateTime? receivedTime,
  String? receivedBy,
  String? type,
  String? customerId,
  String? paymentId,
}) {
  return PaymentModel(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    customerName: customerName ?? this.customerName,
    receivedTime: receivedTime ?? this.receivedTime,
    receivedBy: receivedBy ?? this.receivedBy,
    type: type ?? this.type,
    customerId: customerId ?? this.customerId,
    paymentId: paymentId ?? this.paymentId,
  );
}


  /// ✅ Serialize to Firestore format
 Map<String, dynamic> toJson() {
  return {
    'amount': amount,
    'customerName': customerName,
    'receivedTime': receivedTime,
    'receivedBy': receivedBy,
    'type': type,
    'customerId': customerId,
    'paymentId': paymentId, // ✅ added
  };
}
}

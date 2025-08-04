import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String item;
  final double quantity;
  final double price;
  final double totalAmount;
  final double amountPaid;
  final String paymentStatus;
  final String customerName;
  final DateTime orderTime;
  final String addedBy;

  OrderModel({
    required this.id,
    required this.item,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.amountPaid,
    required this.paymentStatus,
    required this.customerName,
    required this.orderTime,
    required this.addedBy,
  });

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    return OrderModel(
      id: snapshot.id,
      item: data?['item'] ?? 'Unknown Item',
      quantity: (data?['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (data?['price'] is num) ? (data!['price'] as num).toDouble() : 0.0,
      totalAmount: (data?['totalAmount'] is num)
          ? (data!['totalAmount'] as num).toDouble()
          : 0.0,
      amountPaid: (data?['amountPaid'] is num)
          ? (data!['amountPaid'] as num).toDouble()
          : 0.0,
      paymentStatus: data?['paymentStatus'] ?? 'Unpaid',
      customerName: data?['customerName'] ?? 'Unknown Customer',
      orderTime: (data?['orderTime'] is Timestamp)
          ? (data!['orderTime'] as Timestamp).toDate()
          : DateTime.now(),
      addedBy: data?['receivedBy'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus,
      'customerName': customerName,
      'orderTime': orderTime,
      'recievedBy': addedBy,
    };
  }
}

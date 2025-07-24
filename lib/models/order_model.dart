import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String description;
  final int quantity;
  final double totalAmount;
  final double pricePerItem;
  final double amountPaid;
  final String paymentStatus;
  final String customerName;
  final DateTime orderTime;
  final String addedBy;
  final String itemType;

  OrderModel({
    required this.id,
    required this.description,
    required this.quantity,
    required this.totalAmount,
    required this.pricePerItem,
    required this.amountPaid,
    required this.paymentStatus,
    required this.customerName,
    required this.orderTime,
    required this.addedBy,
    required this.itemType,
  });

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    return OrderModel(
      id: snapshot.id,
      description: data?['description'] ?? 'Unknown Item',
      quantity: (data?['quantity'] ?? 0) as int,
      totalAmount: (data?['totalAmount'] is num)
          ? (data!['totalAmount'] as num).toDouble()
          : 0.0,
      pricePerItem: (data?['pricePerItem'] is num)
          ? (data!['pricePerItem'] as num).toDouble()
          : 0.0,
      amountPaid: (data?['amountPaid'] is num)
          ? (data!['amountPaid'] as num).toDouble()
          : 0.0,
      paymentStatus: data?['paymentStatus'] ?? 'Unpaid',
      customerName: data?['customerName'] ?? 'Unknown Customer',
      orderTime: (data?['orderTime'] is Timestamp)
          ? (data!['orderTime'] as Timestamp).toDate()
          : DateTime.now(),
      addedBy: data?['addedBy'] ?? 'Unknown',
      itemType: data?['itemType'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'pricePerItem': pricePerItem,
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus,
      'customerName': customerName,
      'orderTime': orderTime,
      'addedBy': addedBy,
      'itemType': itemType,
    };
  }
}

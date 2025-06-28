import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String description;
  final int quantity;
  final double totalPrice;
  final String customerName;
  final DateTime orderTime;
  final String addedBy;

  OrderModel({
    required this.id,
    required this.description,
    required this.quantity,
    required this.totalPrice,
    required this.customerName,
    required this.orderTime,
    required this.addedBy,
  });

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return OrderModel(
      id: snapshot.id,
      description: data['description'],
      quantity: data['quantity'],
      totalPrice: (data['totalPrice'] as num).toDouble(),
      customerName: data['customerName'],
      orderTime: (data['orderTime'] as Timestamp).toDate(),
      addedBy: data['addedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'customerName': customerName,
      'orderTime': orderTime,
      'addedBy': addedBy,
    };
  }
}
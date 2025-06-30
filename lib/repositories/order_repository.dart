import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For DateUtils
import '../models/order_model.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  OrderRepository() : super(FirebaseFirestore.instance.collection('orders'));

  /// Stream of today's orders (real-time)
  Stream<List<OrderModel>> getTodaysOrders() {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(Duration(days: 1));

    return collection
        .where('orderTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('orderTime', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList(),
        );
  }

  /// Stream of count of today's orders (real-time)
  Stream<int> countTodaysOrders() {
    return getTodaysOrders().map((orders) => orders.length);
  }

  /// Add a new order
  Future<void> addOrder(Map<String, dynamic> orderData) async {
    final docRef = await collection.add(orderData);

    // ✅ Create notification for new order
    try {
      final customerName = orderData['customerName'] ?? 'Customer';
      final orderId = docRef.id;

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Order',
        'body': 'Order #$orderId placed by $customerName',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't fail order creation if notification fails
      print('Failed to create order notification: $e');
    }
  }
}

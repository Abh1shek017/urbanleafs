import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 Fetch today's orders across all customers
  Stream<List<OrderModel>> getTodaysOrders() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return _firestore
        .collectionGroup(
          'orders',
        ) // ✅ Searches all subcollections named 'orders'
        .where(
          'orderTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .where('orderTime', isLessThan: Timestamp.fromDate(tomorrowStart))
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList(),
        );
  }

  /// 🔥 Count of today's orders
  Stream<int> countTodaysOrders() {
    return getTodaysOrders().map((orders) => orders.length);
  }

  /// ✅ Add order to specific customer's subcollection
  Future<void> addOrder({
    required Map<String, dynamic> orderData,
    required String orderId,
  }) async {
    final customerId = orderData['customerId']; // or wherever you store this
    final docRef = _firestore
        .collection('customers')
        .doc(customerId)
        .collection('orders')
        .doc(orderId);

    await docRef.set(orderData);
  }

  /// 🔥 Fetch all orders across all customers
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collectionGroup('orders') // 🔥 All orders under all customers
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList(),
        );
  }
}

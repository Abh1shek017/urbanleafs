import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final todaysOrderCountStreamProvider = StreamProvider.autoDispose((ref) {
  final start = DateTime.now();
  final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
  return FirebaseFirestore.instance
      .collection('orders')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .snapshots();
});

final todayPaymentsStreamProvider = StreamProvider.autoDispose((ref) {
  final start = DateTime.now();
  final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
  return FirebaseFirestore.instance
      .collection('payments')
      .where('receivedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('receivedTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .snapshots();
});

final todayExpensesStreamProvider = StreamProvider.autoDispose((ref) {
  final start = DateTime.now();
  final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
  return FirebaseFirestore.instance
      .collection('expenses')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .snapshots();
});

final inventoryStatusStreamProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance.collection('inventory').snapshots();
});

final attendanceTriggerProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance.collection('attendance').snapshots();
});

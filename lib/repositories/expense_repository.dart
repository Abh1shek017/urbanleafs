import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../utils/notifications_util.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  ExpenseRepository()
      : super(FirebaseFirestore.instance.collection('expenses'));

  /// ✅ Get today's expenses using date range
  Stream<List<ExpenseModel>> getTodaysExpenses() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromSnapshot(doc))
              .toList(),
        );
  }

  /// 🔁 Get all expenses
  Stream<List<ExpenseModel>> getAllExpenses() {
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ExpenseModel.fromSnapshot(doc)).toList(),
    );
  }
/// ➕ Add expense with custom doc ID and addedBy as username
Future<void> addExpense(Map<String, dynamic> expenseData) async {
  final now = DateTime.now();
  final formattedDate = DateFormat('yyyyMMdd').format(now);
  final timePart = DateFormat('HHmmss').format(now);

  final expenseType = expenseData['type'].toString().toLowerCase().replaceAll(' ', '_');
  final docId = '${expenseType}_${formattedDate}_$timePart';

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final username = userDoc.data()?['username'] ?? 'Unknown User';

  final fullExpenseData = {
    'description': expenseData['description'],
    'amount': expenseData['amount'],
    'type': expenseData['type'],
    'date': Timestamp.now(),
    'addedBy': username,
    'addedAt': Timestamp.now(),
  };

  await collection.doc(docId).set(fullExpenseData);

  // ✅ Create notification
  try {
    final description = fullExpenseData['description'];
    final amount = fullExpenseData['amount'];
    final type = fullExpenseData['type'];

    await addNotification(
      'expenses',
      'New Expense',
      '$description - ₹${amount.toStringAsFixed(2)} ($type)',
    );
  } catch (_) {
    // Ignore notification failure
  }
}

  /// ✏️ Update expense
  Future<void> updateExpense(
    String id,
    Map<String, dynamic> expenseData,
  ) async {
    await collection.doc(id).update(expenseData);
  }
}

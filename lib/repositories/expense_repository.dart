import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// 🔁 Get all expenses (optional)
  Stream<List<ExpenseModel>> getAllExpenses() {
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ExpenseModel.fromSnapshot(doc)).toList(),
    );
  }

  /// ➕ Add expense
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    await collection.add(expenseData);

    // ✅ Create notification for new expense
    try {
      final description = expenseData['description'] ?? 'Unknown';
      final amount = expenseData['amount'] ?? 0.0;
      final type = expenseData['type'] ?? 'other';

      await addNotification(
        'expenses',
        'New Expense',
        '$description - ₹${amount.toStringAsFixed(2)} ($type)',
      );
    } catch (e) {
      // Don't fail expense creation if notification fails
      // print('Failed to create expense notification: $e');
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

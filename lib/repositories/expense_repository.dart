import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  ExpenseRepository() : super(FirebaseFirestore.instance.collection('expenses'));

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
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromSnapshot(doc))
            .toList());
  }

  /// 🔁 Get all expenses (optional)
  Stream<List<ExpenseModel>> getAllExpenses() {
    return collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ExpenseModel.fromSnapshot(doc)).toList());
  }

  /// ➕ Add expense
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    await collection.add(expenseData);
  }

  /// ✏️ Update expense
  Future<void> updateExpense(String id, Map<String, dynamic> expenseData) async {
    await collection.doc(id).update(expenseData);
  }
}

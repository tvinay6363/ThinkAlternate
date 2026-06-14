import 'package:hive_ce/hive.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';
import 'package:smart_spend/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_spend/features/expenses/data/models/expense_model.dart';

/// Hive implementation of the ExpenseRepository.
class HiveExpenseRepository implements ExpenseRepository {
  final Box<ExpenseModel> _box;

  HiveExpenseRepository(this._box);

  @override
  Future<List<Expense>> getAllExpenses() async {
    final models = _box.values.toList();
    final expenses = models.map((m) => m.toEntity()).toList();
    // Sort newest first
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Future<void> addExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await _box.put(expense.id, model);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await _box.put(expense.id, model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String category) async {
    final all = await getAllExpenses();
    return all.where((e) => e.category.name == category).toList();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllExpenses();
    return all.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
}

import '../entities/expense.dart';

/// Abstract repository interface for expense operations.
/// The data layer implements this, keeping domain layer clean.
abstract class ExpenseRepository {
  /// Returns all expenses sorted by date (newest first).
  Future<List<Expense>> getAllExpenses();

  /// Adds a new expense.
  Future<void> addExpense(Expense expense);

  /// Updates an existing expense.
  Future<void> updateExpense(Expense expense);

  /// Deletes an expense by ID.
  Future<void> deleteExpense(String id);

  /// Returns expenses filtered by category.
  Future<List<Expense>> getExpensesByCategory(String category);

  /// Returns expenses within a date range.
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);
}

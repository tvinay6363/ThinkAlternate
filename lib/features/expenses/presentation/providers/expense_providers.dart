import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:smart_spend/core/constants/app_constants.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';
import 'package:smart_spend/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_spend/features/expenses/data/models/expense_model.dart';
import 'package:smart_spend/features/expenses/data/repositories/hive_expense_repository.dart';

/// Provides the ExpenseRepository singleton.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final box = Hive.box<ExpenseModel>(HiveBoxes.expenses);
  return HiveExpenseRepository(box);
});

/// Manages the list of all expenses.
final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpenseListNotifier(repository);
});

class ExpenseListNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;

  ExpenseListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      state = const AsyncValue.loading();
      final expenses = await _repository.getAllExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _repository.updateExpense(expense);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Search & Filter Providers ───────────────────────────────────────

/// Search query for filtering expenses.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category filter (null = show all).
final selectedCategoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);

/// Filtered expenses based on search query and category filter.
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final categoryFilter = ref.watch(selectedCategoryFilterProvider);

  return expensesAsync.whenData((expenses) {
    var filtered = expenses;

    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.merchantName.toLowerCase().contains(query) ||
        e.category.label.toLowerCase().contains(query) ||
        (e.notes?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Apply category filter
    if (categoryFilter != null) {
      filtered = filtered.where((e) => e.category == categoryFilter).toList();
    }

    return filtered;
  });
});

// ─── Computed Providers ──────────────────────────────────────────────

/// Provides total spending for current month.
final monthlyTotalProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) {
      final now = DateTime.now();
      return expenses
          .where((e) => e.date.month == now.month && e.date.year == now.year)
          .fold(0.0, (sum, e) => sum + e.amount);
    },
    orElse: () => 0.0,
  );
});

/// Provides category-wise breakdown for current month.
final categoryBreakdownProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) {
      final now = DateTime.now();
      final monthExpenses = expenses.where(
        (e) => e.date.month == now.month && e.date.year == now.year,
      );
      final breakdown = <ExpenseCategory, double>{};
      for (final expense in monthExpenses) {
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0) + expense.amount;
      }
      return breakdown;
    },
    orElse: () => {},
  );
});

/// Monthly spending data for bar chart (last 6 months).
final monthlySpendingChartProvider = Provider<List<MonthlySpending>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) {
      final now = DateTime.now();
      final result = <MonthlySpending>[];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final total = expenses
            .where((e) => e.date.month == month.month && e.date.year == month.year)
            .fold(0.0, (sum, e) => sum + e.amount);
        result.add(MonthlySpending(month: month, total: total));
      }

      return result;
    },
    orElse: () => [],
  );
});

/// Data class for monthly spending chart.
class MonthlySpending {
  final DateTime month;
  final double total;

  const MonthlySpending({required this.month, required this.total});

  String get label {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month.month - 1];
  }
}

import 'package:smart_spend/core/constants/app_constants.dart';

/// Pure domain entity representing an expense.
/// This has no dependency on Hive or any external framework.
class Expense {
  final String id;
  final String merchantName;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? notes;
  final String? receiptImagePath;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    this.receiptImagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy with updated fields.
  Expense copyWith({
    String? merchantName,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? notes,
    String? receiptImagePath,
  }) {
    return Expense(
      id: id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

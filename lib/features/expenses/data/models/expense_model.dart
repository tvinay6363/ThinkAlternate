import 'package:hive_ce/hive.dart';
import 'package:smart_spend/core/constants/app_constants.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';

part 'expense_model.g.dart';

/// Hive-annotated model for persistence.
/// Maps to/from the domain Expense entity.
@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String merchantName;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String categoryName;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final String? receiptImagePath;

  @HiveField(7)
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.categoryName,
    this.notes,
    this.receiptImagePath,
    required this.createdAt,
  });

  /// Converts domain entity to Hive model.
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      merchantName: expense.merchantName,
      amount: expense.amount,
      date: expense.date,
      categoryName: expense.category.name,
      notes: expense.notes,
      receiptImagePath: expense.receiptImagePath,
      createdAt: expense.createdAt,
    );
  }

  /// Converts Hive model to domain entity.
  Expense toEntity() {
    return Expense(
      id: id,
      merchantName: merchantName,
      amount: amount,
      date: date,
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => ExpenseCategory.others,
      ),
      notes: notes,
      receiptImagePath: receiptImagePath,
      createdAt: createdAt,
    );
  }
}

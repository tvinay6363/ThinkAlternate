import 'package:flutter/material.dart';
import 'package:smart_spend/core/theme/app_colors.dart';

/// Expense categories with associated icons and colors.
enum ExpenseCategory {
  food(
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: AppColors.foodColor,
  ),
  shopping(
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: AppColors.shoppingColor,
  ),
  travel(
    label: 'Travel',
    icon: Icons.flight_rounded,
    color: AppColors.travelColor,
  ),
  utilities(
    label: 'Utilities',
    icon: Icons.electrical_services_rounded,
    color: AppColors.utilitiesColor,
  ),
  entertainment(
    label: 'Entertainment',
    icon: Icons.movie_rounded,
    color: AppColors.entertainmentColor,
  ),
  others(
    label: 'Others',
    icon: Icons.category_rounded,
    color: AppColors.othersColor,
  );

  const ExpenseCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Hive box names and type IDs.
class HiveBoxes {
  HiveBoxes._();

  static const String expenses = 'expenses_box';
  static const String settings = 'settings_box';

  // Type adapter IDs
  static const int expenseModelId = 0;
}

/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'SmartSpend';
  static const String currency = '₹';
  static const String geminiModel = 'gemini-2.5-flash';
}

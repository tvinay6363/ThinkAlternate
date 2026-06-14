import 'package:intl/intl.dart';
import 'package:smart_spend/core/constants/app_constants.dart';

/// Formatting utilities for currency, dates, etc.
class Formatters {
  Formatters._();

  /// Formats amount with currency symbol. E.g., ₹1,250.00
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currency,
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  /// Formats amount without decimal if whole number. E.g., ₹1,250
  static String currencyCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      final formatter = NumberFormat.currency(
        symbol: AppConstants.currency,
        decimalDigits: 0,
        locale: 'en_IN',
      );
      return formatter.format(amount);
    }
    return currency(amount);
  }

  /// Formats date as "15 Jun 2026"
  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Formats date as "15 Jun"
  static String dateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  /// Formats date as "June 2026"
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Formats date for expense detail view
  static String dateWithDay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  /// Returns relative date text like "Today", "Yesterday", or formatted date
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final diff = today.difference(targetDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return Formatters.date(date);
  }

  /// Returns a group key for section headers: Today, Yesterday, This Week, This Month, Earlier
  static String dateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(targetDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    if (date.month == now.month && date.year == now.year) return 'This Month';
    return DateFormat('MMMM yyyy').format(date);
  }
}

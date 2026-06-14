import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_spend/core/constants/app_constants.dart';
import 'package:smart_spend/core/utils/formatters.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';

/// Utility for exporting expenses to CSV format.
class CsvExporter {
  CsvExporter._();

  /// Exports expenses to a CSV file and opens the share sheet.
  static Future<void> exportAndShare(List<Expense> expenses) async {
    if (expenses.isEmpty) throw Exception('No expenses to export.');

    final csv = StringBuffer();

    // Header row
    csv.writeln('Date,Merchant,Amount (${AppConstants.currency}),Category,Notes');

    // Data rows
    for (final e in expenses) {
      final date = Formatters.date(e.date);
      final merchant = _escapeCsv(e.merchantName);
      final amount = e.amount.toStringAsFixed(2);
      final category = e.category.label;
      final notes = _escapeCsv(e.notes ?? '');
      csv.writeln('$date,$merchant,$amount,$category,$notes');
    }

    // Write to temporary file
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/smartspend_expenses_$timestamp.csv');
    await file.writeAsString(csv.toString());

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SmartSpend Expenses Export',
      text: 'Exported ${expenses.length} expenses from SmartSpend',
    );
  }

  /// Escapes special characters for CSV format.
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

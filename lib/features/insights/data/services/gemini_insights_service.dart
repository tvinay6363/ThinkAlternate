import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';
import 'package:smart_spend/core/constants/app_constants.dart';
import 'package:smart_spend/core/utils/formatters.dart';

/// Service for generating AI spending insights using Gemini.
class GeminiInsightsService {
  GenerativeModel? _model;

  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  bool get isInitialized => _model != null;

  /// Generates a natural-language spending report from expense data.
  Future<String> generateInsights(List<Expense> expenses) async {
    if (_model == null) {
      throw Exception(
        'AI service not initialized. Please add your API key in Settings.',
      );
    }

    if (expenses.isEmpty) {
      throw Exception('No expenses found. Add some expenses first to generate insights.');
    }

    // Build expense summary text for the AI
    final expenseText = _buildExpenseText(expenses);

    try {
      final prompt = TextPart(
        '''You are a personal finance advisor. Analyze the following expense data and generate a comprehensive spending report.

EXPENSE DATA:
$expenseText

Generate a report that includes:
1. **Total Spending** - Overall total with currency symbol (₹)
2. **Category-wise Breakdown** - Amount spent in each category with percentage
3. **Top 3 Largest Expenses** - The biggest individual expenses
4. **Spending Trends** - Any patterns you notice (e.g., high spending days, frequent categories)
5. **Actionable Recommendations** - At least 2 specific, practical suggestions to improve spending habits

Format the report in a clean, readable way using markdown.
Keep the tone friendly and helpful, like a personal finance buddy.
Use ₹ for currency. Be concise but insightful.''',
      );

      final response = await _model!.generateContent([
        Content('user', [prompt]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('No response received from AI.');
      }

      return text;
    } catch (e) {
      if (e.toString().contains('API key')) {
        throw Exception('Invalid API key. Please check your Gemini API key in Settings.');
      }
      rethrow;
    }
  }

  /// Builds a structured text summary of expenses for the AI prompt.
  String _buildExpenseText(List<Expense> expenses) {
    final buffer = StringBuffer();

    // Group by month
    final byMonth = <String, List<Expense>>{};
    for (final expense in expenses) {
      final key = Formatters.monthYear(expense.date);
      byMonth.putIfAbsent(key, () => []).add(expense);
    }

    for (final entry in byMonth.entries) {
      buffer.writeln('--- ${entry.key} ---');
      for (final e in entry.value) {
        buffer.writeln(
          '- ${Formatters.date(e.date)} | ${e.merchantName} | '
          '${AppConstants.currency}${e.amount.toStringAsFixed(2)} | '
          '${e.category.label}',
        );
      }
      buffer.writeln();
    }

    // Add summary stats
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    buffer.writeln('TOTAL EXPENSES: ${AppConstants.currency}${total.toStringAsFixed(2)}');
    buffer.writeln('TOTAL TRANSACTIONS: ${expenses.length}');
    buffer.writeln('DATE RANGE: ${Formatters.date(expenses.last.date)} to ${Formatters.date(expenses.first.date)}');

    return buffer.toString();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_spend/features/insights/data/services/gemini_insights_service.dart';
import 'package:smart_spend/features/settings/presentation/providers/settings_providers.dart';
import 'package:smart_spend/features/expenses/presentation/providers/expense_providers.dart';

/// Provides the GeminiInsightsService singleton.
final insightsServiceProvider = Provider<GeminiInsightsService>((ref) {
  final service = GeminiInsightsService();
  final apiKey = ref.watch(apiKeyProvider);
  if (apiKey.isNotEmpty) {
    service.initialize(apiKey);
  }
  return service;
});

/// Insights generation state.
enum InsightsStatus { idle, loading, success, error }

class InsightsState {
  final InsightsStatus status;
  final String? report;
  final String? errorMessage;

  const InsightsState({
    this.status = InsightsStatus.idle,
    this.report,
    this.errorMessage,
  });
}

/// Manages AI insights state.
final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  final service = ref.watch(insightsServiceProvider);
  return InsightsNotifier(service, ref);
});

class InsightsNotifier extends StateNotifier<InsightsState> {
  final GeminiInsightsService _service;
  final Ref _ref;

  InsightsNotifier(this._service, this._ref) : super(const InsightsState());

  Future<void> generateReport() async {
    state = const InsightsState(status: InsightsStatus.loading);

    try {
      final expensesAsync = _ref.read(expenseListProvider);
      final expenses = expensesAsync.maybeWhen(
        data: (data) => data,
        orElse: () => <dynamic>[],
      );

      if (expenses.isEmpty) {
        state = const InsightsState(
          status: InsightsStatus.error,
          errorMessage: 'No expenses found. Add some expenses first!',
        );
        return;
      }

      final report = await _service.generateInsights(List.from(expenses));
      state = InsightsState(
        status: InsightsStatus.success,
        report: report,
      );
    } catch (e) {
      state = InsightsState(
        status: InsightsStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const InsightsState();
  }
}

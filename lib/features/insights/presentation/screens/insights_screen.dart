import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_spend/core/theme/app_colors.dart';
import 'package:smart_spend/core/utils/formatters.dart';
import 'package:smart_spend/core/widgets/shared_widgets.dart';
import 'package:smart_spend/features/expenses/presentation/providers/expense_providers.dart';
import 'package:smart_spend/features/settings/presentation/providers/settings_providers.dart';
import 'package:smart_spend/features/insights/presentation/providers/insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsState = ref.watch(insightsProvider);
    final apiKey = ref.watch(apiKeyProvider);
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final expensesAsync = ref.watch(expenseListProvider);
    final monthlySpending = ref.watch(monthlySpendingChartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Insights')),
      body: ListView(padding: const EdgeInsets.only(bottom: 80), children: [
        // Stats row
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: _StatCard(title: 'This Month', value: Formatters.currencyCompact(monthlyTotal), icon: Icons.calendar_month, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: 'Transactions', value: expensesAsync.maybeWhen(
              data: (d) { final n = DateTime.now(); return d.where((e) => e.date.month == n.month && e.date.year == n.year).length.toString(); },
              orElse: () => '0'), icon: Icons.receipt_long, color: AppColors.info)),
          ]),
        ),

        // Monthly Bar Chart
        if (monthlySpending.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Monthly Spending Trend', style: Theme.of(context).textTheme.titleMedium)),
          GlassCard(child: SizedBox(height: 200, child: _MonthlyBarChart(data: monthlySpending))),
        ],

        // Pie Chart
        if (categoryBreakdown.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Category Breakdown', style: Theme.of(context).textTheme.titleMedium)),
          GlassCard(child: SizedBox(height: 220, child: Row(children: [
            Expanded(child: PieChart(PieChartData(
              sections: categoryBreakdown.entries.map((e) {
                final pct = monthlyTotal > 0 ? (e.value / monthlyTotal * 100) : 0.0;
                return PieChartSectionData(
                  value: e.value, title: '${pct.toStringAsFixed(0)}%',
                  color: e.key.color, radius: 45,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white));
              }).toList(),
              sectionsSpace: 3, centerSpaceRadius: 35,
            ))),
            const SizedBox(width: 16),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryBreakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.key.label, style: Theme.of(context).textTheme.bodySmall),
                ]),
              )).toList()),
          ]))),
        ],

        // AI Insights section
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text('AI Spending Report', style: Theme.of(context).textTheme.titleMedium)),

        if (apiKey.isEmpty)
          GlassCard(child: Column(children: [
            const Icon(Icons.key_rounded, color: AppColors.warning, size: 32),
            const SizedBox(height: 12),
            Text('API Key Required', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Add your Gemini API key in Settings', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ]))
        else ...[
          if (insightsState.status == InsightsStatus.idle)
            GlassCard(child: Column(children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),
              const SizedBox(height: 12),
              Text('Generate AI Report', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Get personalized spending insights powered by AI', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => ref.read(insightsProvider.notifier).generateReport(),
                icon: const Icon(Icons.auto_awesome), label: const Text('Generate Report')),
            ])),

          if (insightsState.status == InsightsStatus.loading)
            GlassCard(child: Column(children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Analyzing your spending...', style: Theme.of(context).textTheme.bodyMedium),
            ])),

          if (insightsState.status == InsightsStatus.success && insightsState.report != null)
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('AI Analysis', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.read(insightsProvider.notifier).generateReport()),
              ]),
              const SizedBox(height: 12),
              SelectableText(insightsState.report!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
            ])),

          if (insightsState.status == InsightsStatus.error)
            GlassCard(child: Column(children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 12),
              Text(insightsState.errorMessage ?? 'Error', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.read(insightsProvider.notifier).generateReport(), child: const Text('Retry')),
            ])),
        ],
      ]),
    );
  }
}

/// Monthly spending bar chart widget.
class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlySpending> data;
  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0.0, (m, e) => e.total > m ? e.total : m);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16),
      child: BarChart(BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gIndex, rod, rIndex) {
              return BarTooltipItem(
                '${data[group.x].label}\n',
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                children: [TextSpan(
                  text: Formatters.currencyCompact(rod.toY),
                  style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                )],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 50,
            getTitlesWidget: (v, _) => Text(
              Formatters.currencyCompact(v),
              style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(data[idx].label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: idx == data.length - 1 ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color)),
              );
            },
          )),
        ),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: data[i].total,
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: i == data.length - 1
                ? const LinearGradient(colors: [AppColors.primary, Color(0xFF6EECD5)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                : LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.5),
                  ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
          )],
        )),
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_spend/core/constants/app_constants.dart';
import 'package:smart_spend/core/theme/app_colors.dart';
import 'package:smart_spend/core/utils/formatters.dart';
import 'package:smart_spend/core/utils/csv_exporter.dart';
import 'package:smart_spend/core/widgets/shared_widgets.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';
import 'package:smart_spend/features/expenses/presentation/providers/expense_providers.dart';
import 'package:smart_spend/features/expenses/presentation/screens/add_edit_expense_screen.dart';

/// Main expense list screen with search, filter, summary, and expense cards.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredExpensesProvider);
    final allExpensesAsync = ref.watch(expenseListProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final selectedFilter = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search expenses...',
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            )
          : Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wallet, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('SmartSpend'),
            ]),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          // Export CSV
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'export') _exportCsv();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'export', child: Row(children: [
                Icon(Icons.file_download_outlined, size: 20),
                SizedBox(width: 12),
                Text('Export as CSV'),
              ])),
            ],
          ),
        ],
      ),
      body: filteredAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Something went wrong',
          subtitle: e.toString(),
          action: ElevatedButton(
            onPressed: () => ref.read(expenseListProvider.notifier).loadExpenses(),
            child: const Text('Retry'),
          ),
        ),
        data: (expenses) {
          final allExpenses = allExpensesAsync.valueOrNull ?? [];

          if (allExpenses.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No expenses yet',
              subtitle: 'Start tracking your spending by adding your first expense',
              action: ElevatedButton.icon(
                onPressed: () => _navigateToAddExpense(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(expenseListProvider.notifier).loadExpenses(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // Summary Card
                _buildSummaryCard(context, monthlyTotal, categoryBreakdown, allExpenses.length),

                // Category Filter Chips
                _buildFilterChips(selectedFilter),

                const SizedBox(height: 4),
                // Expense List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showSearch || selectedFilter != null ? 'Results' : 'Recent Transactions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${expenses.length} ${expenses.length == 1 ? "item" : "items"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('No matching expenses found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color))),
                  )
                else
                  ..._buildGroupedExpenses(context, ref, expenses),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterChips(ExpenseCategory? selectedFilter) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedFilter == null,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = null,
            ),
          ),
          // Category chips
          ...ExpenseCategory.values.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(cat.icon, size: 16, color: selectedFilter == cat ? cat.color : null),
              label: Text(cat.label),
              selected: selectedFilter == cat,
              selectedColor: cat.color.withValues(alpha: 0.2),
              checkmarkColor: cat.color,
              onSelected: (_) {
                ref.read(selectedCategoryFilterProvider.notifier).state =
                    selectedFilter == cat ? null : cat;
              },
            ),
          )),
        ],
      ),
    );
  }

  /// Groups expenses by date (Today, Yesterday, This Week, etc.) with section headers.
  List<Widget> _buildGroupedExpenses(BuildContext context, WidgetRef ref, List<Expense> expenses) {
    final widgets = <Widget>[];
    String? currentGroup;
    int animIndex = 0;

    for (final expense in expenses) {
      final group = Formatters.dateGroupKey(expense.date);
      if (group != currentGroup) {
        currentGroup = group;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Row(children: [
            Text(group, style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.2), thickness: 1)),
          ]),
        ));
      }
      widgets.add(_buildAnimatedExpenseCard(context, ref, expense, animIndex));
      animIndex++;
    }

    return widgets;
  }

  Widget _buildAnimatedExpenseCard(BuildContext context, WidgetRef ref, Expense expense, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('anim_${expense.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 250)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: _buildExpenseCard(context, ref, expense),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double total,
    Map<ExpenseCategory, double> breakdown,
    int count,
  ) {
    return GlassCard(
      gradient: AppColors.primaryGradient,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Month',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count expenses',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currencyCompact(total),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: breakdown.entries.take(4).map((entry) {
                return _buildMiniCategoryChip(entry.key, entry.value);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniCategoryChip(ExpenseCategory category, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: Colors.black.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            Formatters.currencyCompact(amount),
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref, Expense expense) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text('Delete "${expense.merchantName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(expenseListProvider.notifier).deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${expense.merchantName} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.primary,
              onPressed: () {
                ref.read(expenseListProvider.notifier).addExpense(expense);
              },
            ),
          ),
        );
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEditExpense(context, expense),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: expense.category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    expense.category.icon,
                    color: expense.category.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.merchantName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            expense.category.label,
                            style: TextStyle(
                              color: expense.category.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '  •  ${Formatters.relativeDate(expense.date)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.currencyCompact(expense.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddEditExpenseScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToEditExpense(BuildContext context, Expense expense) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEditExpenseScreen(expense: expense),
        transitionsBuilder: (context, anim, secondaryAnimation, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _exportCsv() {
    final expenses = ref.read(expenseListProvider).valueOrNull;
    if (expenses == null || expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to export')),
      );
      return;
    }
    CsvExporter.exportAndShare(expenses).then((_) {
      // Share sheet handles the rest
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    });
  }
}

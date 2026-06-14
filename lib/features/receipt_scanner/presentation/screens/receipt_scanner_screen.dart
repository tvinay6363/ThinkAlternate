import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_spend/core/constants/app_constants.dart';
import 'package:smart_spend/core/theme/app_colors.dart';
import 'package:smart_spend/core/widgets/shared_widgets.dart';
import 'package:smart_spend/features/expenses/domain/entities/expense.dart';
import 'package:smart_spend/features/receipt_scanner/presentation/providers/scanner_providers.dart';
import 'package:smart_spend/features/settings/presentation/providers/settings_providers.dart';
import 'package:smart_spend/features/expenses/presentation/providers/expense_providers.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});
  @override
  ConsumerState<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _scannedDate = DateTime.now();
  ExpenseCategory _scannedCat = ExpenseCategory.others;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500), vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerProvider);
    final apiKey = ref.watch(apiKeyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: apiKey.isEmpty ? _noApiKey() : _content(state),
    );
  }

  Widget _noApiKey() => EmptyState(
    icon: Icons.key_rounded, title: 'API Key Required',
    subtitle: 'Add your Gemini API key in Settings to enable AI receipt scanning.',
    action: ElevatedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Go to Settings tab to add your API key')),
      ),
      icon: const Icon(Icons.settings), label: const Text('Go to Settings'),
    ),
  );

  Widget _content(ScannerState state) {
    switch (state.status) {
      case ScanningState.idle: return _idle();
      case ScanningState.scanning: return _scanning();
      case ScanningState.success: return _success(state);
      case ScanningState.error: return _error(state);
    }
  }

  Widget _idle() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.document_scanner_rounded, size: 64, color: AppColors.primary)),
      const SizedBox(height: 32),
      Text('Scan a Receipt', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text('Take a photo or select an image of your receipt.\nAI will extract the details automatically.',
        style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
        onPressed: () => _pickImage(ImageSource.camera),
        icon: const Icon(Icons.camera_alt_rounded), label: const Text('Take Photo'))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
        onPressed: () => _pickImage(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_rounded), label: const Text('Choose from Gallery'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]),
  ));

  Widget _scanning() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(animation: _pulseAnim, builder: (ctx, _) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.document_scanner_rounded, size: 56, color: AppColors.primary)))),
      const SizedBox(height: 32),
      Text('Scanning Receipt...', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Text('AI is analyzing your receipt', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      const SizedBox(width: 200, child: LinearProgressIndicator(color: AppColors.primary)),
    ],
  ));

  bool _prefilled = false;

  Widget _success(ScannerState state) {
    final data = state.data!;
    if (!_prefilled) {
      _prefilled = true;
      if (data.merchantName != null) _merchantCtrl.text = data.merchantName!;
      if (data.amount != null) _amountCtrl.text = data.amount!.toStringAsFixed(2);
      if (data.date != null) _scannedDate = data.date!;
      _scannedCat = _mapCat(data.category);
    }
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Text('Receipt Scanned Successfully', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
        ]))),
      const SizedBox(height: 16),
      if (state.imageBytes != null) ClipRRect(borderRadius: BorderRadius.circular(16),
        child: Image.memory(state.imageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover)),
      const SizedBox(height: 20),
      Text('Review & Edit Details', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      TextFormField(controller: _merchantCtrl, decoration: const InputDecoration(labelText: 'Merchant Name', prefixIcon: Icon(Icons.store_rounded))),
      const SizedBox(height: 12),
      TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
        keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      const SizedBox(height: 12),
      InkWell(onTap: _pickDate, borderRadius: BorderRadius.circular(12),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 20), const SizedBox(width: 12),
            Text('${_scannedDate.day}/${_scannedDate.month}/${_scannedDate.year}', style: Theme.of(context).textTheme.bodyLarge)]))),
      const SizedBox(height: 16),
      Text('Category', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: ExpenseCategory.values.map((c) => CategoryChip(
        label: c.label, icon: c.icon, color: c.color, isSelected: _scannedCat == c,
        onTap: () => setState(() => _scannedCat = c))).toList()),
      const SizedBox(height: 24),
      SizedBox(height: 52, child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Save Expense'))),
      const SizedBox(height: 12),
      Center(child: TextButton(onPressed: () { ref.read(scannerProvider.notifier).reset(); _merchantCtrl.clear(); _amountCtrl.clear(); _prefilled = false; },
        child: const Text('Scan Another Receipt'))),
    ]);
  }

  Widget _error(ScannerState state) => EmptyState(
    icon: Icons.error_outline_rounded, title: 'Scan Failed',
    subtitle: state.errorMessage ?? 'An unknown error occurred',
    action: Column(children: [
      ElevatedButton.icon(onPressed: () {
        if (state.imageBytes != null) { ref.read(scannerProvider.notifier).scanReceipt(state.imageBytes!); }
        else { ref.read(scannerProvider.notifier).reset(); }
      }, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again')),
      const SizedBox(height: 8),
      TextButton(onPressed: () => ref.read(scannerProvider.notifier).reset(), child: const Text('Start Over')),
    ]),
  );

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (img != null) { ref.read(scannerProvider.notifier).scanReceipt(await img.readAsBytes()); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _scannedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (p != null) { setState(() => _scannedDate = p); }
  }

  void _save() {
    final m = _merchantCtrl.text.trim();
    final a = double.tryParse(_amountCtrl.text.trim());
    if (m.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter merchant name'))); return; }
    if (a == null || a <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount'))); return; }
    ref.read(expenseListProvider.notifier).addExpense(Expense(id: const Uuid().v4(), merchantName: m, amount: a, date: _scannedDate, category: _scannedCat));
    ref.read(scannerProvider.notifier).reset();
    _merchantCtrl.clear(); _amountCtrl.clear(); _prefilled = false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Expense saved from receipt! ✓'), backgroundColor: AppColors.success));
  }

  ExpenseCategory _mapCat(String? s) {
    if (s == null) return ExpenseCategory.others;
    return ExpenseCategory.values.firstWhere((c) => c.name.toLowerCase() == s.toLowerCase(), orElse: () => ExpenseCategory.others);
  }
}

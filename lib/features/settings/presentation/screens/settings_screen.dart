import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_spend/core/theme/app_colors.dart';
import 'package:smart_spend/core/widgets/shared_widgets.dart';
import 'package:smart_spend/features/settings/presentation/providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiKeyCtrl.text = ref.read(apiKeyProvider);
    });
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // API Key Section
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gemini API Key', style: Theme.of(context).textTheme.titleMedium),
              Text(apiKey.isEmpty ? 'Not configured' : 'Configured ✓',
                style: TextStyle(fontSize: 12, color: apiKey.isEmpty ? AppColors.warning : AppColors.success)),
            ])),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apiKeyCtrl,
            obscureText: !_showKey,
            decoration: InputDecoration(
              hintText: 'Paste your API key here',
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _showKey = !_showKey)),
                IconButton(icon: const Icon(Icons.save_rounded, size: 20, color: AppColors.primary),
                  onPressed: _saveApiKey),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('Get a free key from aistudio.google.com/apikey',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        ])),

        // Theme Section
        GlassCard(child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dark Mode', style: Theme.of(context).textTheme.titleMedium),
            Text(themeMode == ThemeMode.dark ? 'On' : 'Off', style: Theme.of(context).textTheme.bodySmall),
          ])),
          Switch(value: themeMode == ThemeMode.dark, activeTrackColor: AppColors.primary,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme()),
        ])),

        // About Section
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.wallet, color: Colors.black, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SmartSpend', style: Theme.of(context).textTheme.titleMedium),
              Text('v1.0.0', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
          const SizedBox(height: 12),
          Text('AI-Powered Expense Tracker with Receipt Scanning & Spending Insights.',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('Built with Flutter • Riverpod • Hive • Gemini AI',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic)),
        ])),
      ]),
    );
  }

  void _saveApiKey() {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) {
      ref.read(apiKeyProvider.notifier).clearApiKey();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key cleared')));
    } else {
      ref.read(apiKeyProvider.notifier).setApiKey(key);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved! ✓'), backgroundColor: AppColors.success));
    }
  }
}

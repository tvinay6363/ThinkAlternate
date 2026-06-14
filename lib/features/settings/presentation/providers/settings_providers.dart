import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:smart_spend/core/constants/app_constants.dart';

/// Provides the stored Gemini API key.
final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String>((ref) {
  return ApiKeyNotifier();
});

class ApiKeyNotifier extends StateNotifier<String> {
  ApiKeyNotifier() : super('') {
    _loadApiKey();
  }

  void _loadApiKey() {
    final box = Hive.box(HiveBoxes.settings);
    state = box.get('gemini_api_key', defaultValue: '') as String;
  }

  Future<void> setApiKey(String key) async {
    final box = Hive.box(HiveBoxes.settings);
    await box.put('gemini_api_key', key);
    state = key;
  }

  Future<void> clearApiKey() async {
    final box = Hive.box(HiveBoxes.settings);
    await box.delete('gemini_api_key');
    state = '';
  }
}

/// Provides the current theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final box = Hive.box(HiveBoxes.settings);
    final isDark = box.get('is_dark_mode', defaultValue: true) as bool;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final box = Hive.box(HiveBoxes.settings);
    final isDark = state == ThemeMode.dark;
    await box.put('is_dark_mode', !isDark);
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

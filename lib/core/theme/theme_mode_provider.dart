import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String appPreferencesBoxName = 'app_preferences';
const String _darkModeKey = 'isDarkMode';

/// ライト/ダークのテーマ設定。端末ごとのローカル設定として保存する（ゲストも利用可）。
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// MaterialApp に渡す Brightness
final brightnessProvider = Provider<Brightness>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark
      ? Brightness.dark
      : Brightness.light;
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    if (!Hive.isBoxOpen(appPreferencesBoxName)) return ThemeMode.light;
    final isDark = Hive.box(
      appPreferencesBoxName,
    ).get(_darkModeKey, defaultValue: false);
    return isDark == true ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDark(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    if (Hive.isBoxOpen(appPreferencesBoxName)) {
      await Hive.box(appPreferencesBoxName).put(_darkModeKey, isDark);
    }
  }
}

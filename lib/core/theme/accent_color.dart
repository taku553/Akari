import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_palette.dart';

/// アクセントカラーが満たすべき、白との最小コントラスト比（WCAG 2.1 AA）
const double minAccentContrastRatio = 4.5;

final RegExp _hexColorPattern = RegExp(r'^#?([0-9a-fA-F]{6})$');

/// `#RRGGBB`（`#`は省略可）形式の文字列をColorに変換する。不正な形式ならnull。
Color? parseHexColor(String input) {
  final match = _hexColorPattern.firstMatch(input.trim());
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

/// Colorを`#RRGGBB`形式（大文字）に変換する
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// 2色のコントラスト比（1〜21）を返す
double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

/// 白背景・白文字のどちらでも読める（白とのコントラスト比が基準以上）かどうか
bool meetsAccentContrast(Color color) =>
    contrastRatio(color, Colors.white) >= minAccentContrastRatio;

/// アクセントカラーを薄く[base]に重ねた背景色。ライトのデフォルトの赤では AppColors.primaryBackground とほぼ一致する。
Color accentBackgroundOf(
  Color accent, {
  Color base = Colors.white,
  double alpha = 0.09,
}) => Color.alphaBlend(accent.withValues(alpha: alpha), base);

/// 画面から現在のアクセントカラーを取得するための拡張。
/// MaterialApp のテーマ（colorScheme.primary）を参照するため、色が変わると自動で再描画される。
extension AccentColorContext on BuildContext {
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get accentBackground => accentBackgroundOf(
    accent,
    base: palette.backgroundWhite,
    alpha: isDarkTheme ? 0.22 : 0.09,
  );
}

/// アプリ共通のテーマ。アクセントカラーとライト/ダークを切り替え可能。
ThemeData buildAppTheme({
  Color accent = AppColors.primary,
  Brightness brightness = Brightness.light,
}) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      onPrimary: Colors.white,
      brightness: brightness,
      surface: isDark ? palette.backgroundWhite : null,
      onSurface: isDark ? palette.textPrimary : null,
    ),
    scaffoldBackgroundColor: isDark ? palette.backgroundLight : null,
    dividerColor: isDark ? palette.border : null,
    extensions: [palette],
    useMaterial3: true,
    fontFamily: 'NotoSansJP',
  );
}

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_palette.dart';

/// アクセントカラーが背景に対して満たすべき最小コントラスト比。
/// ゲージ・ボタン・アイコンなど図形・UI部品が主な用途のため、文字用の4.5:1より緩い値にしている。
const double minAccentContrastRatio = 3.1;

/// アクセント色の上に白文字を置く場合に許容する、白とのコントラスト比の下限。
/// デフォルトの赤（約2.8:1）が白文字のままになるよう、これを下回る明るい色だけ黒文字にする。
const double _minWhiteOnAccentRatio = 2.5;

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

/// アクセント色が背景[background]に対して見分けられる（コントラスト比が基準以上）かどうか
bool meetsAccentContrast(Color color, Color background) =>
    contrastRatio(color, background) >= minAccentContrastRatio;

/// アクセント色の上に置く文字・アイコンの色。明るいアクセント色（純白など）では黒にする。
Color onAccentOf(Color accent) =>
    contrastRatio(accent, Colors.white) >= _minWhiteOnAccentRatio
    ? Colors.white
    : Colors.black;

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
  Color get onAccent => Theme.of(this).colorScheme.onPrimary;
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
      onPrimary: onAccentOf(accent),
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

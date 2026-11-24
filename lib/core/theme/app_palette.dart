import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ライト/ダークで切り替わる背景・文字・枠線の色。
/// アクセントカラー（primary）は accent_color.dart、状態色（success/error等）は AppColors を使う。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color backgroundWhite; // カード・AppBarなどの面
  final Color backgroundLight; // 画面全体の背景
  final Color backgroundSection;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textLight;
  final Color border;
  final Color borderLight;
  final Color borderDark;

  const AppPalette({
    required this.backgroundWhite,
    required this.backgroundLight,
    required this.backgroundSection,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textLight,
    required this.border,
    required this.borderLight,
    required this.borderDark,
  });

  static const AppPalette light = AppPalette(
    backgroundWhite: AppColors.backgroundWhite,
    backgroundLight: AppColors.backgroundLight,
    backgroundSection: AppColors.backgroundSection,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textLight: AppColors.textLight,
    border: AppColors.border,
    borderLight: AppColors.borderLight,
    borderDark: AppColors.borderDark,
  );

  // 文字と背景を反転した配色。文字は背景に対してコントラスト比4.5:1以上を保つ。
  static const AppPalette dark = AppPalette(
    backgroundWhite: Color(0xFF1F2733),
    backgroundLight: Color(0xFF151A23),
    backgroundSection: Color(0xFF1A202C),
    textPrimary: Color(0xFFEDF2F7),
    textSecondary: Color(0xFFB0BCCB),
    textTertiary: Color(0xFF8D9AAE),
    textLight: Color(0xFF5B677A),
    border: Color(0xFF2F3A4B),
    borderLight: Color(0xFF283241),
    borderDark: Color(0xFF475569),
  );

  @override
  AppPalette copyWith({
    Color? backgroundWhite,
    Color? backgroundLight,
    Color? backgroundSection,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textLight,
    Color? border,
    Color? borderLight,
    Color? borderDark,
  }) {
    return AppPalette(
      backgroundWhite: backgroundWhite ?? this.backgroundWhite,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundSection: backgroundSection ?? this.backgroundSection,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textLight: textLight ?? this.textLight,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      borderDark: borderDark ?? this.borderDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      backgroundWhite: Color.lerp(backgroundWhite, other.backgroundWhite, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      backgroundSection: Color.lerp(
        backgroundSection,
        other.backgroundSection,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderDark: Color.lerp(borderDark, other.borderDark, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// 現在のテーマ（ライト/ダーク）に応じた背景・文字・枠線の色
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}

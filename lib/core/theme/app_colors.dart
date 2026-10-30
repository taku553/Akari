import 'package:flutter/material.dart';

/// アプリ全体で使用するカラーパレット
/// HTMLモックアップ (akari_v6.html) に基づく
class AppColors {
  AppColors._();

  // メインアクセントカラー
  static const Color primary = Color(0xFFF87171); // メインの赤系
  static const Color primaryLight = Color(0xFFFCA5A5);
  static const Color primaryBackground = Color(0xFFFEF2F2);

  // 背景色
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundSection = Color(0xFFF7FAFC);
  static const Color backgroundDark = Color(0xFF1A202C);

  // テキストカラー
  static const Color textPrimary = Color(0xFF2D3748); // 濃いグレー
  static const Color textSecondary = Color(0xFF718096); // ミディアムグレー
  static const Color textTertiary = Color(0xFFA0AEC0); // 薄いグレー
  static const Color textLight = Color(0xFFCBD5E0);

  // ボーダーカラー
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E0);

  // 状態カラー
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFED8936);
  static const Color error = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);

  // レベルアップ専用カラー
  static const Color levelUpGold = Color(0xFFFFD700); // "Level Up!" テキスト用
  static const Color levelUpWhite = Color(0xFFFFFFFF); // レベル番号用

  // シャドウカラー
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.08);
  static Color shadowDark = Colors.black.withValues(alpha: 0.15);
}

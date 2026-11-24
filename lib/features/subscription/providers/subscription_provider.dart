import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../settings/providers/user_settings_provider.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_status.dart';

/// 開発中にサブスクリプション有効として動作確認するためのフラグ（デバッグビルドのみ有効）
/// 例: flutter run --dart-define=DEBUG_SUBSCRIBED=true
const bool _debugSubscribed = bool.fromEnvironment('DEBUG_SUBSCRIBED');

/// ログイン中ユーザーの Firestore 上のサブスクリプション状態（未ログイン・取得失敗時は無効）
final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(SubscriptionStatus.none);
  return SubscriptionRepository().watch(uid);
});

/// サブスクリプションの有効な権利があるか。
/// 買い切りの権利はここに含めない（カラーパレットはサブスクリプション限定のため）。
/// TODO: 課金基盤（Google Play Billing）の導入時に、購入検証済みの状態から判定するよう差し替える。
final hasSubscriptionProvider = Provider<bool>((ref) {
  if (kDebugMode && _debugSubscribed) return true;

  final status =
      ref.watch(subscriptionStatusProvider).valueOrNull ??
      SubscriptionStatus.none;
  final now = DateTime.now();
  if (!status.isActiveAt(now)) return false;

  // 期限が来た時点で、Firestore の更新を待たずに無効へ切り替える
  final expiresAt = status.expiresAt;
  if (expiresAt != null) {
    final timer = Timer(
      expiresAt.difference(now) + const Duration(seconds: 1),
      ref.invalidateSelf,
    );
    ref.onDispose(timer.cancel);
  }
  return true;
});

/// カラーパレットを利用できるか。会員登録（ログイン）済みで、かつサブスクリプションが有効な場合のみ true。
final canUseColorPaletteProvider = Provider<bool>((ref) {
  final isLoggedIn = ref.watch(currentUidProvider) != null;
  return isLoggedIn && ref.watch(hasSubscriptionProvider);
});

/// アプリ全体で使うアクセントカラー。
/// 利用資格がない場合（未契約・解約後・ゲスト）は、保存済みの色を残したままデフォルトの赤を返す。
/// 現在のテーマ（ライト/ダーク）の背景に対してコントラストが足りない色（例：ダークで選んだ純白をライトに戻した場合）も、
/// 保存値は残したまま表示だけデフォルトの赤にする。
final accentColorProvider = Provider<Color>((ref) {
  if (!ref.watch(canUseColorPaletteProvider)) return AppColors.primary;

  final saved = ref.watch(
    userSettingsNotifierProvider.select((s) => s.valueOrNull?.accentColorValue),
  );
  if (saved == null) return AppColors.primary;

  final color = Color(saved);
  final background = ref.watch(themeModeProvider) == ThemeMode.dark
      ? AppPalette.dark.backgroundWhite
      : AppPalette.light.backgroundWhite;
  return meetsAccentContrast(color, background) ? color : AppColors.primary;
});

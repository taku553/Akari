import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/providers/user_settings_provider.dart';

/// 開発中にサブスクリプション有効として動作確認するためのフラグ（デバッグビルドのみ有効）
/// 例: flutter run --dart-define=DEBUG_SUBSCRIBED=true
const bool _debugSubscribed = bool.fromEnvironment('DEBUG_SUBSCRIBED');

/// サブスクリプションの有効な権利があるか。
/// 買い切りの権利はここに含めない（カラーパレットはサブスクリプション限定のため）。
/// TODO: 課金基盤（Google Play Billing）の導入時に購入状態から判定するよう差し替える。
final hasSubscriptionProvider = Provider<bool>((ref) {
  return kDebugMode && _debugSubscribed;
});

/// カラーパレットを利用できるか。会員登録（ログイン）済みで、かつサブスクリプションが有効な場合のみ true。
final canUseColorPaletteProvider = Provider<bool>((ref) {
  final isLoggedIn = ref.watch(currentUidProvider) != null;
  return isLoggedIn && ref.watch(hasSubscriptionProvider);
});

/// アプリ全体で使うアクセントカラー。
/// 利用資格がない場合（未契約・解約後・ゲスト）は、保存済みの色を残したままデフォルトの赤を返す。
final accentColorProvider = Provider<Color>((ref) {
  if (!ref.watch(canUseColorPaletteProvider)) return AppColors.primary;

  final saved = ref.watch(
    userSettingsNotifierProvider.select((s) => s.valueOrNull?.accentColorValue),
  );
  return saved == null ? AppColors.primary : Color(saved);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../data/user_settings_repository.dart';
import '../domain/user_settings.dart';

/// Repository を提供
final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return UserSettingsRepository();
});

/// 現在ログイン中のユーザーの設定を管理（起動時に読み込み、その後はメモリ上で状態保持）
final userSettingsNotifierProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings>(() {
      return UserSettingsNotifier();
    });

class UserSettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    // 認証状態が確定するまで待つ（Web では起動直後に currentUser が null のことがあるため）
    final user = await ref.watch(authStateProvider.future);
    final uid = user?.uid;
    if (uid == null) {
      return const UserSettings(); // 未ログイン時はデフォルト
    }
    final repository = ref.read(userSettingsRepositoryProvider);
    return await repository.getSettings(uid);
  }

  /// 設定を更新し、Firestoreにも保存する
  Future<void> updateSettings(UserSettings newSettings) async {
    final uid = ref.read(authServiceProvider).uid;
    if (uid == null) return;

    // UIを即座に反映させるため状態を先に更新
    state = AsyncValue.data(newSettings);

    final repository = ref.read(userSettingsRepositoryProvider);
    await repository.saveSettings(uid, newSettings);
  }
}

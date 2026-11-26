import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/auth_service.dart';
import '../data/profile_image_repository.dart';

final profileImageRepositoryProvider = Provider<ProfileImageRepository>((ref) {
  return ProfileImageRepository();
});

/// 現在のユーザーのプロフィール画像URL（未設定・未ログイン時は null）
final profileImageUrlProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(profileImageRepositoryProvider).watchProfileImageUrl(uid);
});

/// 画像の選択・アップロードの進行状態を管理する（loading 中はアップロード中）
final profileImageNotifierProvider =
    AsyncNotifierProvider<ProfileImageNotifier, void>(ProfileImageNotifier.new);

class ProfileImageNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// ギャラリーから画像を選び、アップロードする。選択をキャンセルした場合は何もしない。
  Future<void> pickAndUpload() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(profileImageRepositoryProvider)
          .uploadProfileImage(uid, file),
    );
  }
}

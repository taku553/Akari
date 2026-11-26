import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// users/{uid} の profileImageUrl を購読する（未設定の場合は null）
  Stream<String?> watchProfileImageUrl(String uid) {
    return _userDoc(
      uid,
    ).snapshots().map((snap) => snap.data()?['profileImageUrl'] as String?);
  }

  /// 画像をStorageへアップロードし、URLとパスをFirestoreに保存する。
  /// 置き換え前の画像はアップロード成功後に削除する。
  Future<void> uploadProfileImage(String uid, XFile file) async {
    final bytes = await file.readAsBytes();
    final path =
        'profile_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    final previousSnap = await _userDoc(uid).get();
    final previousPath = previousSnap.data()?['profileImagePath'] as String?;

    // merge で書き込み、settings など他のフィールドを消さない
    await _userDoc(uid).set({
      'profileImageUrl': url,
      'profileImagePath': path,
    }, SetOptions(merge: true));

    if (previousPath != null && previousPath != path) {
      await _deleteQuietly(previousPath);
    }
  }

  /// アカウント削除時に、ユーザーのプロフィール画像フォルダをすべて削除する
  Future<void> deleteAllProfileImages(String uid) async {
    try {
      final result = await _storage.ref('profile_images/$uid').listAll();
      for (final item in result.items) {
        await _deleteQuietly(item.fullPath);
      }
    } catch (e) {
      // 画像の削除失敗でアカウント削除全体を止めないよう、ここでは握りつぶす
      debugPrint('⚠️ ProfileImage: Failed to delete profile images: $e');
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // 既に削除済みなどの失敗は無視し、画像の置き換え・アカウント削除を続行する
    }
  }
}

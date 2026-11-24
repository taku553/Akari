import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/max_width_container.dart';
import '../../home/domain/user_stats.dart';
import '../../mission/domain/mission.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Firestoreの users/{uid} 配下のデータをすべて削除
  Future<void> _deleteFirestoreData(String uid) async {
    debugPrint('🗑️ DeleteAccount: Deleting Firestore data for uid=$uid');
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);

    // missions サブコレクションを削除
    final missions = await userDoc.collection('missions').get();
    for (final doc in missions.docs) {
      await doc.reference.delete();
    }
    debugPrint('🗑️ DeleteAccount: Deleted ${missions.docs.length} missions');

    // stats サブコレクションを削除
    final stats = await userDoc.collection('stats').get();
    for (final doc in stats.docs) {
      await doc.reference.delete();
    }
    debugPrint('🗑️ DeleteAccount: Deleted ${stats.docs.length} stats docs');

    // ユーザードキュメント自体を削除（存在する場合）
    final userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      await userDoc.delete();
    }
    debugPrint('🗑️ DeleteAccount: Firestore data deleted for uid=$uid');
  }

  /// Hiveのローカルデータを削除
  Future<void> _deleteLocalData(String uid) async {
    debugPrint('🗑️ DeleteAccount: Deleting local Hive data for uid=$uid');
    try {
      // UID別ボックスを削除（既に開いている場合は型付きでアクセスしてclose）
      final missionsBoxName = 'missions_$uid';
      if (Hive.isBoxOpen(missionsBoxName)) {
        final box = Hive.box<Mission>(missionsBoxName);
        await box.clear();
        await box.close();
      }
      await Hive.deleteBoxFromDisk(missionsBoxName);

      final statsBoxName = 'userStats_$uid';
      if (Hive.isBoxOpen(statsBoxName)) {
        final box = Hive.box<UserStats>(statsBoxName);
        await box.clear();
        await box.close();
      }
      await Hive.deleteBoxFromDisk(statsBoxName);

      debugPrint('🗑️ DeleteAccount: Local data deleted for uid=$uid');
    } catch (e) {
      debugPrint('⚠️ DeleteAccount: Error deleting local data: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードを入力してください'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 最終確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最終確認'),
        content: const Text(
          'アカウントとすべてのデータが完全に削除されます。\nこの操作は取り消せません。\n\n本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '削除する',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.uid;

      if (uid == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No authenticated user found.',
        );
      }

      debugPrint('⚠️ DeleteAccount: Starting account deletion for uid=$uid');

      // ① 再認証
      await authService.reauthenticate(password);

      // ② Firestoreデータ削除
      await _deleteFirestoreData(uid);

      // ③ ローカルデータ削除
      await _deleteLocalData(uid);

      // ④ Firebase Authアカウント削除（最後に実行）
      await authService.deleteAccount();

      debugPrint('✅ DeleteAccount: Account deletion complete for uid=$uid');

      // 削除成功 → authStateChanges で自動的にログイン画面に遷移する
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'パスワードが正しくありません。';
          break;
        case 'requires-recent-login':
          message = '再ログインが必要です。一度ログアウトして再度ログインしてください。';
          break;
        default:
          message = 'エラーが発生しました (${e.code})';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'アカウント削除',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MaxWidthContainer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 警告バナー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'アカウントを削除すると',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• すべてのミッションデータが削除されます\n'
                          '• レベルと経験値がリセットされます\n'
                          '• この操作は取り消せません',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF991B1B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // パスワード入力
            Text(
              '確認のためパスワードを入力してください',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.palette.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.border, width: 1),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'パスワード',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: context.palette.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: context.palette.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 削除ボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'アカウントを削除',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

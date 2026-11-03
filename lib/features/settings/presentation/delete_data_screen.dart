import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/level_up_state_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/guest_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/max_width_container.dart';
import '../../home/data/user_stats_repository.dart';
import '../../home/providers/user_stats_provider.dart';
import '../../mission/data/mission_repository.dart';
import '../../mission/providers/mission_provider.dart';

enum _DeleteMode { all, partial }

class DeleteDataScreen extends ConsumerStatefulWidget {
  const DeleteDataScreen({super.key});

  @override
  ConsumerState<DeleteDataScreen> createState() => _DeleteDataScreenState();
}

class _DeleteDataScreenState extends ConsumerState<DeleteDataScreen> {
  static const _confirmText = 'data-delete';
  static const _red = Color(0xFFDC2626);

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _DeleteMode _mode = _DeleteMode.all;
  bool _deleteLevel = false;
  bool _deleteExp = false;
  bool _deleteMissions = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isGuest =>
      ref.read(isGuestModeProvider) || ref.read(authServiceProvider).uid == null;

  bool get _allSelected => _deleteLevel && _deleteExp && _deleteMissions;

  /// 全データ削除、または部分削除で全項目が選択された場合
  bool get _isFullDelete => _mode == _DeleteMode.all || _allSelected;

  bool get _hasSelection =>
      _mode == _DeleteMode.all ||
      _deleteLevel ||
      _deleteExp ||
      _deleteMissions;

  bool get _canSubmit =>
      !_isLoading &&
      _hasSelection &&
      _confirmController.text == _confirmText &&
      (_isGuest || _passwordController.text.isNotEmpty);

  String get _targetLabel {
    if (_isFullDelete) return 'レベル・経験値・ミッション履歴のすべて';
    return [
      if (_deleteLevel) 'レベル',
      if (_deleteExp) '経験値',
      if (_deleteMissions) 'ミッション履歴',
    ].join('・');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最終確認'),
        content: Text('$_targetLabelを削除します。\nこの操作は取り消せません。\n\n本当に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      // ゲストはパスワードが無いため再認証をスキップ
      if (!_isGuest) {
        await ref
            .read(authServiceProvider)
            .reauthenticate(_passwordController.text);
      }

      final deleteLevel = _isFullDelete || _deleteLevel;
      final deleteExp = _isFullDelete || _deleteExp;
      final deleteMissions = _isFullDelete || _deleteMissions;

      if (deleteMissions) {
        await ref.read(missionRepositoryProvider).deleteAllMissions();
      }
      // ミッション履歴を消す場合は完了ミッション数も0に戻す
      await ref
          .read(userStatsRepositoryProvider)
          .resetStats(
            level: deleteLevel,
            exp: deleteExp,
            missionCount: deleteMissions,
          );
      ref.read(levelUpStateProvider.notifier).reset();
      // 表示中の状態が古いまま残らないよう再作成する
      ref.invalidate(userStatsProvider);
      ref.invalidate(missionListProvider);
      ref.invalidate(missionHistoryProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データを削除しました')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showSnackBar('パスワードが正しくありません。');
          break;
        case 'requires-recent-login':
          _showSnackBar('再ログインが必要です。一度ログアウトして再度ログインしてください。');
          break;
        default:
          _showSnackBar('エラーが発生しました (${e.code})');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('データの削除に失敗しました。通信環境を確認して再度お試しください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _inputBox({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 1),
    ),
    child: child,
  );

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _buildModeSelector() {
    return _inputBox(
      child: RadioGroup<_DeleteMode>(
        groupValue: _mode,
        onChanged: (v) => setState(() => _mode = v ?? _mode),
        child: const Column(
          children: [
            RadioListTile<_DeleteMode>(
              value: _DeleteMode.all,
              title: Text('全データ削除'),
              subtitle: Text('レベル・経験値・ミッション履歴をすべて削除'),
            ),
            RadioListTile<_DeleteMode>(
              value: _DeleteMode.partial,
              title: Text('一部データ削除'),
              subtitle: Text('削除する項目を選択'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartialOptions() {
    Widget check(String title, bool value, ValueChanged<bool> onChanged) =>
        CheckboxListTile(
          value: value,
          title: Text(title),
          activeColor: _red,
          onChanged: (v) => setState(() => onChanged(v ?? false)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _label('削除する項目（1つ以上選択）'),
        _inputBox(
          child: Column(
            children: [
              check('レベル', _deleteLevel, (v) => _deleteLevel = v),
              check('経験値', _deleteExp, (v) => _deleteExp = v),
              check('ミッション履歴', _deleteMissions, (v) => _deleteMissions = v),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!_hasSelection)
          const Text(
            '削除する項目を1つ以上選択してください。',
            style: TextStyle(fontSize: 12, color: _red),
          )
        else if (_allSelected)
          const Text(
            'すべての項目が選択されているため、「全データ削除」と同じ処理になります。',
            style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _isGuest;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'データを削除',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MaxWidthContainer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: _red, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '削除したデータは元に戻せません。\nアカウント自体は削除されません。',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF991B1B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildModeSelector(),
            if (_mode == _DeleteMode.partial) _buildPartialOptions(),
            const SizedBox(height: 24),
            if (!isGuest) ...[
              _label('確認のためパスワードを入力してください'),
              _inputBox(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration(
                    'パスワード',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _label('確認のため「$_confirmText」と入力してください'),
            _inputBox(
              child: TextField(
                controller: _confirmController,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(_confirmText),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canSubmit ? _delete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
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
                        'データを削除',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/guest_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/max_width_container.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SETTINGS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: MaxWidthContainer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ゲストモード中の場合は登録を促すバナーを表示
            _buildGuestModeBanner(context, ref),
            // アカウントプロフィール欄
            _buildAccountBanner(context, ref),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'アプリ情報',
              items: [
                _SettingsItem(
                  icon: Icons.star_outline,
                  title: 'デフォルト経験値の設定',
                  onTap: () => context.push('/settings/default-exp'),
                ),
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'バージョン',
                  trailing: const Text(
                    '1.0.0',
                    style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'データ管理',
              items: [
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: 'データを削除',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFA0AEC0),
                  ),
                  onTap: () {
                    // TODO: Show confirmation dialog
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'その他',
              items: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'ヘルプ',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFA0AEC0),
                  ),
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: '利用規約',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFA0AEC0),
                  ),
                  onTap: () => context.push('/settings/terms'),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'プライバシーポリシー',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFA0AEC0),
                  ),
                  onTap: () => context.push('/settings/privacy-policy'),
                ),
                _SettingsItem(
                  icon: Icons.gavel_outlined,
                  title: '特定商取引法に関する表記',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFA0AEC0),
                  ),
                  onTap: () => context.push('/settings/legal-notice'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAccountSection(context, ref),
          ],
        ),
      ),
    );
  }

  /// ゲストモード中はアカウントセクションを非表示にする
  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    // ゲストモード中はアカウント操作項目を表示しない（バナーで代替）
    if (isGuest) return const SizedBox.shrink();

    return _buildSettingsSection(
      title: 'アカウント',
      items: [
        _SettingsItem(
          icon: Icons.lock_outline,
          title: 'パスワード変更',
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFFA0AEC0),
          ),
          onTap: () => context.push('/settings/change-password'),
        ),
        _SettingsItem(
          icon: Icons.logout,
          title: 'ログアウト',
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFFA0AEC0),
          ),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('ログアウト'),
                content: const Text('ログアウトしますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'ログアウト',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(authServiceProvider).signOut();
            }
          },
        ),
        _SettingsItem(
          icon: Icons.delete_forever,
          title: 'アカウント削除',
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFFA0AEC0),
          ),
          onTap: () => context.push('/settings/delete-account'),
        ),
      ],
    );
  }

  /// ゲストモード中のみ表示するバナー
  Widget _buildGuestModeBanner(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    if (!isGuest) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ ゲストモードで使用中',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'データはこのデバイスにのみ保存されています。'
                'アカウントを作成するとクラウドに保存され、複数デバイスでデータを共有できます。',
                style: TextStyle(fontSize: 13, color: Color(0xFF78350F)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // 新規登録フォームで開く・ゲスト経由フラグをセット
                    ref.read(isFromGuestModeProvider.notifier).state = true;
                    ref.read(guestExitToLoginProvider.notifier).state = false;
                    ref.read(isGuestModeProvider.notifier).state = false;
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('アカウントを作成してデータを保存する'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // ログインフォームで開く・ゲスト経由フラグをセット
                    ref.read(isFromGuestModeProvider.notifier).state = true;
                    ref.read(guestExitToLoginProvider.notifier).state = true;
                    ref.read(isGuestModeProvider.notifier).state = false;
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    foregroundColor: const Color(0xFF92400E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('アカウント作成済みの方はこちらからログイン'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAccountBanner(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryBackground,
              child: Text(
                _getInitial(user?.email),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.email ?? 'ユーザー',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'プロフィールを表示',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  String _getInitial(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  Widget _buildSettingsSection({
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) => Column(
                children: [
                  if (index > 0)
                    Divider(height: 1, color: AppColors.border, indent: 56),
                  items[index],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!],
          ],
        ),
      ),
    );
  }
}

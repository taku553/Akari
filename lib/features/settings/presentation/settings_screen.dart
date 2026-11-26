import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/guest_mode_provider.dart';

import '../../../core/widgets/max_width_container.dart';
import '../../home/providers/user_stats_provider.dart';
import '../../profile/providers/profile_image_provider.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SETTINGS',
          style: TextStyle(
            color: context.palette.textPrimary,
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
              context: context,
              title: 'アプリ情報',
              items: [
                _SettingsItem(
                  icon: Icons.star_outline,
                  title: 'デフォルト経験値の設定',
                  onTap: () => context.push('/settings/default-exp'),
                ),
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'カラーパレット',
                  trailing: Icon(
                    ref.watch(canUseColorPaletteProvider)
                        ? Icons.chevron_right
                        : Icons.lock_outline,
                    color: context.palette.textTertiary,
                  ),
                  onTap: () => _onColorPaletteTap(context, ref),
                ),
                _SettingsItem(
                  icon: context.isDarkTheme
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: 'ダークモード',
                  trailing: Switch(
                    value: ref.watch(themeModeProvider) == ThemeMode.dark,
                    onChanged: (isDark) =>
                        ref.read(themeModeProvider.notifier).setDark(isDark),
                  ),
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setDark(ref.read(themeModeProvider) != ThemeMode.dark),
                ),
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'バージョン',
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.palette.textSecondary,
                    ),
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context: context,
              title: 'データ管理',
              items: [
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: 'データを削除',
                  trailing: _chevron(context),
                  onTap: () => context.push('/settings/delete-data'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context: context,
              title: 'その他',
              items: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'ヘルプ',
                  trailing: _chevron(context),
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: '利用規約',
                  trailing: _chevron(context),
                  onTap: () => context.push('/settings/terms'),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'プライバシーポリシー',
                  trailing: _chevron(context),
                  onTap: () => context.push('/settings/privacy-policy'),
                ),
                _SettingsItem(
                  icon: Icons.gavel_outlined,
                  title: '特定商取引法に関する表記',
                  trailing: _chevron(context),
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

  Widget _chevron(BuildContext context) =>
      Icon(Icons.chevron_right, color: context.palette.textTertiary);

  /// カラーパレットの項目タップ時。利用できる場合のみ画面へ進み、それ以外は理由を案内する。
  Future<void> _onColorPaletteTap(BuildContext context, WidgetRef ref) async {
    if (ref.read(canUseColorPaletteProvider)) {
      context.push('/settings/color-palette');
      return;
    }

    final isGuest = ref.read(isGuestModeProvider);
    final goToSignUp = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カラーパレット'),
        content: Text(
          isGuest
              ? 'カラーパレットはサブスクリプション限定の機能です。'
                    'サブスクリプションの登録にはアカウント（会員登録）が必要です。'
              : 'カラーパレットはサブスクリプション限定の機能です。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('閉じる'),
          ),
          if (isGuest)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('アカウントを作成'),
            ),
        ],
      ),
    );

    if (goToSignUp == true) {
      // ゲストバナーの「アカウントを作成」と同じ遷移（新規登録フォームを開く）
      ref.read(isFromGuestModeProvider.notifier).state = true;
      ref.read(guestExitToLoginProvider.notifier).state = false;
      ref.read(isGuestModeProvider.notifier).state = false;
    }
  }

  /// ゲストモード中はアカウントセクションを非表示にする
  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    // ゲストモード中はアカウント操作項目を表示しない（バナーで代替）
    if (isGuest) return const SizedBox.shrink();

    return _buildSettingsSection(
      context: context,
      title: 'アカウント',
      items: [
        _SettingsItem(
          icon: Icons.lock_outline,
          title: 'パスワード変更',
          trailing: _chevron(context),
          onTap: () => context.push('/settings/change-password'),
        ),
        _SettingsItem(
          icon: Icons.logout,
          title: 'ログアウト',
          trailing: _chevron(context),
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
          trailing: _chevron(context),
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
              Builder(
                builder: (context) {
                  final stats = ref.watch(userStatsProvider).value;
                  if (stats == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Lv.${stats.level}　EXP ${stats.currentExp} / ${stats.nextLevelExp}'
                      '　累計 ${stats.totalExp} EXP',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  );
                },
              ),
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
          color: context.palette.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.palette.border, width: 1),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              radius: 24,
              fontSize: 20,
              initial: _getInitial(user?.email),
              imageUrl: ref.watch(profileImageUrlProvider).value,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.email ?? 'ユーザー',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'プロフィールを表示',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _chevron(context),
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
    required BuildContext context,
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
              color: context.palette.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.palette.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.border, width: 1),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) => Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: context.palette.border,
                      indent: 56,
                    ),
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
            Icon(icon, size: 24, color: context.palette.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.palette.textPrimary,
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

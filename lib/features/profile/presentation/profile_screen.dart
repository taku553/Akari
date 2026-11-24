import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/max_width_container.dart';
import '../../home/providers/user_stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PROFILE',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MaxWidthContainer(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('ログインしていません'));
            }
            return _buildProfileContent(context, user, userStats);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('エラーが発生しました')),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    User user,
    AsyncValue userStats,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // アイコン＋レベル表示エリア
        _buildProfileHeader(context, user, userStats),
        const SizedBox(height: 24),
        // アカウント情報セクション
        _buildInfoSection(
          context,
          title: 'アカウント情報',
          items: [
            _ProfileInfoItem(
              icon: Icons.email_outlined,
              label: 'メールアドレス',
              value: user.email ?? '未設定',
            ),
            _ProfileInfoItem(
              icon: Icons.calendar_today_outlined,
              label: 'アカウント作成日',
              value: _formatDate(user.metadata.creationTime),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // ステータスセクション
        _buildInfoSection(
          context,
          title: 'ステータス',
          items: [
            _ProfileInfoItem(
              icon: Icons.star_outline,
              label: '現在のレベル',
              value: userStats.when(
                data: (stats) => 'Lv. ${stats.level}',
                loading: () => '...',
                error: (_, _) => '-',
              ),
            ),
            _ProfileInfoItem(
              icon: Icons.bolt_outlined,
              label: '累計経験値',
              value: userStats.when(
                data: (stats) => '${stats.totalExp} EXP',
                loading: () => '...',
                error: (_, _) => '-',
              ),
            ),
            _ProfileInfoItem(
              icon: Icons.flag_outlined,
              label: 'ミッション完了数',
              value: userStats.when(
                data: (stats) => '${stats.completedMissionCount} 回',
                loading: () => '...',
                error: (_, _) => '-',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    User user,
    AsyncValue userStats,
  ) {
    final level = userStats.when(
      data: (stats) => stats.level,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border, width: 1),
      ),
      child: Column(
        children: [
          // アイコン（将来的に画像設定可能にする）
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: context.accentBackground,
                child: Text(
                  _getInitial(user.email),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: context.accent,
                  ),
                ),
              ),
              // 将来のアイコン変更ボタン（Phase3で有効化）
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.palette.backgroundWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.border, width: 1),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // メールアドレス表示（将来的にはdisplayNameを表示）
          Text(
            user.email ?? 'ユーザー',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // レベルバッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.accentBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lv. $level',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<_ProfileInfoItem> items,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '不明';
    return DateFormat('yyyy年M月d日', 'ja_JP').format(date);
  }

  String _getInitial(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 24, color: context.palette.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

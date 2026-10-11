import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../mission/providers/mission_provider.dart';
import '../providers/user_stats_provider.dart';
import '../widgets/exp_progress_widget.dart';
import '../widgets/mission_list_widget.dart';
import '../../../core/widgets/max_width_container.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final missionsAsync = ref.watch(missionListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        bottom: false,
        child: userStatsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'エラーが発生しました: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (userStats) {
            // アクティブなミッションを取得
            final activeMission = missionsAsync.maybeWhen(
              data: (missions) => missions.isNotEmpty ? missions.first : null,
              orElse: () => null,
            );

            return MaxWidthContainer(
              child: CustomScrollView(
                slivers: [
                  // ヘッダー部分（レベルと経験値）
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.backgroundWhite,
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ロゴ（左上、履歴ボタンの上）
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 18, bottom: 8),
                              child: SvgPicture.asset(
                                'assets/images/akari_mark.svg',
                                height: 36,
                              ),
                            ),
                          ),
                          // ─── トップバー行: 履歴 ／ MISSION+名前 ／ 右スペーサー ───
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 左: 履歴ボタン
                                TextButton.icon(
                                  onPressed: () =>
                                      context.push('/mission/history'),
                                  icon: const Icon(
                                    Icons.history,
                                    size: 16,
                                    color: AppColors.textTertiary,
                                  ),
                                  label: const Text(
                                    '履歴',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                // 中央: MISSION ラベル + ミッション名 or CTA
                                Expanded(
                                  child: activeMission != null
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'MISSION',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.5,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              activeMission.title,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'MISSION',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.5,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () => context.push(
                                                '/mission/create',
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 16,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'ミッションを作成',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                // 右スペーサー（左の履歴ボタンと対称に取る）
                                const SizedBox(width: 68),
                              ],
                            ),
                          ),
                          // ─── 経験値プログレスバー ───
                          const SizedBox(height: 20),
                          ExpProgressWidget(
                            level: userStats.level,
                            currentExp: userStats.currentExp,
                            nextLevelExp: userStats.nextLevelExp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // タスクセクションヘッダー
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.backgroundSection,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TASKS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ミッションリスト
                  const MissionListWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

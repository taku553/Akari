import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/max_width_container.dart';
import '../domain/mission.dart';
import '../providers/mission_provider.dart';

class MissionHistoryScreen extends ConsumerWidget {
  const MissionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(missionHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '完了済みミッション',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: MaxWidthContainer(
        child: history.isEmpty
            ? _buildEmpty(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return _MissionHistoryCard(mission: history[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 72, color: AppColors.textLight),
          const SizedBox(height: 20),
          const Text(
            'まだ完了したミッションはありません',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ミッションを完了すると\nここに記録されます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('ホームに戻る'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionHistoryCard extends StatefulWidget {
  final Mission mission;

  const _MissionHistoryCard({required this.mission});

  @override
  State<_MissionHistoryCard> createState() => _MissionHistoryCardState();
}

class _MissionHistoryCardState extends State<_MissionHistoryCard> {
  bool _expanded = false;

  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month.toString().padLeft(2, '0')}月${dt.day.toString().padLeft(2, '0')}日';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final levelBefore = m.levelBeforeCompletion;
    final levelAfter = m.levelAfterCompletion;
    final hasLevelInfo = levelBefore != null && levelAfter != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ヘッダー部分 ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 完了アイコン
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                // タイトル・日付
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (m.completedAt != null)
                        Text(
                          '完了日: ${_formatDate(m.completedAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      Text(
                        '作成日: ${_formatDate(m.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 展開ボタン
                IconButton(
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 22),
                  ),
                  color: AppColors.textTertiary,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // --- レベル情報バー ---
          if (hasLevelInfo)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.accentBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 14,
                    color: context.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lv.$levelBefore',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.accent,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: context.accent,
                    ),
                  ),
                  Text(
                    'Lv.$levelAfter',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.accent,
                    ),
                  ),
                  if (levelAfter > levelBefore) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.levelUpGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LEVEL UP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC89B00),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // --- タスク一覧（展開時） ---
          if (_expanded) ...[
            Container(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'TASKS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  ...m.tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${task.exp} EXP',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

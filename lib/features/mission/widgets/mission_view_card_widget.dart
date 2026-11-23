import 'package:flutter/material.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/mission.dart';
import 'task_view_item_widget.dart';

/// ミッション画面用のミッションカード（読み取り専用、完了操作不可）
class MissionViewCardWidget extends StatelessWidget {
  final Mission mission;

  const MissionViewCardWidget({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final completedTasksCount = mission.tasks
        .where((t) => t.isCompleted)
        .length;
    final totalTasksCount = mission.tasks.length;
    final progress = totalTasksCount > 0
        ? completedTasksCount / totalTasksCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（進捗のみ表示）
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$completedTasksCount / $totalTasksCount タスク完了',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // プログレス表示
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.accent,
                        ),
                        strokeWidth: 4,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // タスクリスト（読み取り専用）
          Column(
            children: mission.tasks.map((task) {
              return TaskViewItemWidget(task: task);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

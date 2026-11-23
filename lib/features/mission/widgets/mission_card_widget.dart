import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/animations/progress_animation_controller.dart';
import '../domain/mission.dart';
import 'task_item_widget.dart';

class MissionCardWidget extends ConsumerStatefulWidget {
  final Mission mission;

  const MissionCardWidget({super.key, required this.mission});

  @override
  ConsumerState<MissionCardWidget> createState() => _MissionCardWidgetState();
}

class _MissionCardWidgetState extends ConsumerState<MissionCardWidget>
    with TickerProviderStateMixin {
  late ProgressAnimationController _animationController;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = ProgressAnimationController(
      vsync: this,
      progressDuration: const Duration(milliseconds: 600),
      pulseDuration: const Duration(milliseconds: 300),
    );

    final completedCount = widget.mission.tasks
        .where((t) => t.isCompleted)
        .length;
    final totalCount = widget.mission.tasks.length;
    final initialProgress = totalCount > 0 ? completedCount / totalCount : 0.0;
    _animationController.setProgress(initialProgress);
    _previousProgress = initialProgress;
  }

  @override
  void didUpdateWidget(MissionCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final completedCount = widget.mission.tasks
        .where((t) => t.isCompleted)
        .length;
    final totalCount = widget.mission.tasks.length;
    final newProgress = totalCount > 0 ? completedCount / totalCount : 0.0;

    if ((_previousProgress - newProgress).abs() > 0.001) {
      // 通常は増加のみなのでシンプルにアニメーション
      _animationController.animateToProgress(newProgress, withPulse: false);
      _previousProgress = newProgress;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedTasksCount = widget.mission.tasks
        .where((t) => t.isCompleted)
        .length;
    final totalTasksCount = widget.mission.tasks.length;
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
                AnimatedBuilder(
                  animation: _animationController.progressAnimation,
                  builder: (context, child) {
                    final animatedProgress = _animationController
                        .getAnimatedProgress();

                    return SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: animatedProgress,
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
                    );
                  },
                ),
              ],
            ),
          ),
          // タスク列ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 34), // チェックボックス分のスペース
                Expanded(
                  child: Text(
                    'タスク',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Text(
                  '獲得経験値',
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
          // タスクリスト
          Column(
            children: widget.mission.tasks.map((task) {
              return TaskItemWidget(task: task, missionId: widget.mission.id);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

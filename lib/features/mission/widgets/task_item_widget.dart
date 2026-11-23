import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/animation_providers.dart';
import '../../../core/animations/animation_types.dart';
import '../../../core/animations/level_up_overlay.dart';
import '../../../core/animations/level_up_state_provider.dart';
import '../../../core/animations/mission_complete_overlay.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/providers/user_stats_provider.dart';
import '../../home/providers/exp_progress_controller_provider.dart';
import '../domain/task.dart';
import '../providers/mission_provider.dart';
import '../providers/task_completion_service.dart';

class TaskItemWidget extends ConsumerStatefulWidget {
  final Task task;
  final String missionId;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.missionId,
  });

  @override
  ConsumerState<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends ConsumerState<TaskItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    debugPrint(
      '🎯 TaskItem: _handleTap called - task: ${widget.task.title}, isCompleted: ${widget.task.isCompleted}',
    );

    // Haptic feedback
    HapticFeedback.lightImpact();

    // スケールアニメーション
    await _scaleController.forward();
    _scaleController.reverse();

    final service = ref.read(taskCompletionServiceProvider);
    final coordinator = ref.read(animationCoordinatorProvider);
    final progressController = ref.read(expProgressControllerProvider);

    // context と Navigator を事前にキャプチャ（dispose後でも使えるよう保存）
    // ミッション完了時にこのウィジェットがツリーから外れても
    // ルートNavigatorからモーダルを表示できるようにする
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // LevelUpStateNotifier を await より前にキャプチャ
    // StateNotifierProvider の Notifier はウィジェットの dispose に関係なく
    // アプリが動いている間存在し続けるため、dispose 後でも安全に呼び出せる
    final levelUpNotifier = ref.read(levelUpStateProvider.notifier);

    // レベルアップ前のprogressを計算するため、現在のUserStatsを取得
    final userStatsAsync = ref.read(userStatsProvider);
    final currentStats = userStatsAsync.value;
    final progressBeforeLevelUp =
        currentStats != null && currentStats.nextLevelExp > 0
        ? currentStats.currentExp / currentStats.nextLevelExp
        : 0.0;

    debugPrint(
      '🎯 TaskItem: Before toggle - currentExp: ${currentStats?.currentExp}, nextLevelExp: ${currentStats?.nextLevelExp}',
    );
    debugPrint(
      '🎯 TaskItem: progressBeforeLevelUp: ${progressBeforeLevelUp.toStringAsFixed(3)}',
    );

    // タスク完了処理を実行
    final result = await service.toggleTaskCompletion(
      missionId: widget.missionId,
      taskId: widget.task.id,
      isCurrentlyCompleted: widget.task.isCompleted,
      taskExp: widget.task.exp,
    );

    debugPrint(
      '🎯 TaskItem: After toggle - leveledUp: ${result.leveledUp}, oldLevel: ${result.oldLevel}, newLevel: ${result.newLevel}, missionCompleted: ${result.missionCompleted}',
    );

    // ミッション完了処理用に notifier をキャプチャ
    final missionListNotifier = ref.read(missionListProvider.notifier);
    final missionId = widget.missionId;

    // レベルアップした場合はオーバーレイを表示（高優先度）
    // ※ミッション完了時にこのウィジェットがdisposeされている可能性があるため
    //   !mounted チェックをスキップし、事前にキャプチャしたNavigatorを使用する
    if (result.leveledUp &&
        result.oldLevel != null &&
        result.newLevel != null) {
      debugPrint(
        '🎯 TaskItem: Level up detected! ${result.oldLevel} -> ${result.newLevel}',
      );

      // Haptic feedback for level up
      HapticFeedback.mediumImpact();

      // レベルアップモーダルの状態を更新（旧レベル、新レベル、progressを渡す）
      // ※ levelUpNotifier は await 前にキャプチャ済みのため
      //   ウィジェットが dispose されていても安全に呼び出せる
      debugPrint('🎯 TaskItem: Calling openModal (mounted: $mounted)');
      levelUpNotifier.openModal(
        result.oldLevel!,
        result.newLevel!,
        progressBeforeLevelUp,
      );

      debugPrint(
        '🎯 TaskItem: Waiting for progress animation to reach 100%...',
      );
      // プログレスバーが100%に到達するまで待つ
      await progressController.animateToProgressAndWait(1.0, withPulse: false);
      debugPrint(
        '🎯 TaskItem: Progress animation reached 100%, showing modal...',
      );

      // アニメーション完了後にモーダル表示
      // mounted でなくても事前キャプチャした rootNavigator を使って表示する
      final shouldCompleteMission = result.missionCompleted;
      coordinator.enqueue(
        AnimationTask(
          id: 'levelup_${result.newLevel}',
          type: AnimationType.levelUp,
          priority: AnimationPriority.high,
          estimatedDuration: const Duration(seconds: 3),
          onExecute: () {
            // showDialog + useRootNavigator でモーダルを表示
            // PageRouteBuilder の push は go_router のスタックと干渉するため使用しない
            // rootNavigator.overlay!.context を使うことで dispose 後も安全に表示できる
            showDialog(
              context: rootNavigator.overlay!.context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              useRootNavigator: true,
              builder: (dialogContext) => Material(
                type: MaterialType.transparency,
                child: LevelUpOverlay(
                  oldLevel: result.oldLevel!,
                  newLevel: result.newLevel!,
                  onDismiss: () {
                    debugPrint('🎯 TaskItem: LevelUp modal dismissed');
                    Navigator.of(dialogContext).pop();
                    // closeModal は LevelUpOverlay 内（ConsumerWidget）で呼ぶ

                    // レベルアップモーダルが閉じた後にミッション完了モーダルを表示
                    if (shouldCompleteMission) {
                      debugPrint(
                        '🎯 TaskItem: Showing mission complete modal after level up',
                      );
                      _showMissionCompleteModal(
                        rootNavigator,
                        missionListNotifier,
                        missionId,
                        levelBefore: result.oldLevel,
                        levelAfter: result.newLevel,
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      );
    } else {
      debugPrint(
        '🎯 TaskItem: No level up - normal task completion/incompletion',
      );

      // レベルアップなしでミッション完了した場合
      if (result.missionCompleted) {
        debugPrint('🎯 TaskItem: Completing mission (no level up)');
        // 経験値プログレスバーのアニメーション完了を待ってからモーダル表示
        await Future.delayed(const Duration(milliseconds: 800));
        _showMissionCompleteModal(
          rootNavigator,
          missionListNotifier,
          missionId,
          levelBefore: result.oldLevel,
          levelAfter: result.newLevel,
        );
      }
    }
  }

  /// ミッション完了モーダルを表示
  void _showMissionCompleteModal(
    NavigatorState rootNavigator,
    MissionListNotifier missionListNotifier,
    String missionId, {
    int? levelBefore,
    int? levelAfter,
  }) {
    showDialog(
      context: rootNavigator.overlay!.context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (dialogContext) => Material(
        type: MaterialType.transparency,
        child: MissionCompleteOverlay(
          onDismiss: () {
            debugPrint('🎯 TaskItem: Mission complete modal dismissed');
            Navigator.of(dialogContext).pop();
            // モーダルが閉じた後にミッションをクリア
            missionListNotifier.completeMission(
              missionId,
              levelBefore: levelBefore,
              levelAfter: levelAfter,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _handleTap,
            splashColor: context.accent.withValues(alpha: 0.1),
            highlightColor: context.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  // チェックボックス (円形)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: widget.task.isCompleted
                          ? context.accent
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.task.isCompleted
                            ? context.accent
                            : AppColors.borderDark,
                        width: 2,
                      ),
                    ),
                    child: widget.task.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // タスクタイトル
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.task.isCompleted
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  // 経験値バッジ
                  Text(
                    '+${widget.task.exp} EXP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.task.isCompleted
                          ? AppColors.borderDark
                          : context.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

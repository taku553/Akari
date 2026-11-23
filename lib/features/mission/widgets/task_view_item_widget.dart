import 'package:flutter/material.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/task.dart';

/// ミッション画面用のタスクアイテム（読み取り専用、完了操作不可）
class TaskViewItemWidget extends StatelessWidget {
  final Task task;

  const TaskViewItemWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            // チェックボックス (円形、読み取り専用)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? context.accent
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted
                      ? context.accent
                      : AppColors.borderDark,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            // タスク名
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  color: task.isCompleted
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 経験値バッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${task.exp} EXP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

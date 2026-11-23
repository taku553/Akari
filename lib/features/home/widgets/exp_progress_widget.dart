import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/animations/progress_animation_controller.dart';
import '../../../core/animations/level_up_state_provider.dart';
import '../providers/exp_progress_controller_provider.dart';

class ExpProgressWidget extends ConsumerStatefulWidget {
  final int level;
  final int currentExp;
  final int nextLevelExp;

  const ExpProgressWidget({
    super.key,
    required this.level,
    required this.currentExp,
    required this.nextLevelExp,
  });

  @override
  ConsumerState<ExpProgressWidget> createState() => _ExpProgressWidgetState();
}

class _ExpProgressWidgetState extends ConsumerState<ExpProgressWidget>
    with TickerProviderStateMixin {
  late ProgressAnimationController _animationController;
  double _previousProgress = 0.0;
  // dispose時に ref を使わずアクセスできるよう、事前にホルダーの参照を保持する
  ExpProgressControllerHolder? _controllerHolder;

  @override
  void initState() {
    super.initState();
    _animationController = ProgressAnimationController(vsync: this);

    final initialProgress = widget.nextLevelExp > 0
        ? widget.currentExp / widget.nextLevelExp
        : 0.0;
    _animationController.setProgress(initialProgress);
    _previousProgress = initialProgress;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Providerにコントローラーを登録（同時にホルダー参照を保持）
    _controllerHolder = ref.read(expProgressControllerProvider);
    _controllerHolder!.controller = _animationController;
  }

  @override
  void didUpdateWidget(ExpProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newProgress = widget.nextLevelExp > 0
        ? widget.currentExp / widget.nextLevelExp
        : 0.0;

    // レベルアップモーダルの状態をリスン
    final levelUpState = ref.watch(levelUpStateProvider);

    debugPrint('📊 ExpProgress: didUpdateWidget called');
    debugPrint(
      '  - currentExp: ${widget.currentExp}, nextLevelExp: ${widget.nextLevelExp}',
    );
    debugPrint(
      '  - newProgress: ${newProgress.toStringAsFixed(3)}, _previousProgress: ${_previousProgress.toStringAsFixed(3)}',
    );
    debugPrint(
      '  - modalJustClosed: ${levelUpState.modalJustClosed}, isModalOpen: ${levelUpState.isModalOpen}',
    );
    debugPrint(
      '  - level: ${widget.level}, displayLevel: ${levelUpState.displayLevel}',
    );

    // モーダル表示中は通常のプログレス更新をスキップ
    if (levelUpState.isModalOpen) {
      debugPrint('📊 ExpProgress: ⏭️ Skipping update (modal is open)');
      return;
    }

    // 通常のプログレス更新（減少も含む）
    final diff = (_previousProgress - newProgress).abs();
    if (diff > 0.001) {
      debugPrint(
        '📊 ExpProgress: ✅ Normal update branch - diff: ${diff.toStringAsFixed(3)}',
      );
      debugPrint(
        '  - Animating from ${_previousProgress.toStringAsFixed(3)} to ${newProgress.toStringAsFixed(3)}',
      );
      _previousProgress = newProgress; // 即座に更新
      _animationController.animateToProgress(newProgress, withPulse: false);
    } else {
      debugPrint(
        '📊 ExpProgress: ⏭️ Skipping update (diff too small: ${diff.toStringAsFixed(4)})',
      );
    }
  }

  @override
  void dispose() {
    // ref は dispose 時点で無効なため、事前キャプチャしたホルダー経由で解除
    _controllerHolder?.controller = null;
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // modalJustClosedフラグの監視（状態変化時に即座にリセット処理）
    ref.listen<LevelUpState>(levelUpStateProvider, (previous, next) {
      debugPrint(
        '📊 ExpProgress: levelUpStateProvider changed - modalJustClosed: ${next.modalJustClosed}',
      );

      if (next.modalJustClosed && !(previous?.modalJustClosed ?? false)) {
        debugPrint(
          '📊 ExpProgress: 🔥 modalJustClosed flag detected via listen!',
        );

        // 現在のプログレスを計算
        final newProgress = widget.nextLevelExp > 0
            ? widget.currentExp / widget.nextLevelExp
            : 0.0;

        debugPrint(
          '  - Resetting progress to 0, then animating to ${newProgress.toStringAsFixed(3)}',
        );

        // 即座に0にリセット
        _animationController.setProgress(0.0);
        _previousProgress = 0.0;

        // 繰越分がある場合はアニメーション
        if (newProgress > 0.001) {
          _animationController.animateToProgress(newProgress, withPulse: false);
          _previousProgress = newProgress;
        }

        // フラグをクリア（次のフレームまで待つ）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint(
              '📊 ExpProgress: Calling clearClosedFlag from listen PostFrameCallback',
            );
            try {
              ref.read(levelUpStateProvider.notifier).clearClosedFlag();
            } catch (e) {
              // ref が dispose 後にアクセスされた場合は無視
              debugPrint(
                '📊 ExpProgress: clearClosedFlag skipped (ref disposed): $e',
              );
            }
          }
        });
      }
    });

    final progress = widget.nextLevelExp > 0
        ? widget.currentExp / widget.nextLevelExp
        : 0.0;

    // レベルアップモーダル表示中は旧レベルを表示
    final levelUpState = ref.watch(levelUpStateProvider);
    final displayLevel = levelUpState.displayLevel ?? widget.level;

    return Column(
      children: [
        // 円形プログレスバー
        AnimatedBuilder(
          animation: _animationController.progressAnimation,
          builder: (context, child) {
            final animatedProgress = _animationController.getAnimatedProgress();

            return SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // プログレスリング
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _CircularProgressPainter(
                      progress: animatedProgress,
                      backgroundColor: AppColors.borderLight,
                      progressColor: context.accent,
                      strokeWidth: 18,
                    ),
                  ),
                  // 中央のテキスト
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$displayLevel',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 50,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // 経験値バッジ（右上）
                  Positioned(
                    top: -20,
                    right: -60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.backgroundWhite,
                            AppColors.backgroundLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.currentExp}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.accent,
                            ),
                          ),
                          Text(
                            ' / ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.borderDark,
                            ),
                          ),
                          Text(
                            '${widget.nextLevelExp}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'EXP',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景の円
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // プログレスの円弧
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 上部から開始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}

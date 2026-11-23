import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/accent_color.dart';
import '../theme/app_colors.dart';

/// ミッション完了時に表示されるモーダルオーバーレイ
class MissionCompleteOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const MissionCompleteOverlay({super.key, required this.onDismiss});

  @override
  State<MissionCompleteOverlay> createState() => _MissionCompleteOverlayState();
}

class _MissionCompleteOverlayState extends State<MissionCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _textSlideController;
  late AnimationController _missionTextController;
  late AnimationController _tapHintController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _congratsSlideAnimation;
  late Animation<double> _congratsOpacityAnimation;
  late Animation<double> _missionSlideAnimation;
  late Animation<double> _missionOpacityAnimation;
  late Animation<double> _tapHintAnimation;

  @override
  void initState() {
    super.initState();

    // 背景フェードインアニメーション（0.5秒）
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // 「Congratulations!」テキストのスライドアニメーション（0.5秒）
    _textSlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 下から上へスライド（40px下から）
    _congratsSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOut),
    );

    // テキストの不透明度
    _congratsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOut),
    );

    // 「Mission Complete」テキストアニメーション（0.5秒）
    _missionTextController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _missionSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _missionTextController, curve: Curves.easeOut),
    );

    _missionOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _missionTextController, curve: Curves.easeOut),
    );

    // タップヒントのフェードイン（500ms）
    _tapHintController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tapHintAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tapHintController, curve: Curves.easeOut),
    );

    // アニメーションシーケンス開始
    _startAnimations();
  }

  void _startAnimations() async {
    // 1. 背景フェードイン（同時スタート）
    _fadeController.forward();

    // 背景が少し表示されてからテキストスライド
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. 「Congratulations!」テキストスライド
    _textSlideController.forward();

    // 3. 300ms後に「Mission Complete」テキストスライド
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _missionTextController.forward();
    }

    // 4. 1.5秒後にタップヒント表示
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      _tapHintController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textSlideController.dispose();
    _missionTextController.dispose();
    _tapHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          final content = Stack(
            children: [
              // コンフェッティアニメーション（2つ同時表示）
              _buildConfetti(),

              // ミッション完了コンテンツ
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCongratulationsText(),
                    const SizedBox(height: 24),
                    _buildMissionCompleteText(),
                    const SizedBox(height: 12),
                    _buildSubText(),
                  ],
                ),
              ),

              // タップヒント
              _buildTapHint(),
            ],
          );

          // Webではブラー効果が重いため、暗い背景のみを使用
          if (kIsWeb) {
            return Container(
              color: Colors.black.withValues(alpha: 0.8 * _fadeAnimation.value),
              child: content,
            );
          }

          // ネイティブではブラー効果を使用
          return Container(
            color: Colors.black.withValues(alpha: 0.6 * _fadeAnimation.value),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12.0 * _fadeAnimation.value,
                sigmaY: 12.0 * _fadeAnimation.value,
              ),
              child: content,
            ),
          );
        },
      ),
    );
  }

  /// "Congratulations!" テキスト（スライドアニメーション付き）
  Widget _buildCongratulationsText() {
    return AnimatedBuilder(
      animation: _textSlideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _congratsSlideAnimation.value),
          child: Opacity(
            opacity: _congratsOpacityAnimation.value,
            child: Text(
              'Congratulations!',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                color: AppColors.levelUpGold,
                shadows: [
                  Shadow(
                    color: AppColors.levelUpGold.withValues(alpha: 0.6),
                    blurRadius: 20,
                  ),
                  Shadow(
                    color: AppColors.levelUpGold.withValues(alpha: 0.4),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// "Mission Complete" テキスト
  Widget _buildMissionCompleteText() {
    return AnimatedBuilder(
      animation: _missionTextController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _missionSlideAnimation.value),
          child: Opacity(
            opacity: _missionOpacityAnimation.value,
            child: Text(
              'Mission Complete',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.levelUpWhite,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: context.accent.withValues(alpha: 0.6),
                    blurRadius: 60,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// "ミッションが完了しました" サブテキスト
  Widget _buildSubText() {
    return AnimatedBuilder(
      animation: _missionTextController,
      builder: (context, child) {
        return Opacity(
          opacity: _missionOpacityAnimation.value,
          child: Text(
            'ミッションが完了しました',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
        );
      },
    );
  }

  /// コンフェッティアニメーション（2つのLottie同時表示）
  Widget _buildConfetti() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Confetti_mission_completed.json
          Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Lottie.asset(
                  'assets/animations/Confetti_mission_completed.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ),
          // Celebrate Red Yellow.json
          Center(
            child: SizedBox(
              width: 450,
              height: 450,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Lottie.asset(
                  'assets/animations/Celebrate Red Yellow.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Tap to continue" ヒント
  Widget _buildTapHint() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _tapHintController,
        builder: (context, child) {
          return Opacity(
            opacity: _tapHintAnimation.value,
            child: Center(
              child: Text(
                'Tap to continue',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

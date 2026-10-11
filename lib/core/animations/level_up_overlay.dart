import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import 'level_up_state_provider.dart';

/// レベルアップ時に表示されるモーダルオーバーレイ
/// デザインカンプのHTMLに基づいた実装
class LevelUpOverlay extends ConsumerStatefulWidget {
  final int oldLevel;
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  ConsumerState<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends ConsumerState<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _textSlideController;
  late AnimationController _numberSlideController;
  late AnimationController _tapHintController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _oldNumberSlideAnimation;
  late Animation<double> _newNumberSlideAnimation;
  late Animation<double> _oldNumberOpacityAnimation;
  late Animation<double> _newNumberOpacityAnimation;
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

    // 「Level Up!」テキストのスライドアニメーション（0.5秒）
    _textSlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 下から上へスライド（40px下から）
    _textSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOut),
    );

    // テキストの不透明度
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOut),
    );

    // 数字スライドアニメーション（0.7秒）
    _numberSlideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // 旧レベル番号：上にスライドアウト
    _oldNumberSlideAnimation = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _numberSlideController, curve: Curves.easeInOut),
    );

    // 新レベル番号：下からスライドイン
    _newNumberSlideAnimation = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _numberSlideController, curve: Curves.easeInOut),
    );

    // 不透明度アニメーション
    _oldNumberOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _numberSlideController, curve: Curves.easeInOut),
    );

    _newNumberOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _numberSlideController, curve: Curves.easeInOut),
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

    // 2. 「Level Up!」テキストスライド（同時スタート）
    _textSlideController.forward();

    // 3. 800ミリ秒後にレベル数字スライド開始
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      _numberSlideController.forward();
    }

    // 4. 2.5秒後にタップヒント表示
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _tapHintController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textSlideController.dispose();
    _numberSlideController.dispose();
    _tapHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // onDismiss コールバックを呼ぶ（Navigator.pop など）
        widget.onDismiss();
        // モーダルが閉じられたことを Provider に通知（ConsumerWidget なので ref を使える）
        debugPrint('🎯 LevelUpOverlay: Calling closeModal(${widget.newLevel})');
        ref.read(levelUpStateProvider.notifier).closeModal(widget.newLevel);
      },
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          final content = Stack(
            children: [
              // コンフェッティアニメーション（レベルアップ時は常に表示）
              _buildConfetti(),

              // レベルアップコンテンツ
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLevelUpText(),
                    const SizedBox(height: 24),
                    _buildLevelNumber(),
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

  /// "Level Up!" テキスト（スライドアニメーション付き）
  Widget _buildLevelUpText() {
    return AnimatedBuilder(
      animation: _textSlideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: Opacity(
            opacity: _textOpacityAnimation.value,
            child: Text(
              'Level Up!',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 28,
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

  /// レベル番号（スライドアニメーション付き）
  Widget _buildLevelNumber() {
    return SizedBox(
      height: 90,
      width: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 旧レベル番号（上にスライドアウト）
          AnimatedBuilder(
            animation: _numberSlideController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _oldNumberSlideAnimation.value),
                child: Opacity(
                  opacity: _oldNumberOpacityAnimation.value,
                  child: _buildNumberText(widget.oldLevel),
                ),
              );
            },
          ),
          // 新レベル番号（下からスライドイン）
          AnimatedBuilder(
            animation: _numberSlideController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _newNumberSlideAnimation.value),
                child: Opacity(
                  opacity: _newNumberOpacityAnimation.value,
                  child: _buildNumberText(widget.newLevel),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// レベル番号のテキストスタイル
  Widget _buildNumberText(int level) {
    return Text(
      '$level',
      style: TextStyle(
        fontFamily: 'Lato',
        fontSize: 72,
        fontWeight: FontWeight.w800,
        color: AppColors.levelUpWhite,
        height: 1.0,
        letterSpacing: 2,
        shadows: [
          Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 30),
          Shadow(
            color: AppColors.primary.withValues(alpha: 0.6),
            blurRadius: 60,
          ),
        ],
      ),
    );
  }

  /// コンフェッティアニメーション（Lottie）
  Widget _buildConfetti() {
    return Positioned.fill(
      child: Center(
        child: SizedBox(
          width: 600,
          height: 600,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Lottie.asset(
              'assets/animations/confetti.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
        ),
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

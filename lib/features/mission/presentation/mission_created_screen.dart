import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_palette.dart';

/// ミッション作成成功画面
/// デザインカンプのHTMLに基づいたアニメーション付き成功画面
class MissionCreatedScreen extends StatefulWidget {
  const MissionCreatedScreen({super.key});

  @override
  State<MissionCreatedScreen> createState() => _MissionCreatedScreenState();
}

class _MissionCreatedScreenState extends State<MissionCreatedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _subtextOpacityAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // アニメーションコントローラーの初期化（1200ms）
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // アイコンのスケールアニメーション（0〜720ms = Interval 0.0〜0.6）
    // 「中心から大きくなり→少しオーバーシュート→縮んで定位置」という
    // スプリングアニメーション（Overshoot / Back-out アニメーション）を実現する
    // カスタムカーブ。CSS の cubic-bezier(0.34, 1.56, 0.64, 1.0) 相当。
    const overshootCurve = Cubic(0.34, 1.56, 0.34, 1.0);
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: overshootCurve),
      ),
    );

    // テキストのフェードアニメーション（480〜840ms = Interval 0.4〜0.7）
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    // テキストのスライドアニメーション（同区間）
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
          ),
        );

    // サブテキストのフェードアニメーション（600〜900ms = Interval 0.5〜0.75）
    _subtextOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    // アニメーション開始
    _controller.forward();

    // 2秒後にホーム画面へ自動遷移
    _navigationTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundWhite.withValues(alpha: 0.98),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ピンクグラデーションの円形アイコン
            ScaleTransition(
              scale: _iconScaleAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.accent,
                      context.accent.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: context.onAccent, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            // "MISSION CREATED" テキスト
            SlideTransition(
              position: _textSlideAnimation,
              child: FadeTransition(
                opacity: _textOpacityAnimation,
                child: Text(
                  'MISSION CREATED',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // "ホーム画面に戻ります" サブテキスト
            FadeTransition(
              opacity: _subtextOpacityAnimation,
              child: Text(
                'ホーム画面に戻ります',
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

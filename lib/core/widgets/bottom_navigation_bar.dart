import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/accent_color.dart';
import '../theme/app_colors.dart';

/// ShellRoute 用のスキャフォールド
/// ボトムナビゲーションバーを含み、子ウィジェットを表示する
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const _BottomNavBar());
  }
}

/// ボトムナビゲーションバー（内部使用）
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/missions')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0; // ホーム
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/missions');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home,
                      label: 'ホーム',
                      isActive: currentIndex == 0,
                      onTap: () => _onItemTapped(context, 0),
                    ),
                    _NavItem(
                      icon: Icons.gps_fixed,
                      label: 'ミッション',
                      isActive: currentIndex == 1,
                      onTap: () => _onItemTapped(context, 1),
                    ),
                    _NavItem(
                      icon: Icons.settings,
                      label: '設定',
                      isActive: currentIndex == 2,
                      onTap: () => _onItemTapped(context, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? context.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? context.accent : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isActive ? context.accent : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

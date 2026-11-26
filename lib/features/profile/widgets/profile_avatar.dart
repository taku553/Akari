import 'package:flutter/material.dart';
import '../../../core/theme/accent_color.dart';

/// プロフィール画像を円形に表示する。画像がない・読み込みに失敗した場合は頭文字を表示する。
class ProfileAvatar extends StatelessWidget {
  final double radius;
  final double fontSize;
  final String initial;
  final String? imageUrl;

  const ProfileAvatar({
    super.key,
    required this.radius,
    required this.fontSize,
    required this.initial,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: context.accentBackground,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: context.accent,
        ),
      ),
    );

    final url = imageUrl;
    if (url == null) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore の `users/{uid}.subscription` から読み取ったサブスクリプションの状態。
/// 形式: { active: bool, expiresAt: Timestamp（任意） }
class SubscriptionStatus {
  final bool active;
  final DateTime? expiresAt;

  const SubscriptionStatus({required this.active, this.expiresAt});

  static const none = SubscriptionStatus(active: false);

  /// `subscription` マップから生成する。不正な形式・未設定は無効（none）として扱う。
  factory SubscriptionStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null || map['active'] != true) return none;

    final raw = map['expiresAt'];
    final expiresAt = switch (raw) {
      Timestamp() => raw.toDate(),
      DateTime() => raw,
      _ => null,
    };
    return SubscriptionStatus(active: true, expiresAt: expiresAt);
  }

  /// [now] の時点で有効か。期限（expiresAt）が設定されている場合は、期限内のときのみ有効。
  bool isActiveAt(DateTime now) {
    if (!active) return false;
    final expiry = expiresAt;
    return expiry == null || now.isBefore(expiry);
  }
}

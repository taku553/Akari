import 'package:akari/features/subscription/domain/subscription_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 24, 22, 0);

  group('SubscriptionStatus', () {
    test('未設定・active が true 以外・不正な形式は無効', () {
      expect(SubscriptionStatus.fromMap(null).isActiveAt(now), isFalse);
      expect(SubscriptionStatus.fromMap({}).isActiveAt(now), isFalse);
      expect(
        SubscriptionStatus.fromMap({'active': false}).isActiveAt(now),
        isFalse,
      );
      expect(
        SubscriptionStatus.fromMap({'active': 'true'}).isActiveAt(now),
        isFalse,
      );
    });

    test('active が true で期限なしなら有効', () {
      expect(
        SubscriptionStatus.fromMap({'active': true}).isActiveAt(now),
        isTrue,
      );
    });

    test('expiresAt が未来なら有効、過去・同時刻なら期限切れで無効', () {
      SubscriptionStatus at(DateTime expiry) => SubscriptionStatus.fromMap({
        'active': true,
        'expiresAt': Timestamp.fromDate(expiry),
      });

      expect(at(now.add(const Duration(days: 1))).isActiveAt(now), isTrue);
      expect(
        at(now.subtract(const Duration(minutes: 4))).isActiveAt(now),
        isFalse,
      );
      expect(at(now).isActiveAt(now), isFalse);
    });
  });
}

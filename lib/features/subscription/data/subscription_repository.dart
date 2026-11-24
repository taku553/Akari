import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/subscription_status.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーのサブスクリプション状態を監視する。
  /// アプリからは書き込まない（権利の確定は信頼できる経路でのみ行う）。
  Stream<SubscriptionStatus> watch(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      final raw = snap.data()?['subscription'];
      return SubscriptionStatus.fromMap(
        raw is Map ? Map<String, dynamic>.from(raw) : null,
      );
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_stats.dart';

class UserStatsRepository {
  static const String _sharedBoxName = 'userStats';
  static const String _statsKey = 'stats';

  final String? uid;
  Box<UserStats>? _box;

  /// UID別のボックス名（未設定時は共有ボックス）
  String get _boxName => uid != null ? 'userStats_$uid' : _sharedBoxName;

  UserStatsRepository({this.uid});

  /// Firestoreの stats ドキュメント参照（UID未設定時は null）
  DocumentReference? get _statsDoc => uid != null
      ? FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('stats')
            .doc('current')
      : null;

  // Boxの初期化（旧共有ボックスからの移行 → Firestoreマイグレーション）
  Future<void> init() async {
    debugPrint('🔧 UserStatsRepository: Initializing...');
    _box = await Hive.openBox<UserStats>(_boxName);
    debugPrint(
      '🔧 UserStatsRepository: Initialized. Box "$_boxName" has ${_box?.length ?? 0} stats',
    );
    // 旧共有ボックスからUID別ボックスへデータを移行
    await _migrateFromSharedBox();
    // UID別ボックスのデータをFirestoreへ移行
    await _migrateLocalToFirestoreIfNeeded();
    // 既存アカウントの累計経験値・ミッション完了数をFirestoreのミッション履歴から集計
    await _migrateTotalStatsIfNeeded();
  }

  /// 旧共有ボックス（'userStats'）からUID別ボックスへデータを移行する
  /// 移行後、旧共有ボックスをクリアする（他ユーザーへの混入防止）
  Future<void> _migrateFromSharedBox() async {
    if (uid == null) return;
    // UID別ボックスに既にデータがある場合はスキップ（移行済み）
    if (_box != null && _box!.isNotEmpty) {
      debugPrint(
        '🔧 UserStatsRepository: UID box already has data, skipping shared box migration',
      );
      return;
    }
    try {
      final sharedBox = await Hive.openBox<UserStats>(_sharedBoxName);
      final sharedStats = sharedBox.get(_statsKey);
      if (sharedStats == null) {
        debugPrint(
          '🔧 UserStatsRepository: Shared box is empty, nothing to migrate',
        );
        await sharedBox.close();
        return;
      }
      debugPrint(
        '🔧 UserStatsRepository: Migrating stats from shared box (level=${sharedStats.level}) to UID box...',
      );
      await _box?.put(_statsKey, sharedStats);
      // 旧共有ボックスをクリア（次回ログイン時の混入防止）
      await sharedBox.clear();
      await sharedBox.close();
      debugPrint(
        '🔧 UserStatsRepository: Shared box migration complete & cleared',
      );
    } catch (e) {
      debugPrint('⚠️ UserStatsRepository: Shared box migration failed: $e');
    }
  }

  /// 初回起動時のみ: ローカルHiveデータをFirestoreに移行する
  /// Firestoreにすでにデータがある場合は何もしない（リアルタイムストリームが同期する）
  Future<void> _migrateLocalToFirestoreIfNeeded() async {
    if (_statsDoc == null) {
      debugPrint('⚠️ UserStatsRepository: No UID, skipping migration check');
      return;
    }
    try {
      final snapshot = await _statsDoc!.get();
      if (snapshot.exists) {
        debugPrint(
          '☁️ UserStatsRepository: Firestore has data, stream will sync',
        );
        return;
      }
      // Firestoreが空 → ローカルデータをマイグレーション
      final localStats = _box?.get(_statsKey) ?? const UserStats();
      await _statsDoc!.set(localStats.toJson());
      debugPrint(
        '☁️ UserStatsRepository: Migrated local data to Firestore. level=${localStats.level}',
      );
    } catch (e) {
      debugPrint(
        '⚠️ UserStatsRepository: Migration check failed (offline?). error=$e',
      );
    }
  }

  /// 既存アカウント向け: Firestoreのミッション履歴から累計経験値・完了数を集計する
  /// totalExp が 0 かつ level > 1（過去に経験値を得ているはず）の場合のみ実行
  Future<void> _migrateTotalStatsIfNeeded() async {
    if (uid == null || _statsDoc == null) return;
    try {
      final snapshot = await _statsDoc!.get();
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      // totalExp フィールドが既に存在する場合はスキップ（移行済み）
      // ※ データ削除機能で経験値のみ0に戻した場合に再集計されないよう、0も移行済みとして扱う
      final existingTotalExp = data['totalExp'] as int?;
      if (existingTotalExp != null) {
        debugPrint(
          '☁️ UserStatsRepository: totalExp already exists ($existingTotalExp), skipping migration',
        );
        return;
      }

      // level が 1 で currentExp が 0 なら本当に新規なのでスキップ
      final level = data['level'] as int? ?? 1;
      final currentExp = data['currentExp'] as int? ?? 0;
      if (level <= 1 && currentExp == 0) {
        debugPrint(
          '☁️ UserStatsRepository: New account (level 1, 0 exp), skipping totalStats migration',
        );
        return;
      }

      debugPrint(
        '☁️ UserStatsRepository: Migrating totalStats from mission history...',
      );

      // Firestoreの全ミッションを取得
      final missionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('missions')
          .get();

      int totalExp = 0;
      int completedMissionCount = 0;

      for (final doc in missionsSnapshot.docs) {
        final missionData = doc.data();
        final completedAt = missionData['completedAt'];

        // 完了済みミッションをカウント
        if (completedAt != null) {
          completedMissionCount++;
        }

        // 全ミッション（完了・未完了問わず）の完了タスクのexpを合算
        final tasks = missionData['tasks'] as List<dynamic>? ?? [];
        for (final task in tasks) {
          final taskMap = task as Map<String, dynamic>;
          if (taskMap['isCompleted'] == true) {
            totalExp += (taskMap['exp'] as int? ?? 250);
          }
        }
      }

      debugPrint(
        '☁️ UserStatsRepository: Calculated totalExp=$totalExp, completedMissionCount=$completedMissionCount',
      );

      // 現在のstatsに反映して保存
      final currentStats = getStats();
      final updatedStats = currentStats.copyWith(
        totalExp: totalExp,
        completedMissionCount: completedMissionCount,
      );
      await saveStats(updatedStats);

      debugPrint('☁️ UserStatsRepository: totalStats migration complete');
    } catch (e) {
      debugPrint('⚠️ UserStatsRepository: totalStats migration failed: $e');
    }
  }

  /// Firestoreのリアルタイムストリーム
  /// 他デバイスでの変更が即座にこのストリームに流れる
  /// データが流れるたびにHiveキャッシュも更新する
  Stream<UserStats> get statsStream {
    if (_statsDoc == null) {
      // ゲスト（Hiveのみ）: 現在値を流した後、Hiveの変更を監視して流し続ける
      return _watchLocalStats();
    }
    return _statsDoc!.snapshots().map((doc) {
      if (doc.exists) {
        final stats = UserStats.fromJson(doc.data()! as Map<String, dynamic>);
        _box?.put(_statsKey, stats); // Hiveキャッシュを更新
        debugPrint(
          '🔴 UserStatsRepository: Realtime update. level=${stats.level}',
        );
        return stats;
      }
      return _box?.get(_statsKey) ?? const UserStats();
    });
  }

  Stream<UserStats> _watchLocalStats() async* {
    yield _box?.get(_statsKey) ?? const UserStats();
    final box = _box;
    if (box == null) return;
    yield* box.watch(key: _statsKey).map((_) => getStats());
  }

  // UserStats取得（Hiveキャッシュから）
  UserStats getStats() {
    return _box?.get(_statsKey) ?? const UserStats();
  }

  // UserStats保存（Hive + Firestore の両方に書き込む）
  Future<void> saveStats(UserStats stats) async {
    await _box?.put(_statsKey, stats);
    try {
      await _statsDoc?.set(stats.toJson());
      debugPrint(
        '☁️ UserStatsRepository: Saved to Firestore. level=${stats.level}',
      );
    } catch (e) {
      debugPrint(
        '⚠️ UserStatsRepository: Failed to save to Firestore (offline?). error=$e',
      );
    }
  }

  /// 選択した項目だけ初期値に戻す（Hive + Firestore）
  /// level: レベル / exp: 現在の経験値と累計経験値 / missionCount: 完了ミッション数
  Future<void> resetStats({
    required bool level,
    required bool exp,
    required bool missionCount,
  }) async {
    const defaults = UserStats();
    var stats = getStats();
    if (level) {
      stats = stats.copyWith(
        level: defaults.level,
        nextLevelExp: defaults.nextLevelExp,
        // 経験値を残す場合でもレベル1の上限を超えないようにする
        currentExp: stats.currentExp >= defaults.nextLevelExp
            ? defaults.nextLevelExp - 1
            : stats.currentExp,
      );
    }
    if (exp) {
      stats = stats.copyWith(
        currentExp: defaults.currentExp,
        totalExp: defaults.totalExp,
      );
    }
    if (missionCount) {
      stats = stats.copyWith(
        completedMissionCount: defaults.completedMissionCount,
      );
    }
    await saveStats(stats);
  }

  // 経験値加算とレベルアップ処理
  Future<UserStats> addExp(int exp) async {
    UserStats currentStats = getStats();
    int newExp = currentStats.currentExp + exp;
    int newLevel = currentStats.level;
    int requiredExp = currentStats.nextLevelExp;

    // レベルアップ判定（複数レベルアップにも対応）
    while (newExp >= requiredExp) {
      newExp -= requiredExp;
      newLevel++;
      requiredExp = _calculateNextLevelExp(newLevel);
    }

    final updatedStats = UserStats(
      level: newLevel,
      currentExp: newExp,
      nextLevelExp: requiredExp,
      totalExp: currentStats.totalExp + exp,
      completedMissionCount: currentStats.completedMissionCount,
    );

    await saveStats(updatedStats);
    return updatedStats;
  }

  // 経験値減算（レベルダウンなし、0でクリップ）
  Future<UserStats> subtractExp(int exp) async {
    UserStats currentStats = getStats();
    // 現在のレベル内でのみ減算（0未満にはならない）
    int newExp = (currentStats.currentExp - exp).clamp(
      0,
      currentStats.currentExp,
    );

    final updatedStats = UserStats(
      level: currentStats.level,
      currentExp: newExp,
      nextLevelExp: currentStats.nextLevelExp,
      totalExp: (currentStats.totalExp - exp).clamp(0, currentStats.totalExp),
      completedMissionCount: currentStats.completedMissionCount,
    );

    await saveStats(updatedStats);
    return updatedStats;
  }

  // 次レベルに必要な経験値を計算（線形増加）
  int _calculateNextLevelExp(int level) {
    return 100 + (level - 1) * 50; // Level 1→2: 100, Level 2→3: 150...
  }
}

// Riverpod Provider
// StateProvider: ログイン後にUID付きインスタンスで上書きされる
final userStatsRepositoryProvider = StateProvider<UserStatsRepository>((ref) {
  return UserStatsRepository();
});

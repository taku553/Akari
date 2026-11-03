import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mission.dart';

class MissionRepository {
  static const String _sharedBoxName = 'missions';

  final String? uid;
  Box<Mission>? _box;

  /// UID別のボックス名（未設定時は共有ボックス）
  String get _boxName => uid != null ? 'missions_$uid' : _sharedBoxName;

  MissionRepository({this.uid}) {
    debugPrint(
      '🏗️ MissionRepository: Constructor called (instance: $hashCode)',
    );
  }

  /// Firestoreの missions コレクション参照（UID未設定時は null）
  CollectionReference? get _missionsCol => uid != null
      ? FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('missions')
      : null;

  // Boxの初期化（旧共有ボックスからの移行 → Firestoreマイグレーション）
  Future<void> init() async {
    debugPrint('🔧 MissionRepository: Initializing... (instance: $hashCode)');
    _box = await Hive.openBox<Mission>(_boxName);
    debugPrint(
      '🔧 MissionRepository: Initialized. Box "$_boxName" has ${_box?.length ?? 0} missions',
    );
    // 旧共有ボックスからUID別ボックスへデータを移行
    await _migrateFromSharedBox();
    // UID別ボックスのデータをFirestoreへ移行
    await _migrateLocalToFirestoreIfNeeded();
  }

  /// 旧共有ボックス（'missions'）からUID別ボックスへデータを移行する
  /// 移行後、旧共有ボックスをクリアする（他ユーザーへの混入防止）
  Future<void> _migrateFromSharedBox() async {
    if (uid == null) return;
    // UID別ボックスに既にデータがある場合はスキップ（移行済み）
    if (_box != null && _box!.isNotEmpty) {
      debugPrint(
        '🔧 MissionRepository: UID box already has data, skipping shared box migration',
      );
      return;
    }
    try {
      final sharedBox = await Hive.openBox<Mission>(_sharedBoxName);
      if (sharedBox.isEmpty) {
        debugPrint(
          '🔧 MissionRepository: Shared box is empty, nothing to migrate',
        );
        await sharedBox.close();
        return;
      }
      debugPrint(
        '🔧 MissionRepository: Migrating ${sharedBox.length} missions from shared box to UID box...',
      );
      for (final key in sharedBox.keys) {
        final mission = sharedBox.get(key);
        if (mission != null) {
          await _box?.put(key, mission);
        }
      }
      // 旧共有ボックスをクリア（次回ログイン時の混入防止）
      await sharedBox.clear();
      await sharedBox.close();
      debugPrint(
        '🔧 MissionRepository: Shared box migration complete & cleared',
      );
    } catch (e) {
      debugPrint('⚠️ MissionRepository: Shared box migration failed: $e');
    }
  }

  /// 初回起動時のみ: ローカルHiveデータをFirestoreに移行する
  /// Firestoreにすでにデータがある場合は何もしない（リアルタイムストリームが同期する）
  Future<void> _migrateLocalToFirestoreIfNeeded() async {
    if (_missionsCol == null) {
      debugPrint('⚠️ MissionRepository: No UID, skipping migration check');
      return;
    }
    try {
      final snapshot = await _missionsCol!.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint(
          '☁️ MissionRepository: Firestore has data, stream will sync',
        );
        return;
      }
      // Firestoreが空 → ローカルデータをマイグレーション
      final localMissions = _box?.values.toList() ?? [];
      if (localMissions.isEmpty) {
        debugPrint('☁️ MissionRepository: No local missions to migrate');
        return;
      }
      debugPrint(
        '☁️ MissionRepository: Migrating ${localMissions.length} local missions to Firestore...',
      );
      for (final mission in localMissions) {
        try {
          await _missionsCol!.doc(mission.id).set(_toFirestore(mission));
          debugPrint('  ✅ Migrated: "${mission.title}" (${mission.id})');
        } catch (e) {
          debugPrint('  ❌ Failed to migrate: "${mission.title}" error=$e');
        }
      }
      debugPrint('☁️ MissionRepository: Migration complete');
    } catch (e) {
      debugPrint(
        '⚠️ MissionRepository: Migration check failed (offline?). error=$e',
      );
    }
  }

  /// Firestoreのリアルタイムストリーム（全ミッション）
  /// 他デバイスでの変更が即座にこのストリームに流れる
  /// データが流れるたびにHiveキャッシュも更新する
  Stream<List<Mission>> get allMissionsStream {
    if (_missionsCol == null) {
      // ゲスト（Hiveのみ）: 現在値を流した後、Hiveの変更を監視して流し続ける
      return _watchLocalMissions();
    }
    return _missionsCol!.snapshots().map((snapshot) {
      final missions = snapshot.docs
          .map((doc) => _fromFirestore(doc.data()! as Map<String, dynamic>))
          .toList();
      // Hiveキャッシュを更新（非同期で実行）
      _updateHiveCache(missions);
      debugPrint(
        '🔴 MissionRepository: Realtime update. ${missions.length} missions',
      );
      return missions;
    });
  }

  Stream<List<Mission>> _watchLocalMissions() async* {
    yield _box?.values.toList() ?? [];
    final box = _box;
    if (box == null) return;
    yield* box.watch().map((_) => box.values.toList());
  }

  /// HiveキャッシュをFirestoreストリームのデータで更新する
  /// Firestoreが空の場合はローカルデータを削除しない（安全策）
  Future<void> _updateHiveCache(List<Mission> missions) async {
    if (_box == null) return;
    if (missions.isEmpty) {
      // Firestoreが空の場合、ローカルデータを破壊しない
      debugPrint(
        '⚠️ MissionRepository: Firestore returned 0 missions. Keeping local data intact.',
      );
      return;
    }
    // Firestoreにないミッションをローカルから削除
    final newIds = missions.map((m) => m.id).toSet();
    final keysToDelete = _box!.keys.where((k) => !newIds.contains(k)).toList();
    for (final key in keysToDelete) {
      await _box!.delete(key);
    }
    // 追加・更新
    for (final m in missions) {
      await _box!.put(m.id, m);
    }
  }

  /// Mission → Firestore用Map（DateTime を Timestamp に、Task を Map に変換）
  Map<String, dynamic> _toFirestore(Mission mission) {
    final json = mission.toJson();
    // tasks を明示的に Map に変換（explicitToJson 未設定対策）
    json['tasks'] = mission.tasks.map((t) => t.toJson()).toList();
    json['createdAt'] = Timestamp.fromDate(mission.createdAt);
    if (mission.completedAt != null) {
      json['completedAt'] = Timestamp.fromDate(mission.completedAt!);
    }
    return json;
  }

  /// Firestoreのデータ → Mission（Timestamp を DateTime に変換）
  Mission _fromFirestore(Map<String, dynamic> data) {
    final json = Map<String, dynamic>.from(data);
    if (json['createdAt'] is Timestamp) {
      json['createdAt'] = (json['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    if (json['completedAt'] is Timestamp) {
      json['completedAt'] = (json['completedAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return Mission.fromJson(json);
  }

  // 全ミッション取得
  List<Mission> getAllMissions() {
    return _box?.values.toList() ?? [];
  }

  // アクティブなミッション取得（未完了のみ）
  List<Mission> getActiveMissions() {
    debugPrint('📖 MissionRepository: _box is null? ${_box == null}');
    debugPrint(
      '📖 MissionRepository: Reading missions from box (total: ${_box?.length ?? 0})',
    );
    if (_box != null) {
      debugPrint('📖 MissionRepository: Box keys: ${_box!.keys.toList()}');
    }
    final missions =
        _box?.values.where((mission) => mission.completedAt == null).toList() ??
        [];
    debugPrint(
      '📖 MissionRepository: Found ${missions.length} active missions',
    );
    return missions;
  }

  // 完了済みミッション取得（新しい順）
  List<Mission> getCompletedMissions() {
    final missions =
        _box?.values.where((mission) => mission.completedAt != null).toList() ??
        [];
    missions.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return missions;
  }

  // ミッション追加（Hive + Firestore に同時書き込み）
  Future<void> addMission(Mission mission) async {
    debugPrint(
      '💾 MissionRepository: Saving mission "${mission.title}" (ID: ${mission.id})',
    );
    if (_box == null) {
      debugPrint('❌ MissionRepository: Box is null! Reinitializing...');
      await init();
    }
    await _box?.put(mission.id, mission);
    debugPrint(
      '💾 MissionRepository: Box now has ${_box?.length ?? 0} missions',
    );
    try {
      await _missionsCol?.doc(mission.id).set(_toFirestore(mission));
      debugPrint('☁️ MissionRepository: Mission added to Firestore.');
    } catch (e) {
      debugPrint(
        '⚠️ MissionRepository: Failed to add to Firestore (offline?). error=$e',
      );
    }
  }

  // ミッション更新（Hive + Firestore に同時書き込み）
  Future<void> updateMission(Mission mission) async {
    await _box?.put(mission.id, mission);
    try {
      await _missionsCol?.doc(mission.id).set(_toFirestore(mission));
      debugPrint('☁️ MissionRepository: Mission updated in Firestore.');
    } catch (e) {
      debugPrint(
        '⚠️ MissionRepository: Failed to update Firestore (offline?). error=$e',
      );
    }
  }

  // ミッション削除（Hive + Firestore から同時削除）
  Future<void> deleteMission(String id) async {
    await _box?.delete(id);
    try {
      await _missionsCol?.doc(id).delete();
      debugPrint('☁️ MissionRepository: Mission deleted from Firestore.');
    } catch (e) {
      debugPrint(
        '⚠️ MissionRepository: Failed to delete from Firestore (offline?). error=$e',
      );
    }
  }

  // 全ミッション削除（Hive + Firestore）
  Future<void> deleteAllMissions() async {
    await _box?.clear();
    final col = _missionsCol;
    if (col == null) return;
    try {
      final snapshot = await col.get();
      // WriteBatch は1回500件までのため分割して削除
      for (var i = 0; i < snapshot.docs.length; i += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      debugPrint(
        '☁️ MissionRepository: Deleted ${snapshot.docs.length} missions from Firestore.',
      );
    } catch (e) {
      debugPrint(
        '⚠️ MissionRepository: Failed to delete all from Firestore. error=$e',
      );
      rethrow;
    }
  }

  // 特定のミッション取得
  Mission? getMissionById(String id) {
    return _box?.get(id);
  }
}

// Riverpod Provider
// StateProvider: ログイン後にUID付きインスタンスで上書きされる
final missionRepositoryProvider = StateProvider<MissionRepository>((ref) {
  return MissionRepository();
});

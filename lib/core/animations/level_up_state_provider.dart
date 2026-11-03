import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// レベルアップモーダルの状態を管理するProvider
/// モーダルが閉じられた後にプログレスバーをリセットするトリガーとして使用
class LevelUpState {
  final bool isModalOpen;
  final bool modalJustClosed; // モーダルが閉じられた直後フラグ（1回のみ使用）
  final int? completedLevel; // 完了したレベル（リセットトリガー用）
  final int? displayLevel; // 実際に表示するレベル（モーダル表示中は旧レベル保持）
  final int? pendingLevel; // モーダル表示待ちの新レベル
  final double? progressBeforeLevelUp; // レベルアップ前のプログレス値
  final DateTime timestamp; // 状態更新のタイムスタンプ

  LevelUpState({
    required this.isModalOpen,
    this.modalJustClosed = false,
    this.completedLevel,
    this.displayLevel,
    this.pendingLevel,
    this.progressBeforeLevelUp,
    required this.timestamp,
  });

  LevelUpState copyWith({
    bool? isModalOpen,
    bool? modalJustClosed,
    int? completedLevel,
    int? displayLevel,
    int? pendingLevel,
    double? progressBeforeLevelUp,
    DateTime? timestamp,
  }) {
    return LevelUpState(
      isModalOpen: isModalOpen ?? this.isModalOpen,
      modalJustClosed: modalJustClosed ?? this.modalJustClosed,
      completedLevel: completedLevel ?? this.completedLevel,
      displayLevel: displayLevel ?? this.displayLevel,
      pendingLevel: pendingLevel ?? this.pendingLevel,
      progressBeforeLevelUp:
          progressBeforeLevelUp ?? this.progressBeforeLevelUp,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class LevelUpStateNotifier extends StateNotifier<LevelUpState> {
  LevelUpStateNotifier()
    : super(LevelUpState(isModalOpen: false, timestamp: DateTime.now()));

  /// 状態を初期化する（データ削除後に旧レベル表示などが残らないようにする）
  void reset() {
    state = LevelUpState(isModalOpen: false, timestamp: DateTime.now());
  }

  /// レベルアップモーダルを開く
  /// oldLevel: モーダル表示中に表示し続ける旧レベル
  /// newLevel: モーダル終了後に表示する新レベル
  void openModal(int oldLevel, int newLevel, double progressBeforeLevelUp) {
    debugPrint(
      '🎯 LevelUpState: openModal called - oldLevel: $oldLevel, newLevel: $newLevel, progressBefore: ${progressBeforeLevelUp.toStringAsFixed(3)}',
    );
    state = LevelUpState(
      isModalOpen: true,
      modalJustClosed: false,
      completedLevel: null,
      displayLevel: oldLevel, // モーダル表示中は旧レベルを表示
      pendingLevel: newLevel, // 新レベルは保留
      progressBeforeLevelUp: progressBeforeLevelUp,
      timestamp: DateTime.now(),
    );
    debugPrint(
      '🎯 LevelUpState: State after openModal - isModalOpen: ${state.isModalOpen}, modalJustClosed: ${state.modalJustClosed}',
    );
  }

  /// レベルアップモーダルを閉じる（プログレスバーリセットのトリガー）
  void closeModal(int completedLevel) {
    debugPrint(
      '🎯 LevelUpState: closeModal called - completedLevel: $completedLevel',
    );
    state = LevelUpState(
      isModalOpen: false,
      modalJustClosed: true, // 閉じた直後フラグを立てる
      completedLevel: completedLevel,
      displayLevel: completedLevel, // 新レベルを表示
      pendingLevel: null,
      progressBeforeLevelUp: state.progressBeforeLevelUp,
      timestamp: DateTime.now(),
    );
    debugPrint(
      '🎯 LevelUpState: State after closeModal - isModalOpen: ${state.isModalOpen}, modalJustClosed: ${state.modalJustClosed}',
    );
  }

  /// modalJustClosedフラグをクリア（プログレスバーリセット完了後に呼ぶ）
  void clearClosedFlag() {
    debugPrint(
      '🎯 LevelUpState: clearClosedFlag called - modalJustClosed was: ${state.modalJustClosed}',
    );
    if (state.modalJustClosed) {
      // 演出終了後は displayLevel を解除し、常に実データのレベルを表示させる
      state = LevelUpState(
        isModalOpen: state.isModalOpen,
        modalJustClosed: false,
        completedLevel: state.completedLevel,
        displayLevel: null,
        pendingLevel: state.pendingLevel,
        progressBeforeLevelUp: state.progressBeforeLevelUp,
        timestamp: DateTime.now(),
      );
      debugPrint(
        '🎯 LevelUpState: State after clearClosedFlag - modalJustClosed: ${state.modalJustClosed}',
      );
    } else {
      debugPrint(
        '🎯 LevelUpState: modalJustClosed was already false, no change',
      );
    }
  }
}

final levelUpStateProvider =
    StateNotifierProvider<LevelUpStateNotifier, LevelUpState>(
      (ref) => LevelUpStateNotifier(),
    );

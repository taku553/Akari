# レベルアップアプリ - 要件定義（完全版）

## 概要

### プロジェクトの背景と目的

誰しも自分の中で夢を叶えたり目標を達成したいと考えている。でも個人の意思だけでは自分を律することは難しい。夢や目標を達成するには毎日の小さな積み重ねが必要で、それを達成するには意思だけに頼らない目標達成の仕組みが重要。じゃあどんな仕組みなら作ればいいか。可能性があるのはレベルアップシステム。rpgをはじめとするゲームにはゲーム内キャラクターにレベルの概念を与えてそれぞれを強化していくという仕組みがある。これがあると、自分が所有しているキャラが今どのくらいの強さなのか、さらに強くなるためにどのくらいの経験値が必要なのか、あるキャラは他のキャラと比べてどの位置にいるか、これまでにどれだけこのキャラを使い込みとのみ試練を乗り越えてきたか。それらがレベルによって数値で見て取れることでキャラの存在を自分事として捉えつつ、今何が必要かを客観的な尺度で把握することができる。ゲームの世界で多用されているこのレベルの概念を現実の自分自身に対して使えば、自分を一人のゲームキャラに見立てレベルアップシステムを駆使しながら夢や目標を達成できると考えた。このレベルアップシステムを最も身近に感じれるように、ほとんどの人にとって今や必須のツールであるスマホの中にアプリとして提供する。

### 解決したい課題

- タスク先延ばし
- 夢・目標喪失
- 自身が本来持っている異能の失念
- 自身に今最も必要な事柄の喪失

### 期待される効果

- 先延ばしの解消
- 夢・目標に対する意識の保持
- 異能の理解と自身の立ち位置の把握
- 小さなタスク達成による報酬の実感と達成の継続
- 自身に今最も必要な事柄と不要な事柄の把握

### プロジェクトのスコープ（範囲）

【含まれるもの】

- 個人向け習慣化サポートアプリ(iOS/Android)
- オフライン対応のタスク管理機能
- レベルアップシステムによるゲーミフィケーション
- 単一ユーザーでの利用(マルチユーザー対応なし)
- リマインダー通知機能

【含まれないもの】

- チームやグループでの共有機能
- SNS的なソーシャル機能(共有ボタンは除く)
- Apple WatchやAndroid Wearへの対応
- 有料課金機能(初期バージョンでは無料提供)

【ターゲットユーザー】

- 20-40代の自己成長に関心がある個人
- ゲーム要素を楽しめる層
- 継続的な習慣形成に課題を感じている人

---

## 機能定義

- ミッション作成(名前、目的、タスクリスト)
- タスク完了チェック
- データの永続化
- 経験値の計算と蓄積
- レベル判定ロジック
- レベルアップアニメーション
- 現在レベルと経験値の表示
- アクティブミッション一覧
- 円形プログレスバー
- ローカルストレージへの保存
- アプリ再起動時のデータ復元

### ミッション＆タスク作成処理

1. ミッション作成アイコンをタップし入力フォームへミッション名を入力
2. ミッション名を決めたらそこに含めるタスクを追加していく。最低1個、最大10個
3. タスクを必要な分追加して作成ボタンを押すと確認画面が表示されるので問題なければ作成。ミッション名やタスクに変更を加えたいときは「編集ボタン」をタップ。

### タスク完了処理

1. ユーザーがタスクのチェックボックスをタップ
2. タスクの状態を「完了」に更新（ここで簡単なアニメーション）
3. 該当タスクの獲得経験値を取得。これに加えて、ミッションそのものを達成した場合もレベルアップの対象とする。
4. 現在の経験値に加算
5. レベルアップ判定を実行
   - レベルアップ条件を満たす場合:
     a. レベルを1増加
     b. 余剰経験値を次レベルに繰り越し
     c. レベルアップアニメーションを表示
   - 満たさない場合:
     a. プログレスバーとアニメーションのみ表示
6. ミッション内の全タスク完了状態を確認
7. データベースに保存
8. UI更新

---

## 非機能定義

### 性能要件

- 画面遷移: 300ms以内
- データ読み込み: 1秒以内
- アニメーション: 60fps維持

### 対応環境

- iOS: iOS 14.0以上
- Android: Android 8.0 (API level 26)以上
- 画面サイズ: 5〜7インチ(タブレット対応は将来検討。ただしtailwindcssを使ってタブレットに対応したスタイルシートのテンプレートがあるならそれを実装して初期から対応させてしまいたい。)

### データ・ストレージ

- アプリサイズ: 50MB以下
- ローカルストレージ使用量: 100MB以下
- データバックアップ: ユーザーの端末内で完結

### セキュリティ

- ローカルデータの暗号化(将来的にFirebase連携時に検討)
- アプリ内課金を行わないため、決済関連のセキュリティは不要

### 可用性

- オフライン動作: 必須(ネットワーク不要)
- データ損失防止: アプリクラッシュ時も直前の状態を保持

### 保守性

- コードの可読性とメンテナンス性を重視
- 将来的な機能追加に対応できる設計

### アクセシビリティ

- 文字サイズの変更対応
- カラーコントラスト比4.5:1以上(WCAG 2.1 AA準拠)

### 多言語対応

- 日本語・英語の2言語

---

## 技術アーキテクチャ

### 現在のプロジェクト構造（2026年2月時点）

**Feature-First + Layer分離アーキテクチャ**を採用

```
lib/
├── main.dart
├── core/
│   ├── animations/              # アニメーション専用レイヤー
│   │   ├── animation_coordinator.dart       # アニメーションキュー管理
│   │   ├── animation_providers.dart         # アニメーション用Provider
│   │   ├── animation_types.dart             # アニメーション型定義
│   │   ├── level_up_overlay.dart            # レベルアップオーバーレイUI
│   │   ├── level_up_state_provider.dart     # レベルアップ状態管理
│   │   └── progress_animation_controller.dart # プログレスバーアニメーション
│   ├── providers/               # 共通Provider（未実装）
│   ├── router/                  # ルーティング
│   │   └── app_router.dart              # go_routerによるルート定義
│   ├── storage/                 # データ永続化（未実装）
│   ├── theme/                   # デザインシステム
│   │   └── app_colors.dart              # カラーパレット定義
│   └── widgets/                 # 共通ウィジェット
│       └── bottom_navigation_bar.dart   # ボトムナビゲーション
├── features/
│   ├── home/                    # ホーム画面機能
│   │   ├── data/
│   │   │   └── user_stats_repository.dart   # ユーザー統計データリポジトリ
│   │   ├── domain/
│   │   │   ├── user_stats.dart              # ユーザー統計モデル
│   │   │   ├── user_stats.freezed.dart      # Freezed生成ファイル
│   │   │   └── user_stats.g.dart            # JSON生成ファイル
│   │   ├── presentation/
│   │   │   └── home_screen.dart             # ホーム画面
│   │   ├── providers/
│   │   │   ├── exp_progress_controller_provider.dart  # 経験値アニメーション制御
│   │   │   └── user_stats_provider.dart     # ユーザー統計Provider
│   │   └── widgets/
│   │       ├── exp_progress_widget.dart     # 経験値プログレスバー
│   │       ├── level_display_widget.dart    # レベル表示
│   │       └── mission_list_widget.dart     # ミッション一覧
│   ├── mission/                 # ミッション管理機能
│   │   ├── data/
│   │   │   └── mission_repository.dart      # ミッションデータリポジトリ
│   │   ├── domain/
│   │   │   ├── mission.dart                 # ミッションモデル
│   │   │   ├── mission.freezed.dart         # Freezed生成ファイル
│   │   │   ├── mission.g.dart               # JSON生成ファイル
│   │   │   ├── task.dart                    # タスクモデル
│   │   │   ├── task.freezed.dart            # Freezed生成ファイル
│   │   │   └── task.g.dart                  # JSON生成ファイル
│   │   ├── presentation/
│   │   │   ├── mission_confirmation_screen.dart  # ミッション確認画面
│   │   │   ├── mission_created_screen.dart       # ミッション作成完了画面
│   │   │   ├── mission_creation_screen.dart      # ミッション作成画面
│   │   │   ├── mission_edit_screen.dart          # ミッション編集画面
│   │   │   └── missions_screen.dart              # ミッション一覧画面
│   │   ├── providers/
│   │   │   ├── mission_provider.dart        # ミッションProvider
│   │   │   └── task_completion_service.dart # タスク完了処理サービス
│   │   └── widgets/
│   │       ├── mission_card_widget.dart     # ミッションカード（編集用）
│   │       ├── mission_view_card_widget.dart # ミッションカード（表示用）
│   │       ├── task_item_widget.dart        # タスクアイテム（編集用）
│   │       └── task_view_item_widget.dart   # タスクアイテム（表示用）
│   └── settings/                # 設定機能
│       └── presentation/
│           └── settings_screen.dart         # 設定画面
```

### プラットフォーム対応状況

```
├── android/         # Android設定（Gradle/Kotlin）
├── ios/             # iOS設定（Xcode/Swift）
├── macos/           # macOS設定（CocoaPods）
├── linux/           # Linux設定（CMake）
├── windows/         # Windows設定（CMake）
├── web/             # Web設定
└── assets/
    └── animations/
        └── confetti.json    # Lottieアニメーション
```

### 採用パッケージ一覧

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| flutter_riverpod | ^2.6.1 | 状態管理 |
| riverpod_annotation | ^2.3.5 | Riverpodコード生成 |
| go_router | ^17.1.0 | ルーティング |
| hive | ^2.2.3 | ローカルストレージ |
| hive_flutter | ^1.1.0 | Hive Flutter統合 |
| freezed_annotation | ^2.4.4 | イミュータブルモデル |
| json_annotation | ^4.9.0 | JSON シリアライズ |
| google_fonts | ^8.0.1 | カスタムフォント |
| intl | ^0.20.2 | 国際化対応 |
| uuid | ^4.5.2 | UUID生成 |
| lottie | ^3.2.0 | Lottieアニメーション |

### 開発用パッケージ

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| build_runner | ^2.4.8 | コード生成 |
| riverpod_generator | ^2.4.0 | Riverpod Provider生成 |
| hive_generator | ^2.0.1 | Hiveアダプター生成 |
| freezed | ^2.4.7 | Freezedコード生成 |
| json_serializable | ^6.7.1 | JSON生成 |

### 状態管理

- **Riverpod**を採用
- アニメーションと状態の疎結合を実現
- テストしやすい設計
- コード生成（riverpod_generator）による型安全な実装

### データ永続化

- **Hive**を採用
- オフライン対応
- 高速なデータアクセス
- 軽量なパッケージサイズ
- Freezedによるイミュータブルなモデル定義

---

## アニメーション管理設計

### 重要な設計原則

**アニメーションの競合防止とシーケンス制御が最重要課題**

### 推奨コンポーネント

#### 1. AnimationCoordinator（アニメーション調整役）

複数のアニメーションをキューイングし、順序通りに実行する中央管理システム。以下の機能を持つ：
- アニメーションタスクのキュー管理
- 優先度の高いアニメーション（レベルアップなど）の割り込み処理
- 実行中のアニメーション状態の追跡

#### 2. LevelUpAnimationController（レベルアップシーケンス）

レベルアップ時の一連のアニメーションを制御。以下のシーケンスを管理：
- オーバーレイフェードイン
- スロットマシン風の数字遷移アニメーション
- 10の倍数レベル時のコンフェッティ表示（htmlプロトタイプにあるlottiefilesアニメーションを使用）
- タップによる即座のスキップ機能

#### 3. ProgressAnimationController（プログレスバー）

円形プログレスバーのアニメーション制御：
- Cubic Bezier イージングによる滑らかな進行
- タスク完了時のパルスアニメーション
- 経験値獲得時の視覚的フィードバック

#### 4. ConfettiController（コンフェッティ演出）

マイルストーン達成時の祝福演出：
- Lottieアニメーションの再生制御
- 表示/非表示のタイミング管理
- パフォーマンスへの影響を最小化

---

## 開発の優先順位

### Phase 1: コア機能（2-3週間）

**MVP機能の実装**

- ミッション作成・編集
- タスク完了チェック
- 経験値計算・レベルアップロジック
- ローカルストレージ（Hive）
- 基本的なUIアニメーション

### Phase 2: アニメーション磨き込み（2週間）

**ユーザー体験の向上**

- AnimationCoordinator実装
- レベルアップシーケンス完成
- プログレスバーアニメーション
- コンフェッティ（Lottieまたはカスタム）
- タップフィードバック

### Phase 3: 通知システム（1-2週間）

**習慣化サポート機能**

- flutter_local_notifications統合
- WorkManager/AlarmManagerによるバックグラウンド実行
- リマインダースケジューリング
- 励ましメッセージシステム

### Phase 4: 仕上げ（1週間）

**リリース準備**

- 設定画面
- データエクスポート
- 多言語対応（日本語・英語）
- アプリアイコン・スプラッシュ画面

---

## Flutter環境セットアップ

### 必要なツール

```bash
# Flutter SDK インストール確認
flutter doctor

# 新規プロジェクト作成
flutter create akari
cd akari

# 必須パッケージの追加
flutter pub add riverpod flutter_riverpod
flutter pub add hive hive_flutter
flutter pub add flutter_local_notifications
flutter pub add workmanager
flutter pub add lottie
flutter pub add sentry_flutter

# 開発用パッケージ
flutter pub add --dev build_runner
flutter pub add --dev hive_generator
```

### 推奨開発環境

- **IDE**: Android Studio または VS Code
- **Flutter SDK**: 3.16.0以上
- **Dart SDK**: 3.2.0以上

---

## 開発・テスト・リリース手順

### iOS開発（Macのみ、iPhone実機なし）

#### コーディング

1. **VS Code / Android Studioでコード作成**
2. **Mac上で直接実行**

```bash
# iOSシミュレーターで起動
flutter run -d "iPhone 15 Pro Simulator"
```

#### シミュレーション・テスト

1. **Xcodeシミュレーターで動作確認**
   - UI/UXのテスト
   - アニメーションの確認
   - 基本機能のテスト

2. **Phase 1-3: シミュレーターのみで開発完了**
   - レイアウト、アニメーション、ロジックはすべて検証可能

3. **Phase 3（通知）: TestFlight準備**
   - Apple Developer Program登録（年間12,980円）
   - App Store Connectでアプリ登録
   - TestFlightにビルドアップロード
   - 友人・家族にベータテスター依頼

#### リリース

1. **App Store Connectで申請準備**
   - スクリーンショット作成（シミュレーターから取得可能）
   - アプリ説明文・キーワード設定
   - プライバシーポリシー準備

2. **TestFlightで最終確認**（1-2週間）
   - 実機テスター5-10人で通知動作確認
   - クラッシュレポート収集

3. **App Store審査提出**
   - 平均審査期間: 1-3日

### Android開発（Pixel/Motorola実機）

#### コーディング

1. **VS Code / Android Studioでコード作成**
2. **実機接続でライブデバッグ**

```bash
# USB接続した実機で起動
flutter run
```

#### シミュレーション・テスト

1. **実機で常時テスト**
   - 通知機能も実機で即座に確認可能
   - パフォーマンス測定が正確

2. **エミュレーターも併用**

```bash
# Android Emulatorで起動
flutter run -d emulator-5554
```

#### リリース

1. **Google Play Console準備**
   - デベロッパーアカウント登録（初回25ドル買い切り）
   - アプリ情報・スクリーンショット登録

2. **リリースビルド作成**

```bash
# APK/AABファイル生成
flutter build appbundle
```

3. **内部テスト配布**（1週間）
   - Google Play Consoleの内部テスト機能使用
   - 自分の実機で最終確認

4. **本番リリース**
   - 審査期間: 数時間〜2日程度

### クロスプラットフォーム開発フロー

```
コーディング
  ↓
Androidで実機テスト（通知含む全機能）
  ↓
iOSシミュレーターで動作確認
  ↓
Phase 3完了後にTestFlightでiOS実機テスト
  ↓
両プラットフォーム同時リリース
```

---

## 習慣化アプリ特有の重要概念

### 1. ユーザーリテンション率の追跡 🔴 最重要

**概要**: 習慣化アプリの成功指標は長期利用率

**目標値**:
- Day 1: 60-70%
- Day 7: 30-40%
- Day 30: 15-25%

**実装コンポーネント**:
- RetentionTracker: 初回起動日記録、DAU（Daily Active Users）追跡
- 離脱ポイント特定のための画面滞在時間測定

**優先度**: MVP（Phase 1）

### 2. ストリーク（連続達成日数）機能 🔴 最重要

**概要**: ユーザーがアプリを開き続ける最大のモチベーション

**実装コンポーネント**:
- StreakManager: 連続達成日数の計算ロジック
- StreakRiskNotifier: 連続記録喪失リスクの通知（残り4時間など）
- StreakBadge: UI上での視覚的なストリーク表示

**優先度**: MVP（Phase 1）

### 3. エラー追跡とクラッシュ解析 🔴 最重要

**概要**: リリース後の予期せぬクラッシュを自動収集

**実装コンポーネント**:
- Sentry統合: 例外とスタックトレースの自動送信
- エラーコンテキスト記録: ユーザー操作履歴、デバイス情報

**優先度**: MVP（Phase 1）

### 4. オンボーディング体験 🟡 重要

**概要**: 初回起動3分以内に価値を感じさせる

**設計原則**:
- 説明は最小限（10秒）
- すぐに実際の操作をさせる（1分）
- 達成体験を即座に提供（1分）

**実装コンポーネント**:
- OnboardingFlow: 3ステップガイド
- SampleMissionCreator: 体験用のサンプルミッション自動生成

**優先度**: MVP（Phase 1）

### 5. Intelligent Notification（賢い通知）🟡 重要

**概要**: 通知疲れを防ぎ、ユーザーが反応しやすい通知を実現

**実装コンポーネント**:
- BestTimeCalculator: ユーザーの起動履歴から最適な通知時間を学習
- FrequencyAdjuster: 無視された通知が続いたら頻度を自動調整
- ContextualMessageGenerator: 達成率に応じたメッセージ生成
- QuietHoursManager: 深夜時間帯の通知抑制

**優先度**: v1.1（リリース後1ヶ月）

### 6. データバックアップとマイグレーション 🟡 重要

**概要**: ユーザーの努力を守る信頼性の要

**実装コンポーネント**:
- AutoBackupScheduler: 毎日の自動バックアップ
- CloudBackupManager: Firebase Storage等へのクラウド同期（Phase 2以降）
- DataMigration: バージョンアップ時のデータ構造変換

**優先度**: MVP（Phase 1）でローカルバックアップ、v1.2でクラウド対応

### 7. アナリティクス実装 🟡 重要

**概要**: 改善の羅針盤となるデータ収集

**測定すべき指標**:
- 機能の使用頻度
- レベルアップ達成率と所要時間
- ミッション完了率
- 離脱ポイント（3秒未満で去った画面）

**実装コンポーネント**:
- AnalyticsService: Firebase Analytics統合
- FeatureUsageTracker: 各機能の利用状況追跡
- LevelProgressTracker: レベリング速度の測定

**優先度**: MVP（Phase 1）

### 8. アプリストア最適化（ASO）🟢 推奨

**概要**: ダウンロード数を増やすための準備

**リリース前準備物**:
- スクリーンショット戦略（レベルアップ画面など）
- 説明文最適化（「レベルアップで習慣が続く」）
- キーワード選定（習慣化、目標達成、レベルアップ）
- レビュー促進機能（レベル10到達時）

**実装コンポーネント**:
- ReviewRequester: 適切なタイミングでレビュー依頼

**優先度**: リリース前（Phase 4）

### 9. パフォーマンス最適化 🟢 推奨

**概要**: アニメーションの60fps維持

**実装コンポーネント**:
- PerformanceMonitor: アニメーションフレームレート測定
- IsolateComputing: 重い計算処理のバックグラウンド実行
- WidgetOptimization: 不要な再描画の防止

**優先度**: Phase 2（アニメーション実装時）

### 10. プライバシー対応 🟢 推奨

**概要**: iOS ATT、GDPR等の法規制対応

**実装コンポーネント**:
- TrackingPermissionRequester: iOS App Tracking Transparency対応
- GDPRCompliance: データ削除・エクスポート機能
- PrivacyPolicyManager: プライバシーポリシー表示

**優先度**: リリース前（Phase 4）

### 11. CI/CDパイプライン 🟢 推奨

**概要**: ビルド・テストの自動化で効率化

**実装コンポーネント**:
- GitHub Actions: 自動ビルド・テスト
- Automated Testing: Widget/Integration/Unit テスト

**優先度**: 開発中期（Phase 2-3）

---

## アクセシビリティ対応

### 実装必須項目

- **Semanticsウィジェット**: スクリーンリーダー対応
- **カラーコントラスト**: WCAG 2.1 AA基準（4.5:1以上）準拠
- **タップターゲットサイズ**: 最小44x44ポイント
- **フォントスケーリング**: システム設定に応じた文字サイズ変更

---

## リリース後のロードマップ

### v1.0（初回リリース）

- コア機能一式
- iOS/Android同時リリース

### v1.1（リリース後1ヶ月）

- 賢い通知スケジューリング
- レビュー依頼機能
- データエクスポート
- パフォーマンス最適化

### v1.2（リリース後3ヶ月）

- クラウドバックアップ
- ダークモード
- ウィジェット対応（ホーム画面）

### v2.0（将来展望）

- Apple Watch/Android Wear対応
- ソーシャル機能（任意）
- プレミアム機能（検討中）

---

## まとめ

本アプリケーションの成功には以下3点が最重要：

1. **アニメーションの品質**: AnimationCoordinatorによる競合制御と滑らかな60fps維持
2. **通知の最適化**: ユーザーを疲れさせない賢い通知システム
3. **データの信頼性**: ユーザーの努力を守るバックアップとエラー追跡

これらを確実に実装し、ユーザーが習慣化に成功する体験を提供する。

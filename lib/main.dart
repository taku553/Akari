import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/login_screen.dart';
import 'core/utils/app_reload.dart';

import 'core/router/app_router.dart';
import 'features/mission/domain/task.dart';
import 'features/mission/domain/mission.dart';
import 'features/home/domain/user_stats.dart';
import 'features/home/providers/user_stats_provider.dart';
import 'features/mission/data/mission_repository.dart';
import 'features/home/data/user_stats_repository.dart';
import 'features/settings/providers/user_settings_provider.dart';

void main() {
  // Flutterエンジンの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase/Hive等の非同期初期化はrunApp後に行う。
  // これにより初回フレームがすぐ描画され、Web版で初期化中も「真っ白な画面」にならない。
  runApp(const ProviderScope(child: _BootstrapApp()));
}

Future<void> _initCore() async {
  // Firebaseの初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hive (ローカルDB) の初期化
  await Hive.initFlutter();

  // Hive Adapterの登録
  Hive.registerAdapter(TaskImplAdapter()); // typeId: 0
  Hive.registerAdapter(MissionImplAdapter()); // typeId: 1
  Hive.registerAdapter(UserStatsImplAdapter()); // typeId: 2

  // 日付フォーマットの日本語化
  await initializeDateFormatting('ja_JP');
}

/// Firebase/Hive初期化が終わるまでの起動画面。
/// 初期化に時間がかかる場合（Web版でネットワークが不安定な場合など）は
/// 再読み込みボタンを出し、固まったまま戻れなくなるのを防ぐ。
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCore();
  }

  void _retry() {
    setState(() {
      _initFuture = _initCore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF87171),
          primary: const Color(0xFFF87171),
        ),
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
      ),
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadingWithReload(
              message: '起動処理に失敗しました',
              onRetry: _retry,
              showRetryImmediately: true,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingWithReload(message: '準備中です...', onRetry: _retry);
          }
          return const MissionLevelerApp();
        },
      ),
    );
  }
}

/// 一定時間経っても完了しない場合に再読み込みボタンを表示するローディング画面
class _LoadingWithReload extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final bool showRetryImmediately;

  const _LoadingWithReload({
    required this.message,
    required this.onRetry,
    this.showRetryImmediately = false,
  });

  @override
  State<_LoadingWithReload> createState() => _LoadingWithReloadState();
}

class _LoadingWithReloadState extends State<_LoadingWithReload> {
  bool _showRetry = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _showRetry = widget.showRetryImmediately;
    if (!_showRetry) {
      _timer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showRetry = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleRetry() {
    // Web: 固まったJS側の状態ごとリセットするため、確実性の高いページリロードを優先する
    reloadApp();
    // ネイティブ環境などreloadAppが効かない場合はDart側で再試行する
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/images/akari_mark.svg', width: 96),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(widget.message),
            if (_showRetry) ...[
              const SizedBox(height: 24),
              const Text(
                '読み込みに時間がかかっています',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _handleRetry, child: const Text('再読み込み')),
            ],
          ],
        ),
      ),
    );
  }
}

class MissionLevelerApp extends ConsumerWidget {
  const MissionLevelerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Mission Leveler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF87171),
          primary: const Color(0xFFF87171),
        ),
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
      ),
      home: authState.when(
        data: (user) {
          if (user == null) {
            // 未ログイン → ログイン画面
            return const LoginScreen();
          }
          // ログイン済み → メインアプリ（UID付きでRepository初期化）
          return _AuthenticatedApp(uid: user.uid);
        },
        loading: () =>
            _LoadingWithReload(message: '認証状態を確認しています...', onRetry: () {}),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}

/// ログイン後のメインアプリ
/// UIDが確定してからRepositoryを初期化し、GoRouterで画面遷移する
class _AuthenticatedApp extends ConsumerStatefulWidget {
  final String uid;
  const _AuthenticatedApp({required this.uid});

  @override
  ConsumerState<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends ConsumerState<_AuthenticatedApp> {
  late final GoRouter _router;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initRepositories();
  }

  Future<void> _initRepositories() async {
    debugPrint('🚀 App: Initializing repositories for uid=${widget.uid}');

    final missionRepo = MissionRepository(uid: widget.uid);
    final userStatsRepo = UserStatsRepository(uid: widget.uid);

    await missionRepo.init();
    await userStatsRepo.init();
    // タスク追加画面を開いた瞬間にデフォルト経験値が未読込みで250にフォールバックしないよう、ここで先読みしておく
    await ref.read(userSettingsNotifierProvider.future);

    debugPrint('🚀 App: Repositories initialized successfully');

    // デバッグ用：起動時のステータス操作フラグ
    const bool resetStats = bool.fromEnvironment(
      'RESET_STATS',
      defaultValue: false,
    );
    const bool forceLevel9 = bool.fromEnvironment(
      'FORCE_LEVEL_9',
      defaultValue: false,
    );
    if (resetStats) {
      debugPrint('🔄 DEBUG: Resetting stats to level 1');
      const initialStats = UserStats(
        level: 1,
        currentExp: 0,
        nextLevelExp: 100,
      );
      await userStatsRepo.saveStats(initialStats);
    } else if (forceLevel9) {
      debugPrint('🎮 DEBUG: Setting level to 9');
      const testStats = UserStats(level: 9, currentExp: 0, nextLevelExp: 500);
      await userStatsRepo.saveStats(testStats);
    }

    if (mounted) {
      // Providerを上書きしてからGoRouterを生成
      ref.read(missionRepositoryProvider.notifier).state = missionRepo;
      ref.read(userStatsRepositoryProvider.notifier).state = userStatsRepo;
      // ユーザー切替時に古いキャッシュが残らないよう、statsProviderを再作成
      ref.invalidate(userStatsProvider);
      _router = ref.read(appRouterProvider);
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return _LoadingWithReload(
        message: 'データを読み込んでいます...',
        onRetry: () {
          setState(() {
            _initRepositories();
          });
        },
      );
    }

    return MaterialApp.router(
      title: 'Mission Leveler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF87171),
          primary: const Color(0xFFF87171),
        ),
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
      ),
      routerConfig: _router,
    );
  }
}

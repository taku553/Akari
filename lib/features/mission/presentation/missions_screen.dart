import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/max_width_container.dart';
import '../widgets/mission_view_card_widget.dart';
import '../providers/mission_provider.dart';
import '../domain/mission.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  bool _hasNavigated = false;

  void _showDeleteConfirmationDialog(BuildContext context, Mission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ミッションを削除しますか？'),
        content: const Text('実行中のミッションが削除され、新しいミッションに上書きされますがよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'いいえ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // ミッションを削除してから作成画面へ
              await ref
                  .read(missionListProvider.notifier)
                  .deleteMission(mission.id);
              if (context.mounted) {
                context.push('/mission/create');
              }
            },
            child: Text(
              'はい',
              style: TextStyle(
                color: context.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missionsAsync = ref.watch(missionListProvider);

    // ミッションが空の場合、自動的に作成画面に遷移
    missionsAsync.whenData((missions) {
      if (missions.isEmpty && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 作成画面から戻ってきたときにミッションが存在すれば
            // フラグをリセットして再度空になった場合に対応できるようにする。
            // ※ミッションが空のままの場合はホーム画面に戻る
            context.push('/mission/create').then((_) {
              if (mounted) {
                final currentMissions = ref
                    .read(missionListProvider)
                    .valueOrNull;
                if (currentMissions != null && currentMissions.isNotEmpty) {
                  setState(() {
                    _hasNavigated = false;
                  });
                } else {
                  // ミッションを作成せずに戻ってきた場合はホームに戻る
                  // ナビゲーションバーで go() を使っているとスタックにホームがない場合がある
                  // canPop() でチェックし、pop できなければ go() を使う
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                }
              }
            });
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'MISSIONS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: MaxWidthContainer(
        child: missionsAsync.when(
          data: (missions) {
            if (missions.isEmpty) {
              // 空の場合は作成画面に自動遷移するのでローディング表示
              return const Center(child: CircularProgressIndicator());
            }

            final mission = missions.first;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ミッションカード（読み取り専用）
                  MissionViewCardWidget(mission: mission),
                  const SizedBox(height: 16),
                  // 編集・新規作成ボタン
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/mission/edit', extra: mission);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '編集',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, mission);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.accent,
                            side: BorderSide(
                              color: context.accent,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '新規作成',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'エラーが発生しました',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

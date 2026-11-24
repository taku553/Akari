import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_palette.dart';
import '../../mission/providers/mission_provider.dart';
import '../../mission/widgets/mission_card_widget.dart';

class MissionListWidget extends ConsumerWidget {
  const MissionListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionListProvider);

    return missionsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'エラーが発生しました: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (missions) {
        if (missions.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 80,
                      color: context.palette.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ミッションがありません',
                      style: TextStyle(
                        fontSize: 18,
                        color: context.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '上の+ボタンまたは下のボタンから新しいミッションを作成',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final mission = missions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: MissionCardWidget(mission: mission),
              );
            }, childCount: missions.length),
          ),
        );
      },
    );
  }
}

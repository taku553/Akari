import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/max_width_container.dart';
import '../../home/providers/user_stats_provider.dart';
import '../../settings/providers/user_settings_provider.dart';
import '../domain/mission.dart';
import '../domain/task.dart';
import '../providers/mission_provider.dart';

class MissionEditScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const MissionEditScreen({super.key, required this.mission});

  @override
  ConsumerState<MissionEditScreen> createState() => _MissionEditScreenState();
}

class _MissionEditScreenState extends ConsumerState<MissionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _missionTitleController;
  final _taskControllers = <TextEditingController>[];
  final _expControllers = <TextEditingController>[];
  final _taskIds = <String>[];

  @override
  void initState() {
    super.initState();
    _missionTitleController = TextEditingController(text: widget.mission.title);

    // 既存のタスクをコントローラーに設定
    for (var task in widget.mission.tasks) {
      _taskControllers.add(TextEditingController(text: task.title));
      _expControllers.add(TextEditingController(text: task.exp.toString()));
      _taskIds.add(task.id);
    }
  }

  @override
  void dispose() {
    _missionTitleController.dispose();
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    for (var controller in _expControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addTaskField() async {
    final expController = TextEditingController(text: '250');
    setState(() {
      _taskControllers.add(TextEditingController());
      _expControllers.add(expController);
      _taskIds.add(''); // 新規タスクは空のIDを設定
    });

    // 設定の非同期読み込み完了を待ってから正しいデフォルトEXPを反映する
    // （起動直後は Firestore からの読み込みが完了しておらず valueOrNull が null になるため）
    final settings = await ref.read(userSettingsNotifierProvider.future);
    final userStats = ref.read(userStatsProvider).valueOrNull;
    final currentLevel = userStats?.level ?? 1;
    final defaultExp = settings.getDefaultExpForLevel(currentLevel);

    if (mounted) {
      expController.text = defaultExp.toString();
    }
  }

  void _removeTaskField(int index) {
    if (_taskControllers.length > 1) {
      setState(() {
        _taskControllers[index].dispose();
        _expControllers[index].dispose();
        _taskControllers.removeAt(index);
        _expControllers.removeAt(index);
        _taskIds.removeAt(index);
      });
    }
  }

  Future<void> _updateMission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settings = ref.read(userSettingsNotifierProvider).valueOrNull;
    final userStats = ref.read(userStatsProvider).valueOrNull;
    final currentLevel = userStats?.level ?? 1;
    final defaultExp = settings?.getDefaultExpForLevel(currentLevel) ?? 250;

    // タスクデータを収集
    final tasks = <Task>[];
    for (int i = 0; i < _taskControllers.length; i++) {
      final taskName = _taskControllers[i].text.trim();
      if (taskName.isNotEmpty) {
        final exp = int.tryParse(_expControllers[i].text) ?? defaultExp;

        // 既存のタスクか新規タスクかを判定
        final existingTask = _taskIds[i].isNotEmpty
            ? widget.mission.tasks.firstWhere((t) => t.id == _taskIds[i])
            : null;

        tasks.add(
          Task(
            id: _taskIds[i].isNotEmpty ? _taskIds[i] : const Uuid().v4(),
            title: taskName,
            exp: exp,
            isCompleted: existingTask?.isCompleted ?? false,
          ),
        );
      }
    }

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('最低1つのタスクを追加してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ミッションを更新
    final updatedMission = widget.mission.copyWith(
      title: _missionTitleController.text.trim(),
      tasks: tasks,
    );

    await ref.read(missionListProvider.notifier).updateMission(updatedMission);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ミッションを更新しました！'),
          backgroundColor: context.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundWhite,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundWhite,
        elevation: 0,
        title: Text(
          'ミッションを編集',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: MaxWidthContainer(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ミッション名入力
              Center(
                child: Text(
                  'ミッション名',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _missionTitleController,
                style: TextStyle(color: context.palette.textPrimary),
                decoration: InputDecoration(
                  hintText: '例: アルファ',
                  hintStyle: TextStyle(color: context.palette.textTertiary),
                  filled: true,
                  fillColor: context.palette.backgroundWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ミッション名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // タスクリスト
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'タスクリスト',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_taskControllers.length} / 10',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 列ヘッダー
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'タスク名',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '獲得経験値',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_taskControllers.length > 1) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '削除',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // タスク入力欄
              ...List.generate(_taskControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _taskControllers[index],
                          style: TextStyle(color: context.palette.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'タスク ${index + 1}',
                            hintStyle: TextStyle(
                              color: context.palette.textTertiary,
                            ),
                            filled: true,
                            fillColor: context.palette.backgroundWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.palette.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.palette.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.accent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _expControllers[index],
                          style: TextStyle(color: context.palette.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'EXP',
                            hintStyle: TextStyle(
                              color: context.palette.textTertiary,
                            ),
                            filled: true,
                            fillColor: context.palette.backgroundWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.palette.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.palette.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.accent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final exp = int.tryParse(value);
                              if (exp == null || exp < 1) {
                                return '無効';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_taskControllers.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.error,
                          onPressed: () => _removeTaskField(index),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              // タスク追加ボタン
              if (_taskControllers.length < 10)
                OutlinedButton.icon(
                  onPressed: _addTaskField,
                  icon: const Icon(Icons.add),
                  label: const Text('タスクを追加'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.accent,
                    side: BorderSide(color: context.accent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              // 更新ボタン
              ElevatedButton(
                onPressed: _updateMission,
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
                  '更新',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

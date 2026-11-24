import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_palette.dart';
import '../domain/user_settings.dart';
import '../providers/user_settings_provider.dart';

class DefaultExpSettingsScreen extends ConsumerStatefulWidget {
  const DefaultExpSettingsScreen({super.key});

  @override
  ConsumerState<DefaultExpSettingsScreen> createState() =>
      _DefaultExpSettingsScreenState();
}

class _DefaultExpSettingsScreenState
    extends ConsumerState<DefaultExpSettingsScreen> {
  // レベルをキー、デフォルト経験値を値として持つ一時的なマップ
  Map<String, int> _tempExpMap = {};

  @override
  void initState() {
    super.initState();
    // 初期状態で現在の設定をロードする
    final settingsAsync = ref.read(userSettingsNotifierProvider);
    settingsAsync.whenData((settings) {
      _tempExpMap = Map.from(settings.defaultTaskExpMap);
    });
  }

  void _saveSettings() {
    final notifier = ref.read(userSettingsNotifierProvider.notifier);
    notifier.updateSettings(UserSettings(defaultTaskExpMap: _tempExpMap));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('デフォルト経験値の設定を保存しました')));
    Navigator.of(context).pop();
  }

  void _showAddEditDialog({String? existingLevelStr}) {
    final levelController = TextEditingController(text: existingLevelStr ?? '');
    final expController = TextEditingController(
      text: existingLevelStr != null
          ? _tempExpMap[existingLevelStr].toString()
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingLevelStr == null ? '新しい設定を追加' : '設定を編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: levelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'レベル (例: 10)'),
                enabled:
                    existingLevelStr == null, // 編集時はレベルキーのコンフリクトを避けるため変更不可にする
              ),
              const SizedBox(height: 16),
              TextField(
                controller: expController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '経験値 (例: 800)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final level = levelController.text.trim();
                final exp = int.tryParse(expController.text.trim());
                if (level.isNotEmpty && exp != null) {
                  setState(() {
                    _tempExpMap[level] = exp;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 状態をリッスンしてローディングなどの表示を行う
    final settingsAsyncValue = ref.watch(userSettingsNotifierProvider);

    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        title: Text(
          'デフォルト経験値の設定',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        backgroundColor: context.palette.backgroundWhite,
        iconTheme: IconThemeData(color: context.palette.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSettings),
        ],
      ),
      body: settingsAsyncValue.when(
        data: (settings) {
          if (_tempExpMap.isEmpty && settings.defaultTaskExpMap.isNotEmpty) {
            _tempExpMap = Map.from(settings.defaultTaskExpMap);
          }
          final sortedKeys = _tempExpMap.keys.toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final exp = _tempExpMap[key];
              return Card(
                child: ListTile(
                  title: Text('Lv. $key 以降'),
                  subtitle: Text('タスクのデフォルトXP: $exp'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAddEditDialog(existingLevelStr: key),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _tempExpMap.remove(key);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: context.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

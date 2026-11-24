import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/max_width_container.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../domain/saved_color.dart';
import '../domain/user_settings.dart';
import '../providers/user_settings_provider.dart';

/// サブスクリプション限定のカラーパレット画面。
/// カラーピッカーまたはカラーコード(#RRGGBB)入力でアクセントカラーを選ぶ。
class ColorPaletteScreen extends ConsumerStatefulWidget {
  const ColorPaletteScreen({super.key});

  @override
  ConsumerState<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends ConsumerState<ColorPaletteScreen> {
  late Color _color;
  late final TextEditingController _hexController;
  String? _hexError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(userSettingsNotifierProvider).valueOrNull;
    _color = saved?.accentColorValue == null
        ? AppColors.primary
        : Color(saved!.accentColorValue!);
    _hexController = TextEditingController(text: colorToHex(_color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _onPickerChanged(Color color) {
    final opaque = Color(0xFF000000 | (color.toARGB32() & 0xFFFFFF));
    setState(() {
      _color = opaque;
      _hexError = null;
      // 入力中のカーソル位置が飛ばないよう、値が異なる場合のみ書き換える
      if (parseHexColor(_hexController.text) != opaque) {
        _hexController.text = colorToHex(opaque);
      }
    });
  }

  void _onHexChanged(String text) {
    final parsed = parseHexColor(text);
    setState(() {
      if (parsed == null) {
        _hexError = '#RRGGBB の形式で入力してください';
      } else {
        _hexError = null;
        _color = parsed;
      }
    });
  }

  Future<void> _save(int? accentColorValue) async {
    setState(() => _isSaving = true);
    await _updateSettings(
      (current) => current.copyWith(accentColorValue: accentColorValue),
    );
    if (mounted) context.pop();
  }

  Future<void> _updateSettings(
    UserSettings Function(UserSettings current) update,
  ) async {
    final current =
        ref.read(userSettingsNotifierProvider).valueOrNull ??
        const UserSettings();
    await ref
        .read(userSettingsNotifierProvider.notifier)
        .updateSettings(update(current));
  }

  List<SavedColor> get _savedColors =>
      ref.read(userSettingsNotifierProvider).valueOrNull?.savedColors ??
      const [];

  void _applySavedColor(SavedColor saved) {
    final color = Color(saved.colorValue);
    setState(() {
      _color = color;
      _hexError = null;
      _hexController.text = colorToHex(color);
    });
  }

  /// 現在の色に名前を付けて保存する（最大 maxSavedColors 個）
  Future<void> _saveCurrentColor() async {
    if (_savedColors.length >= maxSavedColors) {
      _showMessage('保存できる色は最大$maxSavedColors個です。不要な色を削除してください。');
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(color: _color),
    );
    if (name == null || !mounted) return;

    await _updateSettings(
      (current) => current.copyWith(
        savedColors: [
          ...current.savedColors,
          SavedColor(name: name, colorValue: _color.toARGB32()),
        ],
      ),
    );
    if (mounted) _showMessage('「$name」を保存しました');
  }

  Future<void> _deleteSavedColor(SavedColor target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存した色を削除'),
        content: Text('「${target.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _updateSettings(
      (current) => current.copyWith(
        savedColors: current.savedColors.where((c) => c != target).toList(),
      ),
    );
  }

  void _showSavedColors() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.backgroundWhite,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (_, ref, _) {
          final saved =
              ref
                  .watch(userSettingsNotifierProvider)
                  .valueOrNull
                  ?.savedColors ??
              const <SavedColor>[];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '保存した色（${saved.length}/$maxSavedColors）',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (saved.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'まだ保存した色はありません。気に入った色を選んで「この色を保存」を押すと、ここから呼び出せます。',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ),
                  for (final item in saved)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(item.colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(color: context.palette.borderDark),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(color: context.palette.textPrimary),
                      ),
                      subtitle: Text(
                        colorToHex(Color(item.colorValue)),
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                      onTap: () {
                        _applySavedColor(item);
                        Navigator.pop(sheetContext);
                      },
                      trailing: IconButton(
                        tooltip: '削除',
                        icon: Icon(
                          Icons.delete_outline,
                          color: context.palette.textSecondary,
                        ),
                        onPressed: () => _deleteSavedColor(item),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canUse = ref.watch(canUseColorPaletteProvider);
    final savedCount =
        ref
            .watch(userSettingsNotifierProvider)
            .valueOrNull
            ?.savedColors
            .length ??
        0;
    final ratio = contrastRatio(_color, context.palette.backgroundWhite);
    final contrastOk = ratio >= minAccentContrastRatio;
    final validColor = _hexError == null && contrastOk;
    final canSave = canUse && validColor && !_isSaving;

    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'カラーパレット',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: MaxWidthContainer(
        child: !canUse
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'カラーパレットは、会員登録済みのサブスクリプション契約者のみ利用できます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'ゲージやボタンなどに使われるアプリのメインカラーを変更できます。',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _save(null),
                    icon: const Icon(
                      Icons.circle,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: const Text('デフォルトの赤に戻す'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.textPrimary,
                      side: BorderSide(color: context.palette.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showSavedColors,
                          icon: const Icon(Icons.bookmarks_outlined, size: 18),
                          label: Text('保存した色を適用 ($savedCount/$maxSavedColors)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.palette.textPrimary,
                            side: BorderSide(color: context.palette.borderDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canSave ? _saveCurrentColor : null,
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 18,
                          ),
                          label: const Text('この色を保存'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.palette.textPrimary,
                            side: BorderSide(color: context.palette.borderDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ColorPicker(
                      color: _color,
                      onColorChanged: _onPickerChanged,
                      pickersEnabled: const <ColorPickerType, bool>{
                        ColorPickerType.both: false,
                        ColorPickerType.primary: false,
                        ColorPickerType.accent: false,
                        ColorPickerType.bw: false,
                        ColorPickerType.custom: false,
                        ColorPickerType.customSecondary: false,
                        ColorPickerType.wheel: true,
                      },
                      enableShadesSelection: false,
                      wheelDiameter: 220,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hexController,
                    onChanged: _onHexChanged,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[#0-9a-fA-F]'),
                      ),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: InputDecoration(
                      labelText: 'カラーコード',
                      hintText: '#F87171',
                      errorText: _hexError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContrastNotice(ratio, contrastOk),
                  const SizedBox(height: 16),
                  _buildPreview(),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: onAccentOf(_color),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: canSave ? () => _save(_color.toARGB32()) : null,
                    child: const Text('この色に変更する'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContrastNotice(double ratio, bool ok) {
    final color = ok ? AppColors.success : AppColors.error;
    final min = minAccentContrastRatio.toStringAsFixed(1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ok ? Icons.check_circle : Icons.error, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ok
                ? '背景とのコントラスト比 ${ratio.toStringAsFixed(2)}:1（見分けやすい色です）'
                : '背景とのコントラスト比が ${ratio.toStringAsFixed(2)}:1 です。'
                      '背景に溶けて見えにくくなるため、$min:1 以上になる色を選んでください。',
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'プレビュー',
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              color: _color,
              backgroundColor: accentBackgroundOf(
                _color,
                base: context.palette.backgroundWhite,
                alpha: context.isDarkTheme ? 0.22 : 0.09,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: onAccentOf(_color),
                ),
                onPressed: () {},
                child: const Text('ボタン'),
              ),
              const SizedBox(width: 12),
              Icon(Icons.check_circle, color: _color),
              const SizedBox(width: 12),
              Text(
                '選択状態',
                style: TextStyle(color: _color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 保存する色の名前を入力するダイアログ。入力された名前（空白除去済み）を返す。
class _NameDialog extends StatefulWidget {
  final Color color;
  const _NameDialog({required this.color});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('色に名前を付けて保存'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.borderDark),
                ),
              ),
              const SizedBox(width: 12),
              Text(colorToHex(widget.color)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: maxSavedColorNameLength,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: '名前',
              hintText: '例：お気に入りの緑',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

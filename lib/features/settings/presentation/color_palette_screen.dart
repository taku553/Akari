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
    final notifier = ref.read(userSettingsNotifierProvider.notifier);
    final current =
        ref.read(userSettingsNotifierProvider).valueOrNull ??
        const UserSettings();
    await notifier.updateSettings(
      current.copyWith(accentColorValue: accentColorValue),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canUse = ref.watch(canUseColorPaletteProvider);
    final ratio = contrastRatio(_color, Colors.white);
    final contrastOk = ratio >= minAccentContrastRatio;
    final canSave = canUse && _hexError == null && contrastOk && !_isSaving;

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
                      foregroundColor: Colors.white,
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
    // ボタンの白文字を基準に判定しているため、ダーク背景では暗い色が溶け込む場合がある（保存は妨げない）
    final darkRatio = contrastRatio(_color, context.palette.backgroundWhite);
    final showDarkHint = context.isDarkTheme && ok && darkRatio < 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ok ? Icons.check_circle : Icons.error, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ok
                    ? '白とのコントラスト比 ${ratio.toStringAsFixed(2)}:1（読みやすい色です）'
                    : '白とのコントラスト比が ${ratio.toStringAsFixed(2)}:1 です。'
                          '文字が読みにくくなるため、${minAccentContrastRatio.toStringAsFixed(1)}:1 以上になるよう、もう少し濃い色を選んでください。',
                style: TextStyle(fontSize: 13, color: color),
              ),
            ),
          ],
        ),
        if (showDarkHint) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ダークモードでは、この色は背景に溶け込んで見えにくい場合があります。',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                  foregroundColor: Colors.white,
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

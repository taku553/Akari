import 'package:akari/core/auth/auth_service.dart';
import 'package:akari/core/theme/accent_color.dart';
import 'package:akari/core/theme/app_colors.dart';
import 'package:akari/core/theme/app_palette.dart';
import 'package:akari/core/theme/theme_mode_provider.dart';
import 'package:akari/features/settings/domain/saved_color.dart';
import 'package:akari/features/settings/domain/user_settings.dart';
import 'package:akari/features/settings/providers/user_settings_provider.dart';
import 'package:akari/features/subscription/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserSettingsNotifier extends UserSettingsNotifier {
  _FakeUserSettingsNotifier(this._settings);
  final UserSettings _settings;

  @override
  Future<UserSettings> build() async => _settings;
}

const _savedColor = Color(0xFF1E3A8A);

ProviderContainer _container({required String? uid, required bool subscribed}) {
  final container = ProviderContainer(
    overrides: [
      currentUidProvider.overrideWithValue(uid),
      hasSubscriptionProvider.overrideWithValue(subscribed),
      userSettingsNotifierProvider.overrideWith(
        () => _FakeUserSettingsNotifier(
          UserSettings(accentColorValue: _savedColor.toARGB32()),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('parseHexColor / colorToHex', () {
    test('#RRGGBB と # なしの両方を受け付け、不正な値はnullを返す', () {
      expect(parseHexColor('#1e3a8a'), const Color(0xFF1E3A8A));
      expect(parseHexColor('1E3A8A'), const Color(0xFF1E3A8A));
      expect(parseHexColor('#FFF'), isNull);
      expect(parseHexColor('#GGGGGG'), isNull);
      expect(parseHexColor(''), isNull);
    });

    test('colorToHex は大文字の #RRGGBB を返す', () {
      expect(colorToHex(const Color(0xFF0A0B0C)), '#0A0B0C');
    });
  });

  group('コントラスト', () {
    test('白は黒と21:1、同色は1:1', () {
      expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
      expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.01));
    });

    test('背景とのコントラスト比3.1:1の境界を判定する', () {
      const light = Colors.white;
      final dark = AppPalette.dark.backgroundWhite;
      expect(meetsAccentContrast(_savedColor, light), isTrue);
      // 純白はライトの背景（白）では見えないが、ダークの背景では制約なく使える
      expect(meetsAccentContrast(Colors.white, light), isFalse);
      expect(meetsAccentContrast(Colors.white, dark), isTrue);
      // 暗い色はダークの背景に溶ける
      expect(meetsAccentContrast(_savedColor, dark), isFalse);
      expect(meetsAccentContrast(const Color(0xFFFFFF00), light), isFalse);
    });

    test('onAccentOf は明るい色で黒、デフォルトの赤や暗い色で白を返す', () {
      expect(onAccentOf(Colors.white), Colors.black);
      expect(onAccentOf(const Color(0xFFFFFF00)), Colors.black);
      expect(onAccentOf(AppColors.primary), Colors.white);
      expect(onAccentOf(_savedColor), Colors.white);
    });
  });

  group('ダークテーマ', () {
    test('buildAppTheme はブライトネスに応じたパレットを持つ', () {
      final dark = buildAppTheme(brightness: Brightness.dark);
      expect(dark.brightness, Brightness.dark);
      expect(dark.extension<AppPalette>(), AppPalette.dark);
      expect(buildAppTheme().extension<AppPalette>(), AppPalette.light);
    });

    test('ダークの文字色は背景に対してWCAG AA(4.5:1)を満たす', () {
      const p = AppPalette.dark;
      for (final bg in [p.backgroundWhite, p.backgroundLight]) {
        expect(contrastRatio(p.textPrimary, bg), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(p.textSecondary, bg), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(p.textTertiary, bg), greaterThanOrEqualTo(3));
      }
    });

    test('themeModeProvider は切り替えできる（Hive未初期化でも動作）', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.light);
      await container.read(themeModeProvider.notifier).setDark(true);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(brightnessProvider), Brightness.dark);
    });
  });

  group('accentColorProvider', () {
    test('ログイン済みでサブスク有効なら保存された色を返す', () async {
      final container = _container(uid: 'user', subscribed: true);
      await container.read(userSettingsNotifierProvider.future);
      expect(container.read(accentColorProvider), _savedColor);
    });

    test('現在のテーマの背景に溶ける色は、保存値は残したまま表示だけデフォルトの赤にする', () async {
      final container = _container(uid: 'user', subscribed: true);
      await container.read(userSettingsNotifierProvider.future);
      // 暗い紺はライトでは表示できるが、ダークの背景では溶ける
      await container.read(themeModeProvider.notifier).setDark(true);
      expect(container.read(accentColorProvider), AppColors.primary);
      final settings = container.read(userSettingsNotifierProvider).value!;
      expect(settings.accentColorValue, _savedColor.toARGB32());
      await container.read(themeModeProvider.notifier).setDark(false);
      expect(container.read(accentColorProvider), _savedColor);
    });

    test('ダークで選んだ純白は、ダークでは表示されライトでは表示だけデフォルトになる', () async {
      final container = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('user'),
          hasSubscriptionProvider.overrideWithValue(true),
          userSettingsNotifierProvider.overrideWith(
            () => _FakeUserSettingsNotifier(
              UserSettings(accentColorValue: Colors.white.toARGB32()),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(userSettingsNotifierProvider.future);
      await container.read(themeModeProvider.notifier).setDark(true);
      expect(container.read(accentColorProvider), Colors.white);
      await container.read(themeModeProvider.notifier).setDark(false);
      expect(container.read(accentColorProvider), AppColors.primary);
    });

    test('保存した色は名前付きでJSONに往復変換できる（Firestore保存用）', () {
      const settings = UserSettings(
        savedColors: [SavedColor(name: '緑', colorValue: 0xFF2E7D32)],
      );
      final json = settings.toJson();
      expect(json['savedColors'], [
        {'name': '緑', 'colorValue': 0xFF2E7D32},
      ]);
      expect(UserSettings.fromJson(json), settings);
      expect(UserSettings.fromJson({}).savedColors, isEmpty);
    });

    test('サブスク無効（未契約・解約後）なら保存値があってもデフォルトの赤を返す', () async {
      final container = _container(uid: 'user', subscribed: false);
      await container.read(userSettingsNotifierProvider.future);
      expect(container.read(accentColorProvider), AppColors.primary);
    });

    test('ゲストはサブスク有効でも利用できず、デフォルトの赤を返す', () async {
      final container = _container(uid: null, subscribed: true);
      await container.read(userSettingsNotifierProvider.future);
      expect(container.read(canUseColorPaletteProvider), isFalse);
      expect(container.read(accentColorProvider), AppColors.primary);
    });
  });
}

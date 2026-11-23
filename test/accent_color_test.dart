import 'package:akari/core/auth/auth_service.dart';
import 'package:akari/core/theme/accent_color.dart';
import 'package:akari/core/theme/app_colors.dart';
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

ProviderContainer _container({
  required String? uid,
  required bool subscribed,
}) {
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

    test('白とのコントラスト比4.5:1の境界を判定する', () {
      expect(meetsAccentContrast(_savedColor), isTrue);
      // デフォルトの赤は白とのコントラスト比が約2.8:1で基準未満
      expect(meetsAccentContrast(AppColors.primary), isFalse);
      expect(meetsAccentContrast(const Color(0xFFFFFF00)), isFalse);
    });
  });

  group('accentColorProvider', () {
    test('ログイン済みでサブスク有効なら保存された色を返す', () async {
      final container = _container(uid: 'user', subscribed: true);
      await container.read(userSettingsNotifierProvider.future);
      expect(container.read(accentColorProvider), _savedColor);
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

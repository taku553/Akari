import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const UserSettings._();

  const factory UserSettings({
    // key: レベルの文字列(例: "1", "10"), value: デフォルト経験値
    // 初期値として、レベル1から250とする設定を含めておく
    @Default({'1': 250}) Map<String, int> defaultTaskExpMap,
    // カラーパレットで選択したアクセントカラー(0xAARRGGBB)。null はデフォルト色。
    // サブスクリプション解約後も値は保持し、表示時にデフォルト色へ戻す。
    int? accentColorValue,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  /// ユーザーの現在のレベルを与えると、適用されるべきデフォルト経験値を計算して返す
  int getDefaultExpForLevel(int currentLevel) {
    if (defaultTaskExpMap.isEmpty) return 250;

    int applicableExp = 250;
    int maxApplicableLevel = 0;

    // 設定されたレベル順にチェックし、現在レベル以下の最大のレベルの設定を適用
    defaultTaskExpMap.forEach((levelStr, exp) {
      final level = int.tryParse(levelStr);
      if (level != null &&
          level <= currentLevel &&
          level >= maxApplicableLevel) {
        maxApplicableLevel = level;
        applicableExp = exp;
      }
    });

    return applicableExp;
  }
}

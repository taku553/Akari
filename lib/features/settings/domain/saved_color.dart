import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_color.freezed.dart';
part 'saved_color.g.dart';

/// カラーパレットで名前を付けて保存した色
@freezed
class SavedColor with _$SavedColor {
  const factory SavedColor({
    // ユーザーが付けた名前
    required String name,
    // 0xAARRGGBB
    required int colorValue,
  }) = _SavedColor;

  factory SavedColor.fromJson(Map<String, dynamic> json) =>
      _$SavedColorFromJson(json);
}

/// 保存できる色の最大数
const int maxSavedColors = 5;

/// 保存する名前の最大文字数
const int maxSavedColorNameLength = 12;

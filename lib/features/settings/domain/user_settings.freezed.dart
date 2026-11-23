// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
// key: レベルの文字列(例: "1", "10"), value: デフォルト経験値
// 初期値として、レベル1から250とする設定を含めておく
  Map<String, int> get defaultTaskExpMap =>
      throw _privateConstructorUsedError; // カラーパレットで選択したアクセントカラー(0xAARRGGBB)。null はデフォルト色。
// サブスクリプション解約後も値は保持し、表示時にデフォルト色へ戻す。
  int? get accentColorValue => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call({Map<String, int> defaultTaskExpMap, int? accentColorValue});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultTaskExpMap = null,
    Object? accentColorValue = freezed,
  }) {
    return _then(_value.copyWith(
      defaultTaskExpMap: null == defaultTaskExpMap
          ? _value.defaultTaskExpMap
          : defaultTaskExpMap // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      accentColorValue: freezed == accentColorValue
          ? _value.accentColorValue
          : accentColorValue // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, int> defaultTaskExpMap, int? accentColorValue});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultTaskExpMap = null,
    Object? accentColorValue = freezed,
  }) {
    return _then(_$UserSettingsImpl(
      defaultTaskExpMap: null == defaultTaskExpMap
          ? _value._defaultTaskExpMap
          : defaultTaskExpMap // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      accentColorValue: freezed == accentColorValue
          ? _value.accentColorValue
          : accentColorValue // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl extends _UserSettings {
  const _$UserSettingsImpl(
      {final Map<String, int> defaultTaskExpMap = const {'1': 250},
      this.accentColorValue})
      : _defaultTaskExpMap = defaultTaskExpMap,
        super._();

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

// key: レベルの文字列(例: "1", "10"), value: デフォルト経験値
// 初期値として、レベル1から250とする設定を含めておく
  final Map<String, int> _defaultTaskExpMap;
// key: レベルの文字列(例: "1", "10"), value: デフォルト経験値
// 初期値として、レベル1から250とする設定を含めておく
  @override
  @JsonKey()
  Map<String, int> get defaultTaskExpMap {
    if (_defaultTaskExpMap is EqualUnmodifiableMapView)
      return _defaultTaskExpMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_defaultTaskExpMap);
  }

// カラーパレットで選択したアクセントカラー(0xAARRGGBB)。null はデフォルト色。
// サブスクリプション解約後も値は保持し、表示時にデフォルト色へ戻す。
  @override
  final int? accentColorValue;

  @override
  String toString() {
    return 'UserSettings(defaultTaskExpMap: $defaultTaskExpMap, accentColorValue: $accentColorValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            const DeepCollectionEquality()
                .equals(other._defaultTaskExpMap, _defaultTaskExpMap) &&
            (identical(other.accentColorValue, accentColorValue) ||
                other.accentColorValue == accentColorValue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_defaultTaskExpMap),
      accentColorValue);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(
      this,
    );
  }
}

abstract class _UserSettings extends UserSettings {
  const factory _UserSettings(
      {final Map<String, int> defaultTaskExpMap,
      final int? accentColorValue}) = _$UserSettingsImpl;
  const _UserSettings._() : super._();

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override // key: レベルの文字列(例: "1", "10"), value: デフォルト経験値
// 初期値として、レベル1から250とする設定を含めておく
  Map<String, int> get defaultTaskExpMap;
  @override // カラーパレットで選択したアクセントカラー(0xAARRGGBB)。null はデフォルト色。
// サブスクリプション解約後も値は保持し、表示時にデフォルト色へ戻す。
  int? get accentColorValue;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

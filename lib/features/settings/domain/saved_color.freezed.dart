// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_color.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SavedColor _$SavedColorFromJson(Map<String, dynamic> json) {
  return _SavedColor.fromJson(json);
}

/// @nodoc
mixin _$SavedColor {
  // ユーザーが付けた名前
  String get name => throw _privateConstructorUsedError; // 0xAARRGGBB
  int get colorValue => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SavedColorCopyWith<SavedColor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedColorCopyWith<$Res> {
  factory $SavedColorCopyWith(
    SavedColor value,
    $Res Function(SavedColor) then,
  ) = _$SavedColorCopyWithImpl<$Res, SavedColor>;
  @useResult
  $Res call({String name, int colorValue});
}

/// @nodoc
class _$SavedColorCopyWithImpl<$Res, $Val extends SavedColor>
    implements $SavedColorCopyWith<$Res> {
  _$SavedColorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? name = null, Object? colorValue = null}) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            colorValue: null == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SavedColorImplCopyWith<$Res>
    implements $SavedColorCopyWith<$Res> {
  factory _$$SavedColorImplCopyWith(
    _$SavedColorImpl value,
    $Res Function(_$SavedColorImpl) then,
  ) = __$$SavedColorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int colorValue});
}

/// @nodoc
class __$$SavedColorImplCopyWithImpl<$Res>
    extends _$SavedColorCopyWithImpl<$Res, _$SavedColorImpl>
    implements _$$SavedColorImplCopyWith<$Res> {
  __$$SavedColorImplCopyWithImpl(
    _$SavedColorImpl _value,
    $Res Function(_$SavedColorImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? name = null, Object? colorValue = null}) {
    return _then(
      _$SavedColorImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        colorValue: null == colorValue
            ? _value.colorValue
            : colorValue // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SavedColorImpl implements _SavedColor {
  const _$SavedColorImpl({required this.name, required this.colorValue});

  factory _$SavedColorImpl.fromJson(Map<String, dynamic> json) =>
      _$$SavedColorImplFromJson(json);

  // ユーザーが付けた名前
  @override
  final String name;
  // 0xAARRGGBB
  @override
  final int colorValue;

  @override
  String toString() {
    return 'SavedColor(name: $name, colorValue: $colorValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedColorImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, colorValue);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedColorImplCopyWith<_$SavedColorImpl> get copyWith =>
      __$$SavedColorImplCopyWithImpl<_$SavedColorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SavedColorImplToJson(this);
  }
}

abstract class _SavedColor implements SavedColor {
  const factory _SavedColor({
    required final String name,
    required final int colorValue,
  }) = _$SavedColorImpl;

  factory _SavedColor.fromJson(Map<String, dynamic> json) =
      _$SavedColorImpl.fromJson;

  @override // ユーザーが付けた名前
  String get name;
  @override // 0xAARRGGBB
  int get colorValue;
  @override
  @JsonKey(ignore: true)
  _$$SavedColorImplCopyWith<_$SavedColorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

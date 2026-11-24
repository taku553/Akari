// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      defaultTaskExpMap:
          (json['defaultTaskExpMap'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {'1': 250},
      accentColorValue: (json['accentColorValue'] as num?)?.toInt(),
      savedColors:
          (json['savedColors'] as List<dynamic>?)
              ?.map((e) => SavedColor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'defaultTaskExpMap': instance.defaultTaskExpMap,
      'accentColorValue': instance.accentColorValue,
      'savedColors': instance.savedColors.map((e) => e.toJson()).toList(),
    };

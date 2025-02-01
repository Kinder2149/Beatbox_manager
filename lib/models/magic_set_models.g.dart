// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magic_set_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColorConverter _$ColorConverterFromJson(Map<String, dynamic> json) =>
    ColorConverter();

Map<String, dynamic> _$ColorConverterToJson(ColorConverter instance) =>
    <String, dynamic>{};

DurationConverter _$DurationConverterFromJson(Map<String, dynamic> json) =>
    DurationConverter();

Map<String, dynamic> _$DurationConverterToJson(DurationConverter instance) =>
    <String, dynamic>{};

_$TagImpl _$$TagImplFromJson(Map<String, dynamic> json) => _$TagImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      color: const ColorConverter().fromJson((json['color'] as num).toInt()),
      scope: $enumDecode(_$TagScopeEnumMap, json['scope']),
    );

Map<String, dynamic> _$$TagImplToJson(_$TagImpl instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': const ColorConverter().toJson(instance.color),
      'scope': _$TagScopeEnumMap[instance.scope]!,
    };

const _$TagScopeEnumMap = {
  TagScope.PLAYLIST: 'PLAYLIST',
  TagScope.TRACK: 'TRACK',
};

_$TrackInfoImpl _$$TrackInfoImplFromJson(Map<String, dynamic> json) =>
    _$TrackInfoImpl(
      trackId: json['trackId'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: json['notes'] as String? ?? '',
      customFields: json['customFields'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$TrackInfoImplToJson(_$TrackInfoImpl instance) =>
    <String, dynamic>{
      'trackId': instance.trackId,
      'tags': instance.tags.map((e) => e.toJson()).toList(),
      'notes': instance.notes,
      'customFields': instance.customFields,
    };

_$MagicSetImpl _$$MagicSetImplFromJson(Map<String, dynamic> json) =>
    _$MagicSetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      playlistId: json['playlistId'] as String,
      description: json['description'] as String? ?? '',
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => TrackInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      totalDuration: const DurationConverter()
          .fromJson((json['totalDuration'] as num).toInt()),
      isTemplate: json['isTemplate'] as bool? ?? false,
    );

Map<String, dynamic> _$$MagicSetImplToJson(_$MagicSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'playlistId': instance.playlistId,
      'description': instance.description,
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
      'tags': instance.tags.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'totalDuration': const DurationConverter().toJson(instance.totalDuration),
      'isTemplate': instance.isTemplate,
    };

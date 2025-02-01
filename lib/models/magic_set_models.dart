import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spotify/spotify.dart';

part 'magic_set_models.freezed.dart';
part 'magic_set_models.g.dart';

enum TagScope { PLAYLIST, TRACK }

// Séparation du ColorConverter et DurationConverter
@JsonSerializable()
class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color color) => color.value;
}

@JsonSerializable()
class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration duration) => duration.inMilliseconds;
}

@freezed
abstract class Tag with _$Tag {
  @JsonSerializable(explicitToJson: true)
  factory Tag({
    required String id,
    required String name,
    @ColorConverter() required Color color,
    required TagScope scope,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}

@freezed
abstract class TrackInfo with _$TrackInfo {
  @JsonSerializable(explicitToJson: true)
  factory TrackInfo({
    required String trackId,
    @Default([]) List<Tag> tags,
    @Default('') String notes,
    @Default({}) Map<String, dynamic> customFields,
  }) = _TrackInfo;

  factory TrackInfo.fromJson(Map<String, dynamic> json) => _$TrackInfoFromJson(json);
}

@freezed
abstract class MagicSet with _$MagicSet {
  @JsonSerializable(explicitToJson: true)
  factory MagicSet({
    required String id,
    required String name,
    required String playlistId,
    @Default('') String description,
    @Default([]) List<TrackInfo> tracks,
    @Default([]) List<Tag> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
    @DurationConverter() required Duration totalDuration,
    @Default(false) bool isTemplate,
  }) = _MagicSet;

  factory MagicSet.fromJson(Map<String, dynamic> json) => _$MagicSetFromJson(json);
  factory MagicSet.create({
    required String name,
    required String playlistId,
    String description = '',
    List<Tag> tags = const [],
    bool isTemplate = false,
  }) {
    return MagicSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      playlistId: playlistId,
      tags: tags,
      tracks: [],
      isTemplate: isTemplate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: Duration.zero,
    );
  }

  factory MagicSet.fromTemplate(MagicSet template, String playlistId) {
    return MagicSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${template.name} (Copy)',
      playlistId: playlistId,
      description: template.description,
      tags: template.tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: template.totalDuration,
      isTemplate: false,
    );
  }
}


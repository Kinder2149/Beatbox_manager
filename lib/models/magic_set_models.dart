import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spotify/spotify.dart';

part 'magic_set_models.freezed.dart';
part 'magic_set_models.g.dart';

enum TagScope { track, set, global }

enum ExportFormat {
  JSON,
  PDF,
  CSV
}

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
class Tag with _$Tag {
  const Tag._(); // Constructeur privé nécessaire

  @JsonSerializable(explicitToJson: true)
  const factory Tag({
    required String id,
    required String name,
    @ColorConverter() required Color color,
    required TagScope scope,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}

@freezed
class TrackInfo with _$TrackInfo {
  const TrackInfo._(); // Constructeur privé nécessaire

  @JsonSerializable(explicitToJson: true)
  const factory TrackInfo({
    required String trackId,
    @Default([]) List<Tag> tags,
    @Default('') String notes,
    @Default({}) Map<String, dynamic> customFields,
    @Default(Duration.zero) @DurationConverter() Duration duration,
    String? key,
    int? bpm,
    @Default({}) Map<String, dynamic> customMetadata,
  }) = _TrackInfo;

  factory TrackInfo.fromJson(Map<String, dynamic> json) => _$TrackInfoFromJson(json);

  // Methods
  TrackInfo updateMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(
      customMetadata: {
        ...customMetadata,
        ...newMetadata,
      },
    );
  }

  TrackInfo addTag(Tag tag) {
    if (tags.any((t) => t.id == tag.id)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  TrackInfo removeTag(String tagId) {
    return copyWith(tags: tags.where((t) => t.id != tagId).toList());
  }
}

@freezed
class MagicSet with _$MagicSet {
  const MagicSet._(); // Constructeur privé nécessaire

  @JsonSerializable(explicitToJson: true)
  const factory MagicSet({
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
    @Default({}) Map<String, dynamic> metadata,
  }) = _MagicSet;

  factory MagicSet.fromJson(Map<String, dynamic> json) => _$MagicSetFromJson(json);

  // Factory constructors
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
      metadata: Map<String, dynamic>.from(template.metadata),
    );
  }

  // Getters
  Duration get computeTotalDuration {
    return tracks.fold(
      Duration.zero,
          (total, track) => total + track.duration,
    );
  }

  // Methods
  MagicSet copyWithUpdatedDuration() {
    return copyWith(
      totalDuration: computeTotalDuration,
      updatedAt: DateTime.now(),
    );
  }

  MagicSet addTrack(TrackInfo track) {
    if (tracks.any((t) => t.trackId == track.trackId)) return this;
    return copyWith(
      tracks: [...tracks, track],
      updatedAt: DateTime.now(),
    ).copyWithUpdatedDuration();
  }

  MagicSet updateTrack(TrackInfo updatedTrack) {
    final newTracks = tracks.map((track) =>
    track.trackId == updatedTrack.trackId ? updatedTrack : track
    ).toList();

    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    ).copyWithUpdatedDuration();
  }

  MagicSet removeTrack(String trackId) {
    return copyWith(
      tracks: tracks.where((t) => t.trackId != trackId).toList(),
      updatedAt: DateTime.now(),
    ).copyWithUpdatedDuration();
  }

  MagicSet addTag(Tag tag) {
    if (tags.any((t) => t.id == tag.id)) return this;
    return copyWith(
      tags: [...tags, tag],
      updatedAt: DateTime.now(),
    );
  }

  MagicSet removeTag(String tagId) {
    return copyWith(
      tags: tags.where((t) => t.id != tagId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  MagicSet updateMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(
      metadata: {
        ...metadata,
        ...newMetadata,
      },
      updatedAt: DateTime.now(),
    );
  }
}
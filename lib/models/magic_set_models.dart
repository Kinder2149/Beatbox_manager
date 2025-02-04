import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spotify/spotify.dart';
import 'package:beatbox_manager/utils/unified_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class PaginationInfo with _$PaginationInfo {
  const factory PaginationInfo({
    @Default(0) int currentPage,
    @Default(20) int itemsPerPage,
    @Default(false) bool hasReachedEnd,
    @Default(0) int totalItems,
  }) = _PaginationInfo;
}

@freezed
class SyncInfo with _$SyncInfo {
  const factory SyncInfo({
    @Default(false) bool isSyncing,
    DateTime? lastSync,
    @Default({}) Map<String, DateTime> lastSetSync,
  }) = _SyncInfo;
}

@freezed
class MagicSetState with _$MagicSetState {
  const factory MagicSetState({
    @Default(AsyncValue<List<MagicSet>>.loading()) AsyncValue<List<MagicSet>> sets,
    @Default(AsyncValue<List<MagicSet>>.loading()) AsyncValue<List<MagicSet>> templates,
    @Default(PaginationInfo()) PaginationInfo pagination,
    @Default(SyncInfo()) SyncInfo syncInfo,
    String? error,
  }) = _MagicSetState;

  const MagicSetState._();

  T when<T>({
    required T Function(List<MagicSet>) data,
    required T Function() loading,
    required T Function(Object error, StackTrace? stackTrace) error,
  }) {
    return sets.when(
      data: data,
      loading: loading,
      error: error,
    );
  }
}

@freezed
class Tag with _$Tag {
  const Tag._();

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
  const TrackInfo._();

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
  const MagicSet._();

  @JsonSerializable(explicitToJson: true)
  const factory MagicSet({
    required String id,
    required String name,
    String? playlistId,
    @Default('') String description,
    @Default([]) List<TrackInfo> tracks,
    @Default([]) List<Tag> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
    @DurationConverter() required Duration totalDuration,
    @Default(false) bool isTemplate,
    @Default(false) bool isPlaylist,
    @Default({}) Map<String, dynamic> metadata,
  }) = _MagicSet;

  factory MagicSet.fromJson(Map<String, dynamic> json) => _$MagicSetFromJson(json);

  factory MagicSet.createTemplate({
    required String name,
    String description = '',
    List<Tag> tags = const [],
    Map<String, dynamic> metadata = const {},
    bool isTemplate = false,
    bool isPlaylist = false,
  }) {
    return MagicSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      tags: tags,
      tracks: [],
      isTemplate: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: Duration.zero,
      metadata: metadata,
    );
  }

  // Ajoutez cette méthode
  MagicSet createFromTemplate(String playlistId) {
    if (!isTemplate) {
      throw ValidationException('Seuls les templates peuvent être utilisés comme base');
    }
    return MagicSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      playlistId: playlistId,
      description: description,
      tags: List.from(tags),
      tracks: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: Duration.zero,
      isTemplate: false,
      metadata: Map<String, dynamic>.from(metadata),
    );
  }


  factory MagicSet.create({
    required String name,
    String? playlistId,
    String description = '',
    List<Tag> tags = const [],
    bool isTemplate = false,
    bool isPlaylist = false, // Ajoutez ce paramètre
  }) {
    return MagicSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      playlistId: playlistId,
      description: description,
      tags: tags,
      tracks: [],
      isTemplate: isTemplate,
      isPlaylist: isPlaylist, // Définissez la valeur
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: Duration.zero,
    );
  }


  void validate() {
    if (name.trim().isEmpty) {
      throw ValidationException('Le nom du Magic Set ne peut pas être vide');
    }
    if (!isTemplate && playlistId == null) {
      throw ValidationException('L\'ID de playlist est requis pour les sets non-templates');
    }
    // Validation des tracks
    for (var track in tracks) {
      if (track.trackId.trim().isEmpty) {
        throw ValidationException('Chaque piste doit avoir un ID valide');
      }
    }
  }

  factory MagicSet.fromTemplate(MagicSet template, String playlistId) {
    if (!template.isTemplate) {
      throw ValidationException('Seuls les templates peuvent être utilisés comme base');
    }
    return MagicSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: template.name,
      playlistId: playlistId,
      description: template.description,
      tags: List.from(template.tags),
      tracks: [],  // Les tracks ne sont pas copiées du template
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: Duration.zero,
      isTemplate: false,
      metadata: Map<String, dynamic>.from(template.metadata),
    );
  }

  Duration get computeTotalDuration {
    return tracks.fold(
      Duration.zero,
          (total, track) => total + track.duration,
    );
  }

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
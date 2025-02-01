// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'magic_set_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Tag _$TagFromJson(Map<String, dynamic> json) {
  return _Tag.fromJson(json);
}

/// @nodoc
mixin _$Tag {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @ColorConverter()
  Color get color => throw _privateConstructorUsedError;
  TagScope get scope => throw _privateConstructorUsedError;

  /// Serializes this Tag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TagCopyWith<Tag> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagCopyWith<$Res> {
  factory $TagCopyWith(Tag value, $Res Function(Tag) then) =
      _$TagCopyWithImpl<$Res, Tag>;
  @useResult
  $Res call(
      {String id, String name, @ColorConverter() Color color, TagScope scope});
}

/// @nodoc
class _$TagCopyWithImpl<$Res, $Val extends Tag> implements $TagCopyWith<$Res> {
  _$TagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? scope = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as TagScope,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TagImplCopyWith<$Res> implements $TagCopyWith<$Res> {
  factory _$$TagImplCopyWith(_$TagImpl value, $Res Function(_$TagImpl) then) =
      __$$TagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, @ColorConverter() Color color, TagScope scope});
}

/// @nodoc
class __$$TagImplCopyWithImpl<$Res> extends _$TagCopyWithImpl<$Res, _$TagImpl>
    implements _$$TagImplCopyWith<$Res> {
  __$$TagImplCopyWithImpl(_$TagImpl _value, $Res Function(_$TagImpl) _then)
      : super(_value, _then);

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? scope = null,
  }) {
    return _then(_$TagImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as TagScope,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TagImpl implements _Tag {
  _$TagImpl(
      {required this.id,
      required this.name,
      @ColorConverter() required this.color,
      required this.scope});

  factory _$TagImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @ColorConverter()
  final Color color;
  @override
  final TagScope scope;

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, color: $color, scope: $scope)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.scope, scope) || other.scope == scope));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, color, scope);

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TagImplCopyWith<_$TagImpl> get copyWith =>
      __$$TagImplCopyWithImpl<_$TagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagImplToJson(
      this,
    );
  }
}

abstract class _Tag implements Tag {
  factory _Tag(
      {required final String id,
      required final String name,
      @ColorConverter() required final Color color,
      required final TagScope scope}) = _$TagImpl;

  factory _Tag.fromJson(Map<String, dynamic> json) = _$TagImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @ColorConverter()
  Color get color;
  @override
  TagScope get scope;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TagImplCopyWith<_$TagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrackInfo _$TrackInfoFromJson(Map<String, dynamic> json) {
  return _TrackInfo.fromJson(json);
}

/// @nodoc
mixin _$TrackInfo {
  String get trackId => throw _privateConstructorUsedError;
  List<Tag> get tags => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  Map<String, dynamic> get customFields => throw _privateConstructorUsedError;

  /// Serializes this TrackInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrackInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrackInfoCopyWith<TrackInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackInfoCopyWith<$Res> {
  factory $TrackInfoCopyWith(TrackInfo value, $Res Function(TrackInfo) then) =
      _$TrackInfoCopyWithImpl<$Res, TrackInfo>;
  @useResult
  $Res call(
      {String trackId,
      List<Tag> tags,
      String notes,
      Map<String, dynamic> customFields});
}

/// @nodoc
class _$TrackInfoCopyWithImpl<$Res, $Val extends TrackInfo>
    implements $TrackInfoCopyWith<$Res> {
  _$TrackInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trackId = null,
    Object? tags = null,
    Object? notes = null,
    Object? customFields = null,
  }) {
    return _then(_value.copyWith(
      trackId: null == trackId
          ? _value.trackId
          : trackId // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      customFields: null == customFields
          ? _value.customFields
          : customFields // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrackInfoImplCopyWith<$Res>
    implements $TrackInfoCopyWith<$Res> {
  factory _$$TrackInfoImplCopyWith(
          _$TrackInfoImpl value, $Res Function(_$TrackInfoImpl) then) =
      __$$TrackInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String trackId,
      List<Tag> tags,
      String notes,
      Map<String, dynamic> customFields});
}

/// @nodoc
class __$$TrackInfoImplCopyWithImpl<$Res>
    extends _$TrackInfoCopyWithImpl<$Res, _$TrackInfoImpl>
    implements _$$TrackInfoImplCopyWith<$Res> {
  __$$TrackInfoImplCopyWithImpl(
      _$TrackInfoImpl _value, $Res Function(_$TrackInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrackInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trackId = null,
    Object? tags = null,
    Object? notes = null,
    Object? customFields = null,
  }) {
    return _then(_$TrackInfoImpl(
      trackId: null == trackId
          ? _value.trackId
          : trackId // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      customFields: null == customFields
          ? _value._customFields
          : customFields // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TrackInfoImpl implements _TrackInfo {
  _$TrackInfoImpl(
      {required this.trackId,
      final List<Tag> tags = const [],
      this.notes = '',
      final Map<String, dynamic> customFields = const {}})
      : _tags = tags,
        _customFields = customFields;

  factory _$TrackInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrackInfoImplFromJson(json);

  @override
  final String trackId;
  final List<Tag> _tags;
  @override
  @JsonKey()
  List<Tag> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final String notes;
  final Map<String, dynamic> _customFields;
  @override
  @JsonKey()
  Map<String, dynamic> get customFields {
    if (_customFields is EqualUnmodifiableMapView) return _customFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customFields);
  }

  @override
  String toString() {
    return 'TrackInfo(trackId: $trackId, tags: $tags, notes: $notes, customFields: $customFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrackInfoImpl &&
            (identical(other.trackId, trackId) || other.trackId == trackId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality()
                .equals(other._customFields, _customFields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      trackId,
      const DeepCollectionEquality().hash(_tags),
      notes,
      const DeepCollectionEquality().hash(_customFields));

  /// Create a copy of TrackInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrackInfoImplCopyWith<_$TrackInfoImpl> get copyWith =>
      __$$TrackInfoImplCopyWithImpl<_$TrackInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrackInfoImplToJson(
      this,
    );
  }
}

abstract class _TrackInfo implements TrackInfo {
  factory _TrackInfo(
      {required final String trackId,
      final List<Tag> tags,
      final String notes,
      final Map<String, dynamic> customFields}) = _$TrackInfoImpl;

  factory _TrackInfo.fromJson(Map<String, dynamic> json) =
      _$TrackInfoImpl.fromJson;

  @override
  String get trackId;
  @override
  List<Tag> get tags;
  @override
  String get notes;
  @override
  Map<String, dynamic> get customFields;

  /// Create a copy of TrackInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrackInfoImplCopyWith<_$TrackInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MagicSet _$MagicSetFromJson(Map<String, dynamic> json) {
  return _MagicSet.fromJson(json);
}

/// @nodoc
mixin _$MagicSet {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get playlistId => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<TrackInfo> get tracks => throw _privateConstructorUsedError;
  List<Tag> get tags => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @DurationConverter()
  Duration get totalDuration => throw _privateConstructorUsedError;
  bool get isTemplate => throw _privateConstructorUsedError;

  /// Serializes this MagicSet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MagicSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MagicSetCopyWith<MagicSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MagicSetCopyWith<$Res> {
  factory $MagicSetCopyWith(MagicSet value, $Res Function(MagicSet) then) =
      _$MagicSetCopyWithImpl<$Res, MagicSet>;
  @useResult
  $Res call(
      {String id,
      String name,
      String playlistId,
      String description,
      List<TrackInfo> tracks,
      List<Tag> tags,
      DateTime createdAt,
      DateTime updatedAt,
      @DurationConverter() Duration totalDuration,
      bool isTemplate});
}

/// @nodoc
class _$MagicSetCopyWithImpl<$Res, $Val extends MagicSet>
    implements $MagicSetCopyWith<$Res> {
  _$MagicSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MagicSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? playlistId = null,
    Object? description = null,
    Object? tracks = null,
    Object? tags = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? totalDuration = null,
    Object? isTemplate = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      playlistId: null == playlistId
          ? _value.playlistId
          : playlistId // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tracks: null == tracks
          ? _value.tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<TrackInfo>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      isTemplate: null == isTemplate
          ? _value.isTemplate
          : isTemplate // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MagicSetImplCopyWith<$Res>
    implements $MagicSetCopyWith<$Res> {
  factory _$$MagicSetImplCopyWith(
          _$MagicSetImpl value, $Res Function(_$MagicSetImpl) then) =
      __$$MagicSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String playlistId,
      String description,
      List<TrackInfo> tracks,
      List<Tag> tags,
      DateTime createdAt,
      DateTime updatedAt,
      @DurationConverter() Duration totalDuration,
      bool isTemplate});
}

/// @nodoc
class __$$MagicSetImplCopyWithImpl<$Res>
    extends _$MagicSetCopyWithImpl<$Res, _$MagicSetImpl>
    implements _$$MagicSetImplCopyWith<$Res> {
  __$$MagicSetImplCopyWithImpl(
      _$MagicSetImpl _value, $Res Function(_$MagicSetImpl) _then)
      : super(_value, _then);

  /// Create a copy of MagicSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? playlistId = null,
    Object? description = null,
    Object? tracks = null,
    Object? tags = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? totalDuration = null,
    Object? isTemplate = null,
  }) {
    return _then(_$MagicSetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      playlistId: null == playlistId
          ? _value.playlistId
          : playlistId // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tracks: null == tracks
          ? _value._tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<TrackInfo>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      isTemplate: null == isTemplate
          ? _value.isTemplate
          : isTemplate // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MagicSetImpl implements _MagicSet {
  _$MagicSetImpl(
      {required this.id,
      required this.name,
      required this.playlistId,
      this.description = '',
      final List<TrackInfo> tracks = const [],
      final List<Tag> tags = const [],
      required this.createdAt,
      required this.updatedAt,
      @DurationConverter() required this.totalDuration,
      this.isTemplate = false})
      : _tracks = tracks,
        _tags = tags;

  factory _$MagicSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$MagicSetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String playlistId;
  @override
  @JsonKey()
  final String description;
  final List<TrackInfo> _tracks;
  @override
  @JsonKey()
  List<TrackInfo> get tracks {
    if (_tracks is EqualUnmodifiableListView) return _tracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tracks);
  }

  final List<Tag> _tags;
  @override
  @JsonKey()
  List<Tag> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @DurationConverter()
  final Duration totalDuration;
  @override
  @JsonKey()
  final bool isTemplate;

  @override
  String toString() {
    return 'MagicSet(id: $id, name: $name, playlistId: $playlistId, description: $description, tracks: $tracks, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt, totalDuration: $totalDuration, isTemplate: $isTemplate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MagicSetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.playlistId, playlistId) ||
                other.playlistId == playlistId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._tracks, _tracks) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.isTemplate, isTemplate) ||
                other.isTemplate == isTemplate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      playlistId,
      description,
      const DeepCollectionEquality().hash(_tracks),
      const DeepCollectionEquality().hash(_tags),
      createdAt,
      updatedAt,
      totalDuration,
      isTemplate);

  /// Create a copy of MagicSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MagicSetImplCopyWith<_$MagicSetImpl> get copyWith =>
      __$$MagicSetImplCopyWithImpl<_$MagicSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MagicSetImplToJson(
      this,
    );
  }
}

abstract class _MagicSet implements MagicSet {
  factory _MagicSet(
      {required final String id,
      required final String name,
      required final String playlistId,
      final String description,
      final List<TrackInfo> tracks,
      final List<Tag> tags,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      @DurationConverter() required final Duration totalDuration,
      final bool isTemplate}) = _$MagicSetImpl;

  factory _MagicSet.fromJson(Map<String, dynamic> json) =
      _$MagicSetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get playlistId;
  @override
  String get description;
  @override
  List<TrackInfo> get tracks;
  @override
  List<Tag> get tags;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @DurationConverter()
  Duration get totalDuration;
  @override
  bool get isTemplate;

  /// Create a copy of MagicSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MagicSetImplCopyWith<_$MagicSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

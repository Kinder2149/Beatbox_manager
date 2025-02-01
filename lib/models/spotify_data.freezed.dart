// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spotify_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SpotifyData {
  List<Track> get tracks => throw _privateConstructorUsedError;
  List<PlaylistSimple> get playlists => throw _privateConstructorUsedError;
  List<TrackSaved> get likedTracks => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyDataCopyWith<SpotifyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyDataCopyWith<$Res> {
  factory $SpotifyDataCopyWith(
          SpotifyData value, $Res Function(SpotifyData) then) =
      _$SpotifyDataCopyWithImpl<$Res, SpotifyData>;
  @useResult
  $Res call(
      {List<Track> tracks,
      List<PlaylistSimple> playlists,
      List<TrackSaved> likedTracks,
      String? userName,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$SpotifyDataCopyWithImpl<$Res, $Val extends SpotifyData>
    implements $SpotifyDataCopyWith<$Res> {
  _$SpotifyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tracks = null,
    Object? playlists = null,
    Object? likedTracks = null,
    Object? userName = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      tracks: null == tracks
          ? _value.tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<Track>,
      playlists: null == playlists
          ? _value.playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<PlaylistSimple>,
      likedTracks: null == likedTracks
          ? _value.likedTracks
          : likedTracks // ignore: cast_nullable_to_non_nullable
              as List<TrackSaved>,
      userName: freezed == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpotifyDataImplCopyWith<$Res>
    implements $SpotifyDataCopyWith<$Res> {
  factory _$$SpotifyDataImplCopyWith(
          _$SpotifyDataImpl value, $Res Function(_$SpotifyDataImpl) then) =
      __$$SpotifyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Track> tracks,
      List<PlaylistSimple> playlists,
      List<TrackSaved> likedTracks,
      String? userName,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$SpotifyDataImplCopyWithImpl<$Res>
    extends _$SpotifyDataCopyWithImpl<$Res, _$SpotifyDataImpl>
    implements _$$SpotifyDataImplCopyWith<$Res> {
  __$$SpotifyDataImplCopyWithImpl(
      _$SpotifyDataImpl _value, $Res Function(_$SpotifyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpotifyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tracks = null,
    Object? playlists = null,
    Object? likedTracks = null,
    Object? userName = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$SpotifyDataImpl(
      tracks: null == tracks
          ? _value._tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<Track>,
      playlists: null == playlists
          ? _value._playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<PlaylistSimple>,
      likedTracks: null == likedTracks
          ? _value._likedTracks
          : likedTracks // ignore: cast_nullable_to_non_nullable
              as List<TrackSaved>,
      userName: freezed == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SpotifyDataImpl implements _SpotifyData {
  const _$SpotifyDataImpl(
      {final List<Track> tracks = const [],
      final List<PlaylistSimple> playlists = const [],
      final List<TrackSaved> likedTracks = const [],
      this.userName,
      this.isLoading = false,
      this.error})
      : _tracks = tracks,
        _playlists = playlists,
        _likedTracks = likedTracks;

  final List<Track> _tracks;
  @override
  @JsonKey()
  List<Track> get tracks {
    if (_tracks is EqualUnmodifiableListView) return _tracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tracks);
  }

  final List<PlaylistSimple> _playlists;
  @override
  @JsonKey()
  List<PlaylistSimple> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  final List<TrackSaved> _likedTracks;
  @override
  @JsonKey()
  List<TrackSaved> get likedTracks {
    if (_likedTracks is EqualUnmodifiableListView) return _likedTracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_likedTracks);
  }

  @override
  final String? userName;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'SpotifyData(tracks: $tracks, playlists: $playlists, likedTracks: $likedTracks, userName: $userName, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyDataImpl &&
            const DeepCollectionEquality().equals(other._tracks, _tracks) &&
            const DeepCollectionEquality()
                .equals(other._playlists, _playlists) &&
            const DeepCollectionEquality()
                .equals(other._likedTracks, _likedTracks) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_tracks),
      const DeepCollectionEquality().hash(_playlists),
      const DeepCollectionEquality().hash(_likedTracks),
      userName,
      isLoading,
      error);

  /// Create a copy of SpotifyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyDataImplCopyWith<_$SpotifyDataImpl> get copyWith =>
      __$$SpotifyDataImplCopyWithImpl<_$SpotifyDataImpl>(this, _$identity);
}

abstract class _SpotifyData implements SpotifyData {
  const factory _SpotifyData(
      {final List<Track> tracks,
      final List<PlaylistSimple> playlists,
      final List<TrackSaved> likedTracks,
      final String? userName,
      final bool isLoading,
      final String? error}) = _$SpotifyDataImpl;

  @override
  List<Track> get tracks;
  @override
  List<PlaylistSimple> get playlists;
  @override
  List<TrackSaved> get likedTracks;
  @override
  String? get userName;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of SpotifyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyDataImplCopyWith<_$SpotifyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

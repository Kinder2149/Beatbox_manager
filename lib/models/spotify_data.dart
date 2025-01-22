import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spotify/spotify.dart';


part 'spotify_data.freezed.dart';

@freezed
class SpotifyData with _$SpotifyData {
  const factory SpotifyData({
    @Default([]) List<Track> tracks,
    @Default([]) List<PlaylistSimple> playlists,
    @Default([]) List<TrackSaved> likedTracks,
    String? userName,
    @Default(false) bool isLoading,
    String? error,
  }) = _SpotifyData;
}
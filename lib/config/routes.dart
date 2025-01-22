import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import '../screens/home_screen.dart';
import '../screens/hello_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/liked_tracks_screen.dart';
import '../screens/playlist_tracks_screen.dart';


class AppRoutes {
  static const String home = '/';
  static const String hello = '/hello';
  static const String playlists = '/playlists';
  static const String likedTracks = '/liked-tracks';
  static const String playlistTracks = '/playlist-tracks';


  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case hello:
        return MaterialPageRoute(builder: (_) => HelloScreen());
      case playlists:
        return MaterialPageRoute(builder: (_) => const PlaylistsScreen());
      case likedTracks:
        return MaterialPageRoute(builder: (_) => const LikedTracksScreen());
      case playlistTracks:
        final playlist = settings.arguments as PlaylistSimple;
        return MaterialPageRoute(
            builder: (_) => PlaylistTracksScreen(playlist: playlist)
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route non définie: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import '../screens/home_screen.dart';
import '../screens/hello_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/liked_tracks_screen.dart';
import '../screens/playlist_tracks_screen.dart';
import '../models/magic_set_models.dart';
import 'package:flutter/material.dart';
import '../screens/magic_sets/magic_sets_screen.dart';
import '../screens/magic_sets/magic_set_detail_screen.dart';
import '../screens/magic_sets/magic_set_editor_screen.dart';
import '../screens/magic_sets/tag_manager_screen.dart';
import '../models/magic_set_models.dart';


class AppRoutes {
  static const String home = '/';
  static const String hello = '/hello';
  static const String playlists = '/playlists';
  static const String likedTracks = '/liked-tracks';
  static const String playlistTracks = '/playlist-tracks';
  static const String magicSets = '/magic-sets';
  static const String magicSetDetail = '/magic-set-detail';
  static const String magicSetEditor = '/magic-set-editor';
  static const String tagManager = '/tag-manager';


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
      case magicSets:
        return MaterialPageRoute(builder: (_) => const MagicSetsScreen());
      case magicSetDetail:
        final set = settings.arguments as MagicSet;
        return MaterialPageRoute(builder: (_) => MagicSetDetailScreen(set: set));
      case magicSetEditor:
        final set = settings.arguments as MagicSet?;
        return MaterialPageRoute(builder: (_) => MagicSetEditorScreen(set: set));
      case tagManager:
        return MaterialPageRoute(builder: (_) => const TagManagerScreen());
      case '/magic-set-detail':
        final set = settings.arguments as MagicSet;
        return MaterialPageRoute(
          builder: (_) => MagicSetDetailScreen(set: set),
        );
      case '/magic-set-detail':
        final set = settings.arguments as MagicSet?;
        if (set == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Magic Set non trouvé')),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => MagicSetDetailScreen(set: set));
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
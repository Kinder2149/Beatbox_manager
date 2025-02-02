import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';

// Screens
import '../screens/home_screen.dart';
import '../screens/hello_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/liked_tracks_screen.dart';
import '../screens/playlist_tracks_screen.dart';

// Magic Sets Screens
import '../screens/magic_sets/magic_sets_screen.dart';
import '../screens/magic_sets/magic_set_detail_screen.dart';
import '../screens/magic_sets/magic_set_editor_screen.dart';
import '../screens/magic_sets/tag_manager_screen.dart';
import '../screens/magic_sets/track_detail_screen.dart';
import '../screens/magic_sets/template_editor_screen.dart';

// Models
import '../models/magic_set_models.dart';

class AppRoutes {
  // Routes constantes
  static const String home = '/';
  static const String hello = '/hello';
  static const String playlists = '/playlists';
  static const String likedTracks = '/liked-tracks';
  static const String playlistTracks = '/playlist-tracks';

  // Routes Magic Sets
  static const String magicSets = '/magic-sets';
  static const String magicSetDetail = '/magic-set-detail';
  static const String magicSetEditor = '/magic-set-editor';
  static const String tagManager = '/tag-manager';
  static const String trackDetail = '/track-detail';
  static const String templateEditor = '/template-editor';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Routes principales
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case hello:
        return MaterialPageRoute(builder: (_) => const HelloScreen());
      case playlists:
        return MaterialPageRoute(builder: (_) => const PlaylistsScreen());
      case likedTracks:
        return MaterialPageRoute(builder: (_) => const LikedTracksScreen());
      case playlistTracks:
        final playlist = settings.arguments as PlaylistSimple;
        return MaterialPageRoute(
            builder: (_) => PlaylistTracksScreen(playlist: playlist)
        );

    // Routes Magic Sets
      case magicSets:
        return MaterialPageRoute(builder: (_) => const MagicSetsScreen());
      case magicSetDetail:
        final set = settings.arguments as MagicSet;
        return MaterialPageRoute(
            builder: (_) => MagicSetDetailScreen(set: set)
        );
      case magicSetEditor:
        final set = settings.arguments as MagicSet?;
        return MaterialPageRoute(
            builder: (_) => MagicSetEditorScreen(set: set)
        );
      case templateEditor:
        final template = settings.arguments as MagicSet;
        return MaterialPageRoute(
            builder: (_) => TemplateEditorScreen(template: template)
        );
      case tagManager:
        return MaterialPageRoute(
            builder: (_) => const TagManagerScreen()
        );
      case trackDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TrackDetailScreen(
            setId: args['setId'] as String,
            track: args['track'] as TrackInfo,
          ),
        );

    // Route par défaut
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
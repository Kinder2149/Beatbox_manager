import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:beatbox_manager/config/routes.dart';


class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void _navigate(String routeName, {Object? arguments}) {
    try {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
    } catch (error) {
      handleNavigationError(error);
    }
  }

  void goToHome() {
    try {
      navigatorKey.currentState?.pushReplacementNamed(AppRoutes.home);
    } catch (error) {
      handleNavigationError(error);
    }
  }

  void goToHello() {
    try {
      navigatorKey.currentState?.pushReplacementNamed(AppRoutes.hello);
    } catch (error) {
      handleNavigationError(error);
    }
  }

  void goToPlaylists() {
    _navigate(AppRoutes.playlists);
  }

  void goToLikedTracks() {
    _navigate(AppRoutes.likedTracks);
  }

  void goToPlaylistTracks(PlaylistSimple playlist) {
    if (playlist != null) {
      _navigate(AppRoutes.playlistTracks, arguments: playlist);
    }
  }



  void goBack() {
    try {
      navigatorKey.currentState?.pop();
    } catch (error) {
      handleNavigationError(error);
    }
  }

  void handleNavigationError(Object error) {
    print('Navigation Error: $error');
    goToHome(); // Fallback sécurisé
  }
}
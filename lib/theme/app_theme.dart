import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs Spotify
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color spotifyBlack = Color(0xFF191414);
  static const Color spotifyDarkGrey = Color(0xFF282828);

  // Thème sombre personnalisé
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: spotifyGreen,
    scaffoldBackgroundColor: spotifyBlack,
    appBarTheme: AppBarTheme(
      backgroundColor: spotifyBlack,
      elevation: 0,
    ),
    colorScheme: ColorScheme.dark(
      primary: spotifyGreen,
      secondary: spotifyGreen,
      background: spotifyBlack,
    ),
    textTheme: TextTheme(
      displayLarge: _textStyleBasedOnBackground(spotifyBlack),
      displayMedium: _textStyleBasedOnBackground(spotifyDarkGrey),
      bodyLarge: _textStyleBasedOnBackground(spotifyGreen),
      bodyMedium: TextStyle(color: Colors.white.withOpacity(0.67)),
    ),
  );

  // Fonction utilitaire pour déterminer la couleur du texte selon le fond
  static TextStyle _textStyleBasedOnBackground(Color backgroundColor) {
    if (backgroundColor == spotifyGreen) {
      return TextStyle(color: Colors.white); // Texte blanc pour fond vert
    } else {
      return TextStyle(color: Colors.white.withOpacity(0.87)); // Texte par défaut
    }
  }

  // Décoration de fond dégradé
  static final Decoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        spotifyBlack,
        spotifyDarkGrey,
      ],
    ),
  );

  // Décoration de carte avec dégradé
  static final Decoration cardGradient = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        spotifyDarkGrey.withOpacity(0.7),
        spotifyBlack.withOpacity(0.9),
      ],
    ),
  );
}

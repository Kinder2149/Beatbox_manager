import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpotifyConfig {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get clientSecret => dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
  static String get redirectUri => dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'beatboxmanager://callback';

  static const scopes = [
    'user-read-private',
    'user-library-read',
    'playlist-read-private',
    'playlist-modify-public',
    'playlist-modify-private',
    'user-top-read'
  ];

  // Nouvelle méthode pour journaliser les détails de configuration
  static void printConfigDetails() {
    print('Configuration Spotify :');
    print('Client ID : ${clientId.isNotEmpty ? clientId : "Manquant"}');
    print('Client Secret : ${clientSecret.isNotEmpty ? clientSecret : "Manquant"}');
    print('Redirect URI : $redirectUri');
    print('Scopes : $scopes');
  }
}
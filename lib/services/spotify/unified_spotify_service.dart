// lib/services/spotify/unified_spotify_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spotify/spotify.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../config/spotify_config.dart';
import '../cache/unified_cache_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class UnifiedSpotifyService with ChangeNotifier {
  // Auth Properties
  SpotifyApi? _spotify;
  SpotifyApiCredentials? _credentials;
  String? _codeVerifier;
  String? _state;
  static const String _tokenKey = 'spotify_token';
  static const String _refreshTokenKey = 'spotify_refresh_token';
  static const String _tokenExpirationKey = 'spotify_token_expiration';
  bool _isLoggingIn = false;
  bool _isInitialized = false;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final _iv = encrypt.IV.fromLength(16);

  // Cache Properties
  final UnifiedCacheService _cacheService;
  static const int pageSize = 50;
  static const int MAX_RETRIES = 3;
  static const Duration _cacheValidityDuration = Duration(minutes: 30);

  bool get isConnected => _spotify != null &&
      _credentials != null &&
      _credentials!.accessToken != null;
  SpotifyApi? get spotify => _spotify;

  UnifiedSpotifyService(this._cacheService) {
    init();
  }

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('Service déjà initialisé');
      return;
    }

    debugPrint('SpotifyService: Initialisation du service...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await _initializeFromPrefs(prefs);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
      await clearCredentials();
    }
  }
  Future<Track> getTrack(String trackId) async {
    if (!isConnected) throw Exception('Non connecté à Spotify');
    try {
      return await _spotify!.tracks.get(trackId);
    } catch (e) {
      print('Erreur lors de la récupération du track: $e');
      rethrow;
    }
  }

  Future<void> _initializeFromPrefs(SharedPreferences prefs) async {
    try {
      final encryptedAccessToken = prefs.getString(_tokenKey);
      final encryptedRefreshToken = prefs.getString(_refreshTokenKey);
      final expirationTime = prefs.getInt(_tokenExpirationKey);

      if (encryptedAccessToken == null || encryptedRefreshToken == null || expirationTime == null) {
        print('Aucun token stocké');
        throw Exception('Aucune session précédente trouvée');
      }

      final accessToken = await _decryptToken(encryptedAccessToken);
      final refreshToken = await _decryptToken(encryptedRefreshToken);
      final expiration = DateTime.fromMillisecondsSinceEpoch(expirationTime);

      _initializeCredentials(accessToken, refreshToken, expiration);

      if (DateTime.now().isAfter(expiration.subtract(const Duration(minutes: 5)))) {
        await refreshCredentials();
      }

      if (!await checkTokenValidity()) {
        throw Exception('Token invalide après rafraîchissement');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      await clearCredentials();
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<String> _encryptToken(String token) async {
    final key = await _getOrCreateEncryptionKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(token, iv: _iv).base64;
  }

  Future<encrypt.Key> _getOrCreateEncryptionKey() async {
    String? storedKey = await _secureStorage.read(key: 'encryption_key');
    if (storedKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(key: 'encryption_key', value: key.base64);
      return key;
    }
    return encrypt.Key.fromBase64(storedKey);
  }

  Future<String> _decryptToken(String encryptedToken) async {
    final key = await _getOrCreateEncryptionKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(encryptedToken, iv: _iv);
  }


  Future<void> clearCredentials() async {
    _spotify = null;
    _credentials = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpirationKey);
    await _cacheService.clearCache();
  }

  Future<void> login() async {
    if (_isLoggingIn) {
      debugPrint('Login déjà en cours');
      return;
    }

    _isLoggingIn = true;
    notifyListeners();

    try {
      debugPrint('Début du processus de login');
      await clearCredentials();

      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);
      _state = _generateRandomString(16);

      final uri = Uri.https(
        'accounts.spotify.com',
        '/authorize',
        {
          'client_id': SpotifyConfig.clientId,
          'response_type': 'code',
          'redirect_uri': SpotifyConfig.redirectUri,
          'code_challenge_method': 'S256',
          'code_challenge': codeChallenge,
          'state': _state,
          'scope': SpotifyConfig.scopes.join(' '),
          'show_dialog': 'true',
        },
      );

      final launched = await launchUrlString(
        uri.toString(),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Impossible d\'ouvrir l\'URL de connexion');
      }
    } catch (e) {
      debugPrint('Erreur lors du login: $e');
      rethrow;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> _handleTokenResponse(String responseBody) async {
    final tokenData = json.decode(responseBody);
    final expiration = DateTime.now().add(Duration(seconds: tokenData['expires_in']));

    _credentials = SpotifyApiCredentials(
      SpotifyConfig.clientId,
      SpotifyConfig.clientSecret,
      accessToken: tokenData['access_token'],
      refreshToken: tokenData['refresh_token'],
      scopes: SpotifyConfig.scopes,
      expiration: expiration,
    );

    print('_credentials créé avec succès: $_credentials');

    _spotify = SpotifyApi(_credentials!);

    print('_spotify créé avec succès: $_spotify');

    print('Access token: ${tokenData['access_token']}');
    print('Refresh token: ${tokenData['refresh_token']}');
    print('Expiration: $expiration');

    _spotify = SpotifyApi(_credentials!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, await _encryptToken(tokenData['access_token']));
    await prefs.setString(_refreshTokenKey, await _encryptToken(tokenData['refresh_token']));
    await prefs.setInt(_tokenExpirationKey, expiration.millisecondsSinceEpoch);
  }

  Future<void> handleAuthResponse(Uri uri) async {
    debugPrint('Traitement de la réponse d\'auth: ${uri.toString()}');
    try {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      if (code == null) {
        throw Exception('Code d\'autorisation manquant');
      }
      if (state != _state) {
        throw Exception('État invalide, possible attaque CSRF');
      }

      final tokenResponse = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64.encode(
              utf8.encode('${SpotifyConfig.clientId}:${SpotifyConfig.clientSecret}')
          )}',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': SpotifyConfig.redirectUri,
          'code_verifier': _codeVerifier,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception(
            'Erreur lors de l\'échange du code: ${tokenResponse.statusCode}\n${tokenResponse.body}'
        );
      }

      await _handleTokenResponse(tokenResponse.body);
      debugPrint('Token response traitée avec succès');
      debugPrint('État de connexion après traitement: ${isConnected ? 'Connecté' : 'Non connecté'}');
      notifyListeners();
      if (!isConnected) {
        throw Exception('Échec de connexion après traitement du token');
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement de l\'auth response: $e');
      await logout();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAccountData({bool forceRefresh = false}) async {
    try {
      print('Vérification de la connexion...');
      print('isConnected: $isConnected');
      print('_credentials: $_credentials');
      print('_spotify: $_spotify');

      if (!isConnected) {
        debugPrint('Tentative de récupération des données sans connexion établie');
        throw Exception('Non connecté à Spotify');
      }

      debugPrint('Vérification de la validité du token...');
      final isValid = await checkTokenValidity();
      if (!isValid) {
        debugPrint('Token invalide, tentative de rafraîchissement...');
        await refreshCredentials();
      }

      debugPrint('Récupération des données utilisateur...');
      final user = await _spotify!.me.get();
      debugPrint('Données utilisateur récupérées avec succès');

      debugPrint('Récupération des playlists...');
      final playlists = await fetchUserPlaylists(forceRefresh: forceRefresh);
      debugPrint('Playlists récupérées avec succès');

      debugPrint('Récupération des titres likés...');
      final likedTracks = await fetchLikedTracks(forceRefresh: forceRefresh);
      debugPrint('Titres likés récupérés avec succès');

      return {
        'userName': user.displayName ?? 'Utilisateur',
        'playlistsCount': playlists.length,
        'likedTracksCount': likedTracks.length,
        'lastUpdate': DateTime.now().toIso8601String(),
        // Ajout des informations de profil
        'images': user.images?.map((image) => {
          'url': image.url,
          'height': image.height,
          'width': image.width,
        }).toList() ?? [],
        'displayName': user.displayName,
        'id': user.id,
      };
    } catch (e, stackTrace) {
      print('Erreur dans fetchAccountData: $e');
      print('Stack trace: $stackTrace');

      if (e is AuthorizationException) {
        print('Erreur d\'autorisation, déconnexion...');
        await logout();
        return {'error': 'Erreur d\'autorisation, veuillez vous reconnecter'};
      } else if (e is Exception && e.toString().contains('Non connecté à Spotify')) {
        print('Non connecté à Spotify, vérification des credentials...');
        print('_credentials: $_credentials');
        print('_spotify: $_spotify');
        return {'error': 'Non connecté à Spotify, veuillez réessayer'};
      } else {
        return {'error': 'Erreur lors de la récupération des données utilisateur: ${e.toString()}'};
      }
    } catch (e) {
      print('Erreur dans fetchAccountData: $e');
      rethrow;  // Propagez l'erreur au lieu de la masquer
    }
  }


  Future<List<PlaylistSimple>> fetchUserPlaylists({
    bool forceRefresh = false,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      if (!isConnected) throw Exception('Non connecté à Spotify');

      if (!forceRefresh) {
        final cached = await _cacheService.getCachedPlaylists();
        if (cached != null) {
          print('Utilisation des playlists en cache');
          onProgress?.call(cached.length, cached.length);
          return cached;
        }
      }

      print('Récupération des playlists depuis l\'API Spotify');
      List<PlaylistSimple> allPlaylists = [];
      var offset = 0;
      const limit = 50;
      bool hasMore = true;

      while (hasMore) {
        final page = await _spotify!.playlists.me.getPage(limit, offset);
        final items = page.items ?? [];
        allPlaylists.addAll(items);

        onProgress?.call(allPlaylists.length, allPlaylists.length);

        hasMore = items.length == limit;
        offset += limit;

        if (hasMore) await Future.delayed(const Duration(milliseconds: 100));
      }

      await _cacheService.cachePlaylists(allPlaylists);
      return allPlaylists;
    } catch (e) {
      print('Erreur dans fetchUserPlaylists: $e');
      rethrow;
    }
  }

  Future<T> _retryWithBackoff<T>(Future<T> Function() operation, {int maxAttempts = 3}) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxAttempts - 1) rethrow;
        final waitTime = Duration(seconds: pow(2, attempt).toInt());
        print('Retry attempt ${attempt + 1} after $waitTime');
        await Future.delayed(waitTime);
      }
    }
    throw Exception('Max retry attempts reached');
  }

// Utilisez cette fonction pour les appels API, par exemple :
  Future<List<TrackSaved>> fetchLikedTracks({bool forceRefresh = false}) async {
    if (!isConnected) throw Exception('Non connecté à Spotify');

    if (!forceRefresh) {
      final cached = await _cacheService.getCachedLikedTracks();
      if (cached != null) {
        print('Utilisation des titres likés en cache');
        return cached;
      }
    }

    print('Récupération des titres likés depuis l\'API Spotify');
    try {
      final items = await _spotify!.tracks.me.saved.all().then((pages) => pages.toList());
      final tracks = items.map((item) {
        if (item is TrackSaved) return item;
        return TrackSaved()..track = item as Track;
      }).toList();

      await _cacheService.cacheLikedTracks(tracks);
      return tracks;
    } catch (e) {
      print('Erreur dans fetchLikedTracks: $e');
      rethrow;
    }
  }

  Future<bool> checkTokenValidity() async {
    try {
      if (_spotify == null || _credentials == null) return false;
      if (_credentials!.accessToken == null) return false;
      final expiration = _credentials!.expiration;
      if (expiration != null && expiration.isBefore(DateTime.now())) {
        await refreshCredentials();
      }
      await _spotify!.me.get();
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de la validité du token: $e');
      return false;
    }
  }

  Future<void> refreshCredentials() async {
    if (_credentials?.refreshToken == null) {
      throw Exception('Pas de refresh token disponible');
    }

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64.encode(utf8.encode('${SpotifyConfig.clientId}:${SpotifyConfig.clientSecret}'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _credentials!.refreshToken,
        },
      );

      if (response.statusCode == 200) {
        await _handleTokenResponse(response.body);
      } else {
        throw Exception('Erreur de rafraîchissement: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement: $e');
      await clearCredentials();
      rethrow;
    }
  }

  Future<void> logout() async {
    _spotify = null;
    _credentials = null;
    _codeVerifier = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpirationKey);

    await _cacheService.clearCache();
    notifyListeners();
  }

  // Méthodes utilitaires privées
  String _generateRandomString(int length) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _generateCodeVerifier() {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }



  void _initializeCredentials(String accessToken, String refreshToken, DateTime expiration) {
    print('Appel de _initializeCredentials avec accessToken: $accessToken, refreshToken: $refreshToken, expiration: $expiration');

    _credentials = SpotifyApiCredentials(
      SpotifyConfig.clientId,
      SpotifyConfig.clientSecret,
      accessToken: accessToken,
      refreshToken: refreshToken,
      scopes: SpotifyConfig.scopes,
      expiration: expiration,
    );

    _spotify = SpotifyApi(_credentials!);
  }
}
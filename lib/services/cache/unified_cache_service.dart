// lib/services/cache/unified_cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify/spotify.dart';
import 'package:beatbox_manager/providers/cache_provider.dart';
import '../../models/magic_set_models.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:spotify/spotify.dart' hide Image; // Cache l'Image de spotify
import 'package:flutter/material.dart' show Image;

class CacheConfig {
  final Duration validityDuration;
  final int maxMemoryItems;
  final bool persistToStorage;

  const CacheConfig({
    this.validityDuration = const Duration(minutes: 30),
    this.maxMemoryItems = 100,
    this.persistToStorage = true,
  });
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final DateTime expiresAt;

  CacheEntry({
    required this.data,
    DateTime? timestamp,
    required Duration validity,
  }) :
        timestamp = timestamp ?? DateTime.now(),
        expiresAt = (timestamp ?? DateTime.now()).add(validity);

  bool get isValid => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}

class UnifiedCacheService {
  static const String _playlistsCacheKey = 'playlists_cache_v2';
  static const String _likedTracksCacheKey = 'liked_tracks_cache_v2';
  static const String _playlistTracksCachePrefix = 'playlist_tracks_v2_';
  static const String _magicSetsCacheKey = 'magic_sets_cache_v1';
  static const String _tagsCacheKey = 'tags_cache_v1';
  static const String _templatesCacheKey = 'templates_cache_v1';

  final CacheConfig config;
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  final SharedPreferences? _prefs;
  bool _isInitialized = false;

  UnifiedCacheService(this._prefs, {
    this.config = const CacheConfig(),
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      if (_prefs != null) {
        await clearExpired();
        _isInitialized = true;
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du cache: $e');
      // Continue même en cas d'erreur
    }
  }

  // Modification de la méthode get pour être plus robuste
  Future<T?> get<T>(String key) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (entry.isValid) return entry.data as T;
        _memoryCache.remove(key);
      }

      if (config.persistToStorage && _prefs != null) {
        final json = _prefs!.getString(key);
        if (json != null) {
          try {
            final data = jsonDecode(json);
            final entry = CacheEntry<T>(
              data: data['data'] as T,
              timestamp: DateTime.parse(data['timestamp']),
              validity: config.validityDuration,
            );

            if (entry.isValid) {
              _memoryCache[key] = entry;
              return entry.data;
            }
            await _prefs!.remove(key);
          } catch (e) {
            print('Erreur de lecture du cache pour $key: $e');
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
    }
    return null;
  }

  Future<void> set<T>(String key, T data) async {
    final entry = CacheEntry<T>(
      data: data,
      validity: config.validityDuration,
    );

    _memoryCache[key] = entry;
    await _cleanMemoryCache();

    if (config.persistToStorage && _prefs != null) {
      await _prefs?.setString(key, jsonEncode(entry.toJson())); // Utiliser l'opérateur ?
    }
  }
  static Future<UnifiedCacheService> create({required CacheConfig config}) async {
    final prefs = await SharedPreferences.getInstance();
    return UnifiedCacheService(prefs, config: config);
  }

  Future<void> _cleanMemoryCache() async {
    if (_memoryCache.length < config.maxMemoryItems) return;

    final entries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final itemsToRemove = (config.maxMemoryItems * 0.2).round();
    for (var i = 0; i < itemsToRemove && i < entries.length; i++) {
      _memoryCache.remove(entries[i].key);
    }
  }

  // On garde les méthodes spécifiques mais on les améliore
  Future<void> cachePlaylists(List<PlaylistSimple> playlists) async {
    final playlistsData = playlists.map((playlist) => {
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'images': playlist.images?.map((image) => {'url': image.url}).toList(),
      'tracksTotal': playlist.tracksLink?.total,
    }).toList();

    await set(_playlistsCacheKey, playlistsData);
  }

  Future<List<PlaylistSimple>?> getCachedPlaylists() async {
    final data = await get<List<dynamic>>(_playlistsCacheKey);
    if (data == null) return null;

    try {
      return data.map((item) => _convertToPlaylist(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Erreur lors de la conversion des playlists: $e');
      return null;
    }
  }

  Future<void> cacheLikedTracks(List<TrackSaved> tracks) async {
    final tracksData = tracks.map((track) => _convertTrackToJson(track.track!)).toList();
    await set(_likedTracksCacheKey, tracksData);
  }

  Future<List<TrackSaved>?> getCachedLikedTracks() async {
    final data = await get<List<dynamic>>(_likedTracksCacheKey);
    if (data == null) return null;

    try {
      return data.map((item) =>
      TrackSaved()..track = _convertToTrack(item as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      print('Erreur lors de la conversion des titres likés: $e');
      return null;
    }
  }
  Future<void> cacheMagicSets(List<MagicSet> sets) async {
    await set(_magicSetsCacheKey, sets.map((s) => s.toJson()).toList());
  }

  Future<List<MagicSet>?> getCachedMagicSets() async {
    final data = await get<List<dynamic>>(_magicSetsCacheKey);
    if (data == null) return null;
    return data.map((json) => MagicSet.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> cacheTags(List<Tag> tags) async {
    await set(_tagsCacheKey, tags.map((t) => t.toJson()).toList());
  }

  Future<List<Tag>?> getCachedTags() async {
    final data = await get<List<dynamic>>(_tagsCacheKey);
    if (data == null) return null;
    return data.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList();
  }
  Future<void> cachePlaylistTracks(String playlistId, List<Track> tracks) async {
    final key = '$_playlistTracksCachePrefix$playlistId';
    final tracksData = tracks.map(_convertTrackToJson).toList();
    await set(key, tracksData);
  }

  Future<List<Track>?> getCachedPlaylistTracks(String playlistId) async {
    final key = '$_playlistTracksCachePrefix$playlistId';
    final data = await get<List<dynamic>>(key);
    if (data == null) return null;

    try {
      return data.map((item) => _convertToTrack(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Erreur lors de la conversion des titres de playlist: $e');
      return null;
    }
  }

  // On garde les méthodes de conversion existantes
  PlaylistSimple _convertToPlaylist(Map<String, dynamic> data) {
    final playlist = PlaylistSimple()
      ..id = data['id']
      ..name = data['name']
      ..description = data['description'];

    if (data['images'] != null) {
      playlist.images = (data['images'] as List).map((img) =>
      spotify.Image()..url = img['url'] as String
      ).toList();
    }

    playlist.tracksLink = spotify.TracksLink()
      ..href = 'spotify:playlist:${data['id']}:tracks'
      ..total = data['tracksTotal'] as int?;

    return playlist;
  }
  Track _convertToTrack(Map<String, dynamic> data) {
    final track = spotify.Track()
      ..id = data['id']
      ..name = data['name'];

    if (data['album'] != null && data['album']['images'] != null) {
      track.album = spotify.Album()
        ..id = data['album']['id']
        ..name = data['album']['name']
        ..images = (data['album']['images'] as List).map((img) =>
        spotify.Image()..url = img['url'] as String
        ).toList();
    }

    return track;
  }


  Map<String, dynamic> _convertTrackToJson(Track track) {
    return {
      'id': track.id,
      'name': track.name,
      'artists': track.artists?.map((artist) => {
        'id': artist.id,
        'name': artist.name,
      }).toList(),
      'album': track.album == null ? null : {
        'id': track.album?.id,
        'name': track.album?.name,
        'images': track.album?.images?.map((image) => {
          'url': image.url,
        }).toList(),
      },
    };
  }

  Future<void> clearCache() async {
    _memoryCache.clear();

    if (config.persistToStorage && _prefs != null) {
      // Utiliser un List.from pour convertir et filtrer
      final playlistTrackKeys = List.from(_prefs!.getKeys())
          .where((key) => key.startsWith(_playlistTracksCachePrefix))
          .toList();

      // Créer une liste de futures pour l'opération de suppression
      final removeFutures = [
        _prefs!.remove(_playlistsCacheKey),
        _prefs!.remove(_likedTracksCacheKey),
        ...playlistTrackKeys.map((key) => _prefs!.remove(key))
      ];

      // Attendre toutes les futures
      await Future.wait(removeFutures.whereType<Future<bool>>());
    }
  }

  Future<void> clearExpired() async {
    final now = DateTime.now();
    _memoryCache.removeWhere((_, entry) => now.isAfter(entry.expiresAt));

    if (config.persistToStorage && _prefs != null) {
      final keys = _prefs?.getKeys().where((key) =>
      key == _playlistsCacheKey ||
          key == _likedTracksCacheKey ||
          key.startsWith(_playlistTracksCachePrefix)
      ) ?? [];

      for (final key in keys) {
        final json = _prefs?.getString(key);
        if (json != null) {
          try {
            final data = jsonDecode(json);
            final expiration = DateTime.parse(data['expiresAt']);
            if (now.isAfter(expiration)) {
              await _prefs?.remove(key);
            }
          } catch (_) {
            await _prefs?.remove(key);
          }
        }
      }
    }
  }

}



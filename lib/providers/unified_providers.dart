import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/spotify/unified_spotify_service.dart';
import '../services/cache/unified_cache_service.dart';
import '../services/navigation_service.dart';
import '../models/magic_set_models.dart';
import '../models/magic_set_models.dart';

// Classes d'état
class LoadingState {
  final int current;
  final int total;
  final String message;

  LoadingState({
    required this.current,
    required this.total,
    required this.message,
  });
}

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final DateTime? lastUpdate;

  const PaginatedState({
    required this.items,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.lastUpdate,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    bool? hasMore,
    DateTime? lastUpdate,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;
}

// Providers de base
final loadingStateProvider = StateNotifierProvider<LoadingStateNotifier, LoadingState?>((ref) {
  return LoadingStateNotifier();
});

final cacheServiceProvider = FutureProvider<UnifiedCacheService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final config = CacheConfig(
    validityDuration: const Duration(minutes: 30),
    maxMemoryItems: 100,
    persistToStorage: true,
  );
  return UnifiedCacheService(prefs, config: config);
});
final tagsProvider = StateNotifierProvider<TagsNotifier, AsyncValue<List<Tag>>>((ref) {
  final cacheServiceAsync = ref.watch(cacheServiceProvider);

  return cacheServiceAsync.when(
    data: (cacheService) => TagsNotifier(cacheService),
    loading: () => TagsNotifier(UnifiedCacheService(null)),
    error: (_, __) => TagsNotifier(UnifiedCacheService(null)),
  );
});

final spotifyServiceProvider = Provider<UnifiedSpotifyService>((ref) {
  final cacheServiceAsync = ref.watch(cacheServiceProvider);

  return cacheServiceAsync.when(
    data: (cacheService) => UnifiedSpotifyService(cacheService),
    loading: () => UnifiedSpotifyService(UnifiedCacheService(null)),
    error: (_, __) => UnifiedSpotifyService(UnifiedCacheService(null)),
  );
});
final spotifyTrackProvider = FutureProvider.family<Track, String>((ref, trackId) async {
  final spotifyService = ref.watch(spotifyServiceProvider);
  return await spotifyService.getTrack(trackId);
});

// Providers d'authentification et navigation
final navigationServiceProvider = Provider<NavigationService>((ref) => NavigationService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UnifiedSpotifyService>>((ref) {
  return AuthNotifier(ref);
});

// Providers de données
final playlistsProvider = StateNotifierProvider<PlaylistNotifier, PaginatedState<PlaylistSimple>>((ref) {
  final spotifyService = ref.watch(spotifyServiceProvider);
  final cacheServiceAsync = ref.watch(cacheServiceProvider);

  return cacheServiceAsync.when(
    data: (cacheService) => PlaylistNotifier(
      spotifyService: spotifyService,
      cacheService: cacheService,
    ),
    loading: () => throw Exception('Cache service not initialized'),
    error: (error, _) => throw Exception('Failed to initialize cache service: $error'),
  );
});

final likedTracksProvider = StateNotifierProvider<LikedTracksNotifier, PaginatedState<TrackSaved>>((ref) {
  final spotifyService = ref.watch(spotifyServiceProvider);
  final cacheServiceAsync = ref.watch(cacheServiceProvider);

  return cacheServiceAsync.when(
    data: (cacheService) => LikedTracksNotifier(
      spotifyService: spotifyService,
      cacheService: cacheService,
    ),
    loading: () => throw Exception('Cache service not initialized'),
    error: (error, _) => throw Exception('Failed to initialize cache service: $error'),
  );
});

// Notifiers
class LoadingStateNotifier extends StateNotifier<LoadingState?> {
  LoadingStateNotifier() : super(null);

  void updateProgress(int current, int total, String message) {
    state = LoadingState(
      current: current,
      total: total,
      message: message,
    );
  }

  void reset() => state = null;
}
abstract class PaginatedDataNotifier<T> extends StateNotifier<PaginatedState<T>> {
  final UnifiedSpotifyService spotifyService;
  final UnifiedCacheService cacheService;
  final int pageSize;

  PaginatedDataNotifier({
    required this.spotifyService,
    required this.cacheService,
    this.pageSize = 50,
  }) : super(PaginatedState<T>(items: []));

  Future<List<T>> fetchPage(int offset, int limit);
  Future<List<T>?> getCachedData();
  Future<void> cacheData(List<T> data);
  String get cacheKey;

  Future<void> initialize() async {
    if (state.items.isNotEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      final cachedData = await getCachedData();
      if (cachedData != null && cachedData.isNotEmpty) {
        state = state.copyWith(
          items: cachedData,
          isLoading: false,
          hasMore: cachedData.length >= pageSize,
          lastUpdate: DateTime.now(),
        );
        _refreshInBackground();
        return;
      }

      await loadMore(refresh: true);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur d\'initialisation: $e',
        isLoading: false,
      );
    }
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading || (!state.hasMore && !refresh)) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = refresh ? 0 : state.items.length;
      final newItems = await fetchPage(offset, pageSize);
      final updatedItems = refresh ? newItems : [...state.items, ...newItems];

      await cacheData(updatedItems);

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
        hasMore: newItems.length >= pageSize,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur de chargement: $e',
        isLoading: false,
      );
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final freshData = await fetchPage(0, state.items.length);
      if (!mounted) return;

      await cacheData(freshData);
      state = state.copyWith(
        items: freshData,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      print('Erreur de rafraîchissement en arrière-plan: $e');
    }
  }
}




class LikedTracksNotifier extends PaginatedDataNotifier<TrackSaved> {
  LikedTracksNotifier({
    required UnifiedSpotifyService spotifyService,
    required UnifiedCacheService cacheService,
  }) : super(
    spotifyService: spotifyService,
    cacheService: cacheService,
  );

  @override
  String get cacheKey => 'liked_tracks';

  @override
  Future<List<TrackSaved>> fetchPage(int offset, int limit) async {
    return await spotifyService.fetchLikedTracks(
      forceRefresh: offset == 0,
    );
  }

  @override
  Future<List<TrackSaved>?> getCachedData() async {
    return await cacheService.getCachedLikedTracks();
  }

  @override
  Future<void> cacheData(List<TrackSaved> data) async {
    await cacheService.cacheLikedTracks(data);
  }
  Future<void> refresh({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final tracks = await spotifyService.fetchLikedTracks(forceRefresh: forceRefresh);
      state = state.copyWith(
        items: tracks,
        isLoading: false,
        hasMore: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur de rafraîchissement: $e',
        isLoading: false,
      );
    }
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<UnifiedSpotifyService>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    initialize();
  }

  Future<void> initialize() async {
    try {
      final cacheService = await _ref.read(cacheServiceProvider.future);
      final spotifyService = UnifiedSpotifyService(cacheService);
      await spotifyService.init();

      if (spotifyService.isConnected) {
        state = AsyncValue.data(spotifyService);
      } else {
        state = const AsyncValue.error("Pas de session valide", StackTrace.empty);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> login() async {
    try {
      state = const AsyncValue.loading();
      final spotifyService = _ref.read(spotifyServiceProvider);
      await spotifyService.login();
      state = AsyncValue.data(spotifyService);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> handleAuthResponse(Uri uri) async {
    try {
      final spotifyService = _ref.read(spotifyServiceProvider);
      await spotifyService.handleAuthResponse(uri);

      if (spotifyService.isConnected) {
        state = AsyncValue.data(spotifyService);
        _ref.read(navigationServiceProvider).goToHello();
      } else {
        throw Exception('Échec de connexion après traitement du token');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      _ref.read(navigationServiceProvider).goToHome();
    }
  }

  Future<void> logout() async {
    try {
      final spotifyService = state.valueOrNull;
      if (spotifyService != null) {
        await spotifyService.logout();
      }
      state = const AsyncValue.loading();
      _ref.read(navigationServiceProvider).goToHome();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}


// Provider d'état utilisateur
class UserStateNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      final spotifyService = ref.read(spotifyServiceProvider);
      return await spotifyService.fetchAccountData();
    } catch (e) {
      print('UserStateNotifier: Erreur de récupération - $e');
      return {'error': 'Erreur lors de la récupération des données utilisateur: ${e.toString()}'};
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchUserData);
  }
}



final userStateProvider = AsyncNotifierProvider<UserStateNotifier, Map<String, dynamic>>(
    UserStateNotifier.new
);

class PlaylistNotifier extends PaginatedDataNotifier<PlaylistSimple> {
  PlaylistNotifier({
    required UnifiedSpotifyService spotifyService,
    required UnifiedCacheService cacheService,
  }) : super(
    spotifyService: spotifyService,
    cacheService: cacheService,
  );

  @override
  String get cacheKey => 'playlists_cache';

  @override
  Future<List<PlaylistSimple>> fetchPage(int offset, int limit) async {
    return await spotifyService.fetchUserPlaylists(
      forceRefresh: offset == 0,
    );
  }

  @override
  Future<List<PlaylistSimple>?> getCachedData() async {
    return await cacheService.getCachedPlaylists();
  }

  @override
  Future<void> cacheData(List<PlaylistSimple> data) async {
    await cacheService.cachePlaylists(data);
  }
  Future<void> refresh({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final playlists = await spotifyService.fetchUserPlaylists(forceRefresh: forceRefresh);
      state = state.copyWith(
        items: playlists,
        isLoading: false,
        hasMore: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur de rafraîchissement: $e',
        isLoading: false,
      );
    }
  }
}




final combinedDataProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final account = ref.watch(userStateProvider);
  final playlists = ref.watch(playlistsProvider);
  final likedTracks = ref.watch(likedTracksProvider);

  // Fonction utilitaire pour gérer les erreurs
  AsyncValue<Map<String, dynamic>> handleErrors() {
    if (account.hasError) {
      return AsyncValue.error(
          'Erreur lors de la récupération des données utilisateur',
          account.stackTrace ?? StackTrace.current
      );
    }

    if (playlists.error != null) {
      return AsyncValue.error(
          'Erreur lors de la récupération des playlists',
          StackTrace.current
      );
    }

    if (likedTracks.error != null) {
      return AsyncValue.error(
          'Erreur lors de la récupération des titres likés',
          StackTrace.current
      );
    }

    return AsyncValue.data({});
  }

  // Vérification des erreurs
  final errorCheck = handleErrors();
  if (errorCheck is AsyncError) return errorCheck;

  // Préparation des données
  final combinedData = {
    'account': {
      'userName': account.valueOrNull?['userName'] ?? 'Utilisateur',
      'images': account.valueOrNull?['images'] ?? [],  // Ajout des images
      'displayName': account.valueOrNull?['displayName'], // Ajout du nom affiché
    },
    'playlists': playlists.items,
    'likedTracks': likedTracks.items,
    'lastUpdate': DateTime.now().toIso8601String(),
    'playlistsCount': playlists.items.length,
    'likedTracksCount': likedTracks.items.length,
  };

  // Gestion des états de chargement
  final isLoading =
      account.isLoading ||
          playlists.isLoading ||
          likedTracks.isLoading;

  // Retour final
  return isLoading
      ? AsyncValue.loading()
      : AsyncValue.data(combinedData);
});



final likedTracksStateProvider = StateNotifierProvider<LikedTracksStateNotifier, AsyncValue<List<TrackSaved>>>((ref) {
  final spotifyService = ref.watch(spotifyServiceProvider);
  final cacheServiceAsync = ref.watch(cacheServiceProvider);
  final loadingNotifier = ref.watch(loadingStateProvider.notifier);

  return cacheServiceAsync.when(
      data: (cacheService) => LikedTracksStateNotifier(
        spotifyService,
        cacheService,
        loadingNotifier,
      )..initialize(),
      loading: () => throw Exception('Cache service not initialized'),
      error: (error, stack) => throw Exception('Failed to initialize cache service: $error')
  );
});





class LikedTracksStateNotifier extends StateNotifier<AsyncValue<List<TrackSaved>>> {
  final UnifiedSpotifyService _service;
  final UnifiedCacheService _cache;
  final LoadingStateNotifier _loadingNotifier;
  bool _isLoading = false;
  List<TrackSaved>? _cachedTracks;

  LikedTracksStateNotifier(this._service, this._cache, this._loadingNotifier)
      : super(const AsyncValue.loading());

  Future<void> initialize() async {
    // Si nous avons déjà des données en cache mémoire, les utiliser
    if (_cachedTracks != null) {
      state = AsyncValue.data(_cachedTracks!);
      return;
    }
    await _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      // Garder l'état précédent pendant le chargement
      final previousState = state;
      state = const AsyncValue.loading();

      // Essayer d'abord le cache local
      final cached = await _cache.getCachedLikedTracks();
      if (cached != null && cached.isNotEmpty) {
        _cachedTracks = cached;
        state = AsyncValue.data(cached);

        // Charger les données fraîches en arrière-plan
        _loadFreshData();
        return;
      }

      await _loadFreshData();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoading = false;
      _loadingNotifier.reset();
    }
  }

  Future<void> _loadFreshData() async {
    try {
      final tracks = await _service.fetchLikedTracks();
      _cachedTracks = tracks;
      if (mounted) {
        state = AsyncValue.data(tracks);
        await _cache.cacheLikedTracks(tracks);
      }
    } catch (e, stack) {
      if (mounted && _cachedTracks == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> refresh() async {
    _cachedTracks = null;
    await _loadInitial();
  }

  @override
  void dispose() {
    _cachedTracks = null;
    super.dispose();
  }
}









class PlaylistTracksNotifier extends StateNotifier<AsyncValue<List<Track>>> {
  final UnifiedSpotifyService _service;
  final UnifiedCacheService _cache;
  final LoadingStateNotifier _loadingNotifier;
  final String playlistId;

  static const int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  List<Track>? _cachedTracks;

  PlaylistTracksNotifier(this._service, this._cache, this._loadingNotifier, this.playlistId)
      : super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final cached = await _cache.getCachedPlaylistTracks(playlistId);
      if (cached != null) {
        _cachedTracks = cached;
        state = AsyncValue.data(cached);
        _currentOffset = cached.length;
        _hasMore = false;
        return;
      }

      await _loadPage();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoading = false;
      _loadingNotifier.reset();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage() async {
    _isLoading = true;
    _loadingNotifier.updateProgress(_currentOffset, -1, 'Chargement des titres...');

    try {
      final tracks = await _service.spotify!.playlists
          .getTracksByPlaylistId(playlistId)
          .getPage(_pageSize, _currentOffset);

      final newTracks = tracks.items
          ?.whereType<Track>()
          .toList() ?? [];

      _hasMore = newTracks.length >= _pageSize;

      final List<Track> updatedTracks = [...(state.valueOrNull ?? []), ...newTracks];
      _cachedTracks = updatedTracks;
      state = AsyncValue.data(updatedTracks);
      _currentOffset += newTracks.length;

      if (!_hasMore) {
        await _cache.cachePlaylistTracks(playlistId, _cachedTracks!);
      }
    } catch (e, stack) {
      if (_cachedTracks == null) {
        state = AsyncValue.error(e, stack);
      }
    } finally {
      _isLoading = false;
      _loadingNotifier.reset();
    }
  }


  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMore = true;
    _cachedTracks = null;
    await loadInitial();
  }

  @override
  void dispose() {
    _cachedTracks = null;
    super.dispose();
  }
}
class TagsNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final UnifiedCacheService _cacheService;
  static const String _cacheKey = 'tags_cache';

  TagsNotifier(this._cacheService) : super(const AsyncValue.loading()) {
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final cached = await _cacheService.get<List<dynamic>>(_cacheKey);
      final tags = cached?.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList() ?? [];
      state = AsyncValue.data(tags);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTag(Tag tag) async {
    try {
      state.whenData((tags) async {
        final updatedTags = [...tags, tag];
        state = AsyncValue.data(updatedTags);
        await _saveTags(updatedTags);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTag(Tag updatedTag) async {
    try {
      state.whenData((tags) async {
        final updatedTags = tags.map((tag) =>
        tag.id == updatedTag.id ? updatedTag : tag
        ).toList();
        state = AsyncValue.data(updatedTags);
        await _saveTags(updatedTags);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTag(String tagId) async {
    try {
      state.whenData((tags) async {
        final updatedTags = tags.where((tag) => tag.id != tagId).toList();
        state = AsyncValue.data(updatedTags);
        await _saveTags(updatedTags);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _saveTags(List<Tag> tags) async {
    try {
      await _cacheService.set(
        _cacheKey,
        tags.map((tag) => tag.toJson()).toList(),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde des tags: $e');
    }
  }
}
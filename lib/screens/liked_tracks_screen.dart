import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import '../theme/app_theme.dart';
import '../widgets/unified_widgets.dart';
import '../utils/unified_utils.dart';
import '../providers/unified_providers.dart';
import '../services/navigation_service.dart';
import 'package:beatbox_manager/services/cache/unified_cache_service.dart';
import 'package:beatbox_manager/services/spotify/unified_spotify_service.dart';
import 'package:beatbox_manager/screens/playlist_tracks_screen.dart';

class LikedTracksScreen extends ConsumerStatefulWidget {
  const LikedTracksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LikedTracksScreen> createState() => _LikedTracksScreenState();
}

class _LikedTracksScreenState extends ConsumerState<LikedTracksScreen> {
  final ScrollController _scrollController = ScrollController();
  late PaginationManager<TrackSaved> _paginationManager;
  double _headerOpacity = 1.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      initPaginationManager();
      _isInitialized = true;
    }
  }

  void initPaginationManager() {
    final likedTracks = ref.read(likedTracksStateProvider);
    final cacheServiceAsync = ref.read(cacheServiceProvider);
    final spotifyService = ref.read(spotifyServiceProvider);

    _paginationManager = PaginationManager<TrackSaved>(
      config: const PaginationConfig(
        initialPageSize: 50,
        subsequentPageSize: 50,
        maxRetries: 3,
        retryDelay: Duration(seconds: 1),
      ),
      fetchData: (offset, {int? limit}) async {
        limit ??= 50;

        // Utilisation de when pour gérer l'AsyncValue du cacheService
        final cacheService = await cacheServiceAsync.when(
          data: (service) => service,
          loading: () => throw Exception('Cache service not initialized'),
          error: (error, _) => throw Exception('Cache service error: $error'),
        );

        if (!spotifyService.isConnected) {
          throw Exception('Service Spotify non connecté');
        }

        // Le reste de votre code reste identique
        if (offset == 0) {
          final cached = await cacheService.getCachedLikedTracks();
          if (cached != null) return cached;
        }

        try {
          if (likedTracks.hasValue && offset < likedTracks.value!.length) {
            final endIndex = offset + limit;
            final availableTracks = likedTracks.value!;
            final actualEndIndex = endIndex > availableTracks.length
                ? availableTracks.length
                : endIndex;

            return availableTracks.sublist(offset, actualEndIndex);
          }

          final tracksPage = await spotifyService.spotify!.tracks.me.saved
              .getPage(limit, offset);

          final tracks = tracksPage.items?.map((item) {
            if (item is TrackSaved) return item;
            return TrackSaved()..track = item as Track;
          }).toList() ?? [];

          if (offset == 0) {
            await cacheService.cacheLikedTracks(tracks);
          }

          return tracks;
        } catch (e) {
          print('Erreur de pagination des titres likés: $e');
          if (e.toString().contains('Invalid limit') && limit > 20) {
            return await spotifyService.spotify!.tracks.me.saved
                .getPage(20, offset)
                .then((tracksPage) => tracksPage.items?.map((item) {
              if (item is TrackSaved) return item;
              return TrackSaved()..track = item as Track;
            }).toList() ?? []);
          }
          rethrow;
        }
      },
    );

    if (likedTracks.hasValue && likedTracks.value!.isNotEmpty) {
      _paginationManager.setInitialData(likedTracks.value!);
    } else {
      _paginationManager.loadInitial();
    }
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (!mounted) return;

      setState(() {
        _headerOpacity = (1 - (_scrollController.offset / 200)).clamp(0.0, 1.0);
      });

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _paginationManager.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _paginationManager,
            builder: (context, child) {
              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [_buildHeader()];
                },
                body: _buildBody(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          ref.read(navigationServiceProvider).goToHello();
        },
        tooltip: 'Retour',
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Titres Likés',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Opacity(
          opacity: _headerOpacity,
          child: Container(
            decoration: AppTheme.gradientBackground,
            child: Center(
              child: Text(
                '${_paginationManager.items.length} titres',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _paginationManager.refresh,
          tooltip: 'Rafraîchir',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_paginationManager.isEmpty && _paginationManager.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.spotifyGreen),
      );
    }

    if (_paginationManager.error != null && _paginationManager.isEmpty) {
      return _buildErrorState(_paginationManager.error!);
    }

    if (_paginationManager.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _paginationManager.refresh(),
      color: AppTheme.spotifyGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _paginationManager.items.length + (_paginationManager.hasMoreItems ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _paginationManager.items.length) {
            return _buildLoadingIndicator();
          }
          return _buildTrackItem(_paginationManager.items[index]);
        },
      ),
    );
  }

  Widget _buildTrackItem(TrackSaved trackSaved) {
    final track = trackSaved.track!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          child: OptimizedNetworkImage(
            imageUrl: track.album?.images?.isNotEmpty == true
                ? track.album!.images!.first.url
                : null,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(4),
          ),
        ),  // J'ai ajouté la virgule manquante ici
        title: Text(
          track.name ?? 'Sans titre',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.artists?.map((a) => a.name).join(', ') ?? 'Artiste inconnu',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (track.album?.name != null)
              Text(
                track.album!.name!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(
          Icons.favorite,
          color: AppTheme.spotifyGreen,
          size: 20,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lecture de : ${track.name}'),
              duration: const Duration(seconds: 1),
              backgroundColor: AppTheme.spotifyGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppTheme.spotifyGreen,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun titre liké',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _paginationManager.refresh,
            child: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur: $error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Utilisez le NavigationService pour gérer l'erreur
              ref.read(navigationServiceProvider).goToHello();
            },
            child: const Text('Retourner à l\'accueil'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _paginationManager.refresh,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
class LikedTracksStateNotifier extends StateNotifier<AsyncValue<List<TrackSaved>>> {
  final UnifiedSpotifyService _service;
  final UnifiedCacheService _cache;
  final LoadingStateNotifier _loadingNotifier;
  bool _isLoading = false;
  List<TrackSaved>? _cachedTracks;

  LikedTracksStateNotifier(
      this._service,
      this._cache,
      this._loadingNotifier,
      ) : super(const AsyncValue.loading());

  Future<void> initialize() async {
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
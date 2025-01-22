import 'playlist_tracks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import '../theme/app_theme.dart';
import '../widgets/unified_widgets.dart';
import '../providers/unified_providers.dart';
import '../services/navigation_service.dart';
import 'package:beatbox_manager/utils/unified_utils.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  late PaginationManager<PlaylistSimple> _paginationManager;
  double _headerOpacity = 1.0;


  @override
  void initState() {
    super.initState();
    _setupScrollController();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        final playlistState = ref.read(playlistsProvider);
        // Utilisez directement loadMore du provider
        if (!playlistState.isLoading) {
          ref.read(playlistsProvider.notifier).loadMore();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initPaginationManager();
      _isInitialized = true;
    }
  }

  void _initPaginationManager() {
    final cacheServiceAsync = ref.read(cacheServiceProvider);
    final spotifyService = ref.read(spotifyServiceProvider);

    _paginationManager = PaginationManager<PlaylistSimple>(
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

        // Vérifier d'abord le cache local
        if (offset == 0) {
          final cached = await cacheService.getCachedPlaylists();
          if (cached != null) return cached;
        }

        try {
          final page = await spotifyService.spotify!.playlists.me.getPage(limit, offset);
          final items = page.items?.toList() ?? [];

          // Mettre en cache uniquement la première page
          if (offset == 0) {
            await cacheService.cachePlaylists(items);
          }

          return items;
        } catch (e) {
          print('Erreur de pagination des playlists: $e');
          rethrow;
        }
      },
    );

    _paginationManager.loadInitial();
  }



  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistsProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(playlistsProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Utiliser la longueur des items
                _buildHeader(playlistState.items.length),

                // Modification du _buildContent
                _buildContent(playlistState),

                if (playlistState.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.spotifyGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildContent(PaginatedState<PlaylistSimple> state) {
    // Gestion des états basée sur PaginatedState
    if (state.error != null) {
      return SliverFillRemaining(
        child: _buildErrorState(state.error!),
      );
    }

    if (state.items.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPlaylistCard(state.items[index]),
        childCount: state.items.length,
      ),
    );
  }

  Widget _buildHeader(int playlistCount) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Mes Playlists',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Opacity(
          opacity: _headerOpacity,
          child: Container(
            decoration: AppTheme.gradientBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  '$playlistCount playlists',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(playlistsProvider.notifier).refresh(),
          tooltip: 'Rafraîchir',
        ),
      ],
    );
  }

  Widget _buildPlaylistCard(PlaylistSimple playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardGradient,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(navigationServiceProvider).goToPlaylistTracks(playlist),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OptimizedNetworkImage(
                  imageUrl: playlist.images?.firstOrNull?.url,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name ?? 'Sans titre',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (playlist.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          playlist.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune playlist trouvée',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(playlistsProvider.notifier).refresh(),
            child: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              onPressed: () => ref.read(playlistsProvider.notifier).refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
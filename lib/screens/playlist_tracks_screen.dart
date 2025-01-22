import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import '../theme/app_theme.dart';
import '../widgets/unified_widgets.dart';
import '../providers/unified_providers.dart';
import '../utils/unified_utils.dart';
import 'dart:ui' as ui;
import '../services/navigation_service.dart';

class PlaylistTracksScreen extends ConsumerStatefulWidget {
  final PlaylistSimple playlist;

  const PlaylistTracksScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  ConsumerState<PlaylistTracksScreen> createState() => _PlaylistTracksScreenState();
}

class _PlaylistTracksScreenState extends ConsumerState<PlaylistTracksScreen> {
  final ScrollController _scrollController = ScrollController();
  late PaginationManager<Track> _paginationManager;
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
      _initPaginationManager();
      _isInitialized = true;
    }
  }

  void _initPaginationManager() {
    final cacheServiceAsync = ref.read(cacheServiceProvider);
    final spotifyService = ref.read(spotifyServiceProvider);

    _paginationManager = PaginationManager<Track>(
      config: const PaginationConfig(
        initialPageSize: 50,
        subsequentPageSize: 50,
        maxRetries: 3,
        retryDelay: Duration(seconds: 1),
      ),
      fetchData: (offset, {int? limit}) async {
        limit = limit ?? 50;

        // Attendre la résolution du cacheService
        final cacheService = await cacheServiceAsync.when(
          data: (service) => service,
          loading: () => throw Exception('Cache service not initialized'),
          error: (error, _) => throw Exception('Cache service error: $error'),
        );

        if (!spotifyService.isConnected) {
          throw Exception('Service Spotify non connecté');
        }

        // Vérification du cache pour la première page
        if (offset == 0) {
          final cached = await cacheService.getCachedPlaylistTracks(
              widget.playlist.id!);
          if (cached != null) return cached;
        }

        try {
          // Le reste de votre code reste identique
          final playlistTracks = await spotifyService.spotify!.playlists
              .getTracksByPlaylistId(widget.playlist.id!)
              .getPage(limit, offset);

          final tracks = playlistTracks.items
              ?.whereType<Track>()
              .map((track) => track)
              .toList() ?? [];

          if (offset == 0) {
            await cacheService.cachePlaylistTracks(widget.playlist.id!, tracks);
          }

          return tracks;
        } catch (e) {
          print('Erreur de pagination: $e');
          if (e.toString().contains('Invalid limit') && (limit ?? 50) > 20) {
            final playlistTracks = await spotifyService.spotify!.playlists
                .getTracksByPlaylistId(widget.playlist.id!)
                .getPage(20, offset);

            final tracks = playlistTracks.items
                ?.whereType<Track>()
                .map((track) => track)
                .toList() ?? [];

            return tracks;
          }
          rethrow;
        }
      },
    );

    _paginationManager.loadInitial();
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

  Future<void> _handleRefresh() async {
    _paginationManager.refresh();
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
            builder: (context, child) =>
                RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppTheme.spotifyGreen,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildHeader(),
                      if (_paginationManager.isEmpty &&
                          _paginationManager.isLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme
                                .spotifyGreen),
                          ),
                        )
                      else
                        if (_paginationManager.error != null &&
                            _paginationManager.isEmpty)
                          SliverFillRemaining(
                            child: _buildErrorState(_paginationManager.error!),
                          )
                        else
                          if (_paginationManager.isEmpty)
                            SliverFillRemaining(
                              child: _buildEmptyState(),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                    if (index >=
                                        _paginationManager.items.length) {
                                      if (_paginationManager.hasMoreItems) {
                                        return _buildLoadingIndicator();
                                      }
                                      return null;
                                    }
                                    return _buildTrackItem(
                                        _paginationManager.items[index], index);
                                  },
                                  childCount: _paginationManager.items.length +
                                      (_paginationManager.hasMoreItems ? 1 : 0),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
          ),
        ),
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

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          ref.read(navigationServiceProvider).goToPlaylists();
        },
        tooltip: 'Retour',
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Opacity(
          opacity: _headerOpacity,
          child: Container(
            decoration: AppTheme.gradientBackground,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'playlist-image-${widget.playlist.id}',
                  child: Container(
                    width: 160,
                    height: 160,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20.0,
                          offset: ui.Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: OptimizedNetworkImage(
                      imageUrl: widget.playlist.images?.isNotEmpty == true
                          ? widget.playlist.images!.first.url
                          : null,
                      width: 160,
                      height: 160,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        widget.playlist.name ?? 'Sans titre',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.playlist.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.playlist.description!,
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _handleRefresh,
          tooltip: 'Rafraîchir',
        ),
      ],
    );
  }

  Widget _buildTracksList(List<Track> tracks) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTrackItem(tracks[index], index),
        childCount: tracks.length,
      ),
    );
  }

  Widget _buildTrackItem(Track track, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox( // Ajout d'un SizedBox pour contraindre la taille
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
        ),
        title: Text(
          track.name ?? 'Sans titre',
          style: Theme
              .of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
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
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (track.album?.name != null)
              Text(
                track.album!.name!,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun titre dans cette playlist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: const Text('Rafraîchir'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              ref.read(navigationServiceProvider).goToPlaylists();
            },
            child: const Text('Retour aux playlists'),
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
              color: Theme
                  .of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur: $error',
              style: TextStyle(
                color: Theme
                    .of(context)
                    .colorScheme
                    .error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Réessayer'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ref.read(navigationServiceProvider).goToPlaylists();
              },
              child: const Text('Retour aux playlists'),
            ),
          ],
        ),
      ),
    );
  }
}
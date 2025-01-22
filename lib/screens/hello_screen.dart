import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart' as spotify;
import '../theme/app_theme.dart';
import '../providers/unified_providers.dart';
import 'package:spotify/spotify.dart' show PlaylistSimple, TrackSaved;
import '../services/navigation_service.dart';
import '../widgets/unified_widgets.dart';



class HelloScreen extends ConsumerStatefulWidget {
  const HelloScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HelloScreen> createState() => _HelloScreenState();
}
class _HelloScreenState extends ConsumerState<HelloScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final authState = ref.read(authStateProvider);
      final spotifyService = ref.read(spotifyServiceProvider);

      // Vérifier l'état d'authentification
      if (!await spotifyService.checkTokenValidity()) {
        if (mounted) {
          ref.read(navigationServiceProvider).goToHome();
          return;
        }
      }

      // Initialiser les données
      await _refreshAll(context, ref);  // Ajoutez context ici

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur d\'initialisation HelloScreen: $e');
      if (mounted) {
        ref.read(navigationServiceProvider).goToHome();
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final combinedData = ref.watch(combinedDataProvider);
    return Scaffold(
      body: combinedData.when(
        data: (data) => _buildSuccessView(context, ref, data),
        loading: () => const LoadingIndicator(
          message: 'Chargement des données...',
        ),
        error: (error, stack) => ErrorDisplay(
          message: "Erreur de chargement: ${error.toString()}",
          onRetry: () {
            ref.refresh(authStateProvider);
            ref.refresh(combinedDataProvider);
          },
          onBack: () => ref.read(navigationServiceProvider).goToHome(),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    return Container(
      decoration: AppTheme.gradientBackground,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, ref, data['account']),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsCard(context, data),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, ref),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Widget _buildAppBar(BuildContext context, WidgetRef ref, Map<String, dynamic> accountData) {
  final userName = accountData['userName'] ?? 'Utilisateur';
  final userImage = accountData['images']?.first?['url'];

  return SliverAppBar(
    expandedHeight: 200,
    floating: false,
    pinned: true,
    flexibleSpace: FlexibleSpaceBar(
      title: Text(
        'Bienvenue $userName 👋',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
        ),
      ),
      background: Stack(
        children: [
          Container(decoration: AppTheme.gradientBackground),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: userImage != null ? NetworkImage(userImage) : null,
                  child: userImage == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => _refreshAll(context, ref, forceRefresh: true),
        tooltip: 'Forcer le rafraîchissement',
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => _handleLogout(context, ref),
        tooltip: 'Déconnexion',
      ),
    ],
  );
}


Widget _buildStatsCard(BuildContext context, Map<String, dynamic> data) {
  final playlistsCount = data['playlistsCount'] ?? 0;
  final likedTracksCount = data['likedTracksCount'] ?? 0;
  final lastUpdate = DateTime.now().toString().substring(11, 16);

  return Container(
    decoration: AppTheme.cardGradient,
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Votre Bibliothèque',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            Text(
              'Mis à jour $lastUpdate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.playlist_play,
                label: 'Playlists',
                value: playlistsCount,
                isLoading: false,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.favorite,
                label: 'Titres likés',
                value: likedTracksCount,
                iconColor: Colors.red[400],
                isLoading: false,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatItem(
    BuildContext context, {
      required IconData icon,
      required String label,
      required int value,
      Color? iconColor,
      bool isLoading = false,  // Ajout d'une valeur par défaut
    }) {
  return Column(
    children: [
      Icon(
        icon,
        size: 40,
        color: isLoading
            ? Colors.grey.withOpacity(0.5)
            : (iconColor ?? AppTheme.spotifyGreen),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      if (isLoading)
        const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.spotifyGreen,
          ),
        )
      else
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.spotifyGreen,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
    ],
  );
}

  // Dans la méthode _buildActionButtons()
Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Bouton Playlists
      ElevatedButton.icon(
        onPressed: () => ref.read(navigationServiceProvider).goToPlaylists(),
        icon: const Icon(Icons.playlist_play),
        label: const Text('Voir mes playlists'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.spotifyGreen, // Couleur de fond
          foregroundColor: Colors.white, // Couleur du texte en blanc
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Coins arrondis
          ),
        ),
      ),

      const SizedBox(height: 12),

      // Bouton Titres likés
      OutlinedButton.icon(
        onPressed: () => ref.read(navigationServiceProvider).goToLikedTracks(),
        icon: const Icon(Icons.favorite),
        label: const Text('Voir mes titres likés'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppTheme.spotifyGreen, width: 2),
          foregroundColor: AppTheme.spotifyGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      const SizedBox(height: 12),

    ],
  );
}

  Widget _buildErrorState({
    required BuildContext context,
    required String error,
    required WidgetRef ref,
  }) {
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
            'Erreur : $error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshAll(context, ref),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

Future<void> _refreshAll(BuildContext context, WidgetRef ref, {bool forceRefresh = false}) async {
  try {
    await Future.wait([
      ref.read(userStateProvider.notifier).refresh(),
      ref.read(playlistsProvider.notifier).refresh(forceRefresh: forceRefresh),
      ref.read(likedTracksProvider.notifier).refresh(forceRefresh: forceRefresh),
    ]);
  } catch (e) {
    print('Erreur lors du rafraîchissement: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur lors du rafraîchissement des données'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  await ref.read(authStateProvider.notifier).logout();
  ref.read(navigationServiceProvider).goToHome();
}

  void _navigateToPlaylists(BuildContext context, WidgetRef ref) {
    ref.read(playlistsProvider.notifier).refresh();
    ref.read(navigationServiceProvider).goToPlaylists();
  }

  void _navigateToLikedTracks(BuildContext context, WidgetRef ref) {
    ref.read(likedTracksStateProvider.notifier).refresh();
    ref.read(navigationServiceProvider).goToLikedTracks();
  }
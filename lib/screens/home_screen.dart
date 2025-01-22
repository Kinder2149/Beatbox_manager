import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/unified_providers.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Attendre que le widget soit complètement monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }
  Future<void> _initializeAuth() async {
    try {
      final spotifyService = ref.read(spotifyServiceProvider);
      final authNotifier = ref.read(authStateProvider.notifier);

      // Vérifier si un token valide existe
      if (await spotifyService.checkTokenValidity()) {
        if (mounted) {
          ref.read(navigationServiceProvider).goToHello();
        }
      }
    } catch (e) {
      print('Erreur d\'initialisation: $e');
      // Ne rien faire, laisser l'utilisateur sur l'écran de connexion
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'BeatBox Manager',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                if (isAuthenticating)
                  const CircularProgressIndicator(color: AppTheme.spotifyGreen)
                else
                  Column(
                    children: [
                      // Bouton nouvelle connexion
                      ElevatedButton.icon(
                        onPressed: () => handleLogin(forceNew: true),
                        icon: const Icon(Icons.add, color: Colors.white), // Couleur de l'icône
                        label: const Text('Nouvelle connexion', style: TextStyle(color: Colors.white)), // Couleur du texte
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.spotifyGreen, // Couleur de fond
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Bouton reprendre session
                      OutlinedButton.icon(
                        onPressed: () => handleLogin(forceNew: false),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reprendre dernière session'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.spotifyGreen,
                          side: const BorderSide(color: AppTheme.spotifyGreen),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleLogin({bool forceNew = false}) async {
    if (isAuthenticating) return;

    setState(() {
      isAuthenticating = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final spotifyService = ref.read(spotifyServiceProvider);

      if (forceNew) {
        await spotifyService.clearCredentials();
        await authNotifier.login();
      } else {
        // Vérifier d'abord si les tokens sont valides
        if (await spotifyService.checkTokenValidity()) {
          // Token valide, forcer un rafraîchissement des données
          await ref.read(userStateProvider.notifier).refresh();
          await ref.read(playlistsProvider.notifier).refresh();
          await ref.read(likedTracksProvider.notifier).refresh();

          if (mounted) {
            ref.read(navigationServiceProvider).goToHello();
          }
        } else {
          // Token invalide, essayer de le rafraîchir
          try {
            await spotifyService.refreshCredentials();
            if (mounted) {
              ref.read(navigationServiceProvider).goToHello();
            }
          } catch (e) {
            print('Erreur lors du rafraîchissement: $e');
            // Si échec du rafraîchissement, faire une nouvelle connexion
            await spotifyService.clearCredentials();
            await authNotifier.login();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAuthenticating = false;
        });
      }
    }
  }

  Future<void> checkAuthState() async {
    if (!mounted) return;

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.initialize();

      // Vérifier si nous sommes déjà connectés
      final authState = ref.read(authStateProvider);
      authState.whenData((authService) {
        if (authService.isConnected && mounted) {
          // Utilisez le NavigationService
          ref.read(navigationServiceProvider).goToHello();
        }
      });
    } catch (e) {
      print('Erreur lors de la vérification de l\'état d\'authentification: $e');
    }
  }
}
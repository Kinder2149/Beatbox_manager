import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:beatbox_manager/services/cache/unified_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'config/routes.dart';
import 'services/navigation_service.dart';
import 'providers/unified_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement
  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  final cacheConfig = CacheConfig();
  final cacheService = UnifiedCacheService(prefs, config: cacheConfig);

  runApp(
    ProviderScope(
      overrides: [
        cacheServiceProvider.overrideWith((ref) => Future.value(cacheService)),
      ],
      child: const BeatBoxManagerApp(),
    ),
  );
}

class BeatBoxManagerApp extends ConsumerStatefulWidget {
  const BeatBoxManagerApp({Key? key}) : super(key: key);

  @override
  BeatBoxManagerAppState createState() => BeatBoxManagerAppState();
}

class BeatBoxManagerAppState extends ConsumerState<BeatBoxManagerApp> {
  late NavigationService _navigationService;
  late AppLinks _appLinks;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    if (_initialized) return;
    _navigationService = ref.read(navigationServiceProvider);

    try {
      await _initializeAppLinks();
      await _checkAuthState();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation des services: $e');
      _navigationService.goToHome();
    }
  }

  Future<void> _initializeAppLinks() async {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) {
      print('Lien reçu : $uri');
      if (uri.toString().startsWith('beatboxmanager://callback')) {
        _handleIncomingLink(uri);
      }
    }, onError: (err) {
      print('Erreur de deep link : $err');
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.initialize();
    } catch (e) {
      print('Erreur lors de la vérification de l\'état d\'authentification: $e');
      _navigationService.goToHome();
    }
  }

  void _handleIncomingLink(Uri uri) {
    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      authNotifier.handleAuthResponse(uri);
    } catch (e) {
      print('Erreur de traitement de lien: $e');
      _navigationService.handleNavigationError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: _navigationService.navigatorKey,
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      title: 'BeatBox Manager',
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
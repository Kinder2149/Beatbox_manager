// lib/providers/cache_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache/unified_cache_service.dart';

final cacheConfigProvider = Provider<CacheConfig>((ref) {
  return const CacheConfig(
    validityDuration: Duration(minutes: 30),
    maxMemoryItems: 100,
    persistToStorage: true,
  );
});

final cacheServiceProvider = FutureProvider<UnifiedCacheService>((ref) async {
  final config = ref.watch(cacheConfigProvider);
  final prefs = await SharedPreferences.getInstance();
  return UnifiedCacheService(prefs, config: config);
});
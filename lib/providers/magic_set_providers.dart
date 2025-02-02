import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/magic_set_models.dart';
import '../services/magic_set_service.dart';
import 'unified_providers.dart';

// Provider pour le service MagicSet
final magicSetServiceProvider = Provider<MagicSetService>((ref) {
  final spotifyService = ref.watch(spotifyServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider).value!;
  return MagicSetService(cacheService, spotifyService);
});

// Provider pour les MagicSets
final magicSetsProvider = StateNotifierProvider<MagicSetsNotifier, AsyncValue<List<MagicSet>>>((ref) {
  final service = ref.watch(magicSetServiceProvider);
  return MagicSetsNotifier(service);
});

// Provider pour le MagicSet sélectionné
final selectedSetProvider = StateProvider<MagicSet?>((ref) => null);

// Provider pour les templates
final templatesProvider = StateNotifierProvider<TemplatesNotifier, AsyncValue<List<MagicSet>>>((ref) {
  final service = ref.watch(magicSetServiceProvider);
  return TemplatesNotifier(service);
});

// Notifier pour les MagicSets
class MagicSetsNotifier extends StateNotifier<AsyncValue<List<MagicSet>>> {
  final MagicSetService _service;

  MagicSetsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      state = const AsyncValue.loading();
      final sets = await _service.getCachedSets();
      if (mounted) {
        state = AsyncValue.data(sets);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> createSet(String name, String playlistId, {String description = ''}) async {
    try {
      final newSet = MagicSet.create(
        name: name,
        playlistId: playlistId,
        description: description,
      );

      state.whenData((sets) {
        state = AsyncValue.data([...sets, newSet]);
      });

      await _service.saveMagicSet(newSet);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSet(MagicSet set) async {
    try {
      await _service.saveMagicSet(set);
      state.whenData((sets) {
        final newSets = sets.map((s) => s.id == set.id ? set : s).toList();
        state = AsyncValue.data(newSets);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSet(String setId) async {
    try {
      await _service.deleteMagicSet(setId);
      state.whenData((sets) {
        state = AsyncValue.data(sets.where((s) => s.id != setId).toList());
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveAsTemplate(String setId) async {
    try {
      await _service.saveAsTemplate(setId);
      state.whenData((sets) {
        final updatedSets = sets.map((s) =>
        s.id == setId ? s.copyWith(isTemplate: true) : s
        ).toList();
        state = AsyncValue.data(updatedSets);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> exportSet(String setId, ExportFormat format) async {
    try {
      return await _service.exportSet(setId, format);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importSet(String data) async {
    try {
      await _service.importSet(data);
      await _loadSets();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class TemplatesNotifier extends StateNotifier<AsyncValue<List<MagicSet>>> {
  final MagicSetService _service;

  TemplatesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _service.getTemplates();
      state = AsyncValue.data(templates);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadTemplates();
  }
}
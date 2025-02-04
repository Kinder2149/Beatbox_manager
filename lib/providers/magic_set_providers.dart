import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/magic_set_models.dart';
import '../services/magic_set_service.dart';
import 'unified_providers.dart';
import 'package:beatbox_manager/utils/unified_utils.dart';


// Provider pour le service MagicSet
final magicSetServiceProvider = Provider<MagicSetService>((ref) {
  final spotifyService = ref.watch(spotifyServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider).value!;
  return MagicSetService(cacheService, spotifyService);
});

// Provider pour les MagicSets
final magicSetsProvider = StateNotifierProvider<MagicSetsNotifier, MagicSetState>((ref) {
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
class MagicSetsNotifier extends StateNotifier<MagicSetState> {
  final MagicSetService _service;
  final int _itemsPerPage = 20;

  MagicSetsNotifier(this._service) : super(const MagicSetState()) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    try {
      await loadPage(0);
      await _loadTemplates();
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(e, stack),
        error: e.toString(),
      );
    }
  }
  Future<void> refreshSets() async {
    try {
      state = state.copyWith(
        syncInfo: state.syncInfo.copyWith(isSyncing: true),
      );

      // Utilisation de la méthode existante _loadSets
      await loadSets();

      state = state.copyWith(
        syncInfo: state.syncInfo.copyWith(
          isSyncing: false,
          lastSync: DateTime.now(),
        ),
        pagination: PaginationInfo(
          currentPage: 0,
          hasReachedEnd: false,
        ),
      );
    } catch (e, stack) {
      state = state.copyWith(
        error: e.toString(),
        syncInfo: state.syncInfo.copyWith(isSyncing: false),
      );
    }
  }

  Future<void> loadMoreSets() async {
    if (state.pagination.hasReachedEnd || state.syncInfo.isSyncing) return;

    try {
      final nextPage = state.pagination.currentPage + 1;
      final newSets = await _service.getPaginatedSets(
        offset: nextPage * _itemsPerPage,
        limit: _itemsPerPage,
      );

      final currentSets = state.sets.value ?? [];
      final updatedSets = [...currentSets, ...newSets];

      state = state.copyWith(
        sets: AsyncValue.data(updatedSets),
        pagination: state.pagination.copyWith(
          currentPage: nextPage,
          hasReachedEnd: newSets.isEmpty,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }


  Future<void> loadPage(int page) async {
    if (state.pagination.hasReachedEnd) return;

    try {
      state = state.copyWith(
        sets: const AsyncValue.loading(),
      );

      final offset = page * _itemsPerPage;
      final sets = await _service.getPaginatedSets(
        offset: offset,
        limit: _itemsPerPage,
      );

      final hasReachedEnd = sets.length < _itemsPerPage;

      state = state.copyWith(
        sets: AsyncValue.data(sets),
        pagination: PaginationInfo(
          currentPage: page,
          itemsPerPage: _itemsPerPage,
          hasReachedEnd: hasReachedEnd,
          totalItems: state.pagination.totalItems + sets.length,
        ),
      );
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(e, stack),
        error: e.toString(),
      );
    }
  }
  Future<void> _loadTemplates() async {
    try {
      final templates = await _service.getTemplates();
      state = state.copyWith(
        templates: AsyncValue.data(templates),
      );
    } catch (e, stack) {
      state = state.copyWith(
        templates: AsyncValue.error(e, stack),
        error: e.toString(),
      );
    }
  }


  Future<void> syncSet(String setId) async {
    if (state.syncInfo.isSyncing) return;

    try {
      state = state.copyWith(
        syncInfo: state.syncInfo.copyWith(isSyncing: true),
      );

      await _service.synchronizeWithSpotify(setId);

      state.sets.whenData((currentSets) async {
        final sets = await _service.getCachedSets();
        state = state.copyWith(
          sets: AsyncValue.data(sets),
          syncInfo: state.syncInfo.copyWith(
            isSyncing: false,
            lastSync: DateTime.now(),
            lastSetSync: {
              ...state.syncInfo.lastSetSync,
              setId: DateTime.now(),
            },
          ),
        );
      });
    } catch (e, stack) {
      state = state.copyWith(
        error: e.toString(),
        syncInfo: state.syncInfo.copyWith(isSyncing: false),
      );
    }
  }
  Future<void> loadSets() async {
    try {
      state = state.copyWith(
        sets: const AsyncValue<List<MagicSet>>.loading(),
      );

      final sets = await _service.getCachedSets();
      if (mounted) {
        state = state.copyWith(
          sets: AsyncValue.data(sets.where((set) => set.tracks.isNotEmpty).toList()),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        state = state.copyWith(
          sets: AsyncValue.error(e, stack),
          error: e.toString(),
        );
      }
    }
  }
  Future<void> addSet(MagicSet set) async {
    try {
      set.validate();
      await _service.saveMagicSet(set);

      state.sets.whenData((currentSets) {
        state = state.copyWith(
          sets: AsyncValue.data([...currentSets, set]),
        );
      });
    } catch (e, stack) {
      state = state.copyWith(
        error: e.toString(),
        sets: AsyncValue.error(e, stack),
      );
    }
  }

  Future<void> createSet(String name, String playlistId, {String description = '', MagicSet? template}) async {
    try {
      state = state.copyWith(
        sets: const AsyncValue<List<MagicSet>>.loading(),
      );

      MagicSet newSet;
      if (template != null) {
        newSet = template.createFromTemplate(playlistId);
      } else {
        newSet = MagicSet.create(
          name: name,
          playlistId: playlistId,
          description: description,
        );
      }

      newSet.validate();
      await _service.saveMagicSet(newSet);

      state.sets.when(
        data: (currentSets) {
          state = state.copyWith(
            sets: AsyncValue.data([...currentSets, newSet]),
          );
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(
            e is ValidationException ? e.message : 'Erreur lors de la création: $e',
            stack
        ),
        error: e is ValidationException ? e.message : 'Erreur lors de la création: $e',
      );
    }
  }


  Future<void> createFromTemplate(String templateId, String newPlaylistId) async {
    try {
      state.sets.when(
        data: (currentSets) async {
          final template = currentSets.firstWhere(
                (set) => set.id == templateId,
            orElse: () => throw Exception('Template non trouvé'),
          );

          final newSet = MagicSet.fromTemplate(template, newPlaylistId);
          await _service.saveMagicSet(newSet);

          state = state.copyWith(
            sets: AsyncValue.data([...currentSets, newSet]),
          );
        },
        loading: () {},
        error: (_, __) => throw Exception('État non initialisé'),
      );
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(e, stack),
        error: e.toString(),
      );
      rethrow;
    }
  }


  Future<void> updateSet(MagicSet set) async {
    try {
      await _service.saveMagicSet(set);

      state.sets.whenData((currentSets) {
        final newSets = currentSets.map(
                (s) => s.id == set.id ? set : s
        ).toList();

        state = state.copyWith(
          sets: AsyncValue.data(newSets),
        );
      });
    } catch (e, stack) {
      state = state.copyWith(
        error: e.toString(),
        sets: AsyncValue.error(e, stack),
      );
    }
  }


  Future<void> deleteSet(String setId) async {
    try {
      await _service.deleteMagicSet(setId);

      state.sets.when(
        data: (currentSets) {
          state = state.copyWith(
            sets: AsyncValue.data(currentSets.where((s) => s.id != setId).toList()),
          );
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(e, stack),
        error: e.toString(),
      );
    }
  }

  Future<void> saveAsTemplate(String setId) async {
    try {
      await _service.saveAsTemplate(setId);

      state.sets.when(
        data: (currentSets) {
          final updatedSets = currentSets.map((s) =>
          s.id == setId ? s.copyWith(isTemplate: true) : s
          ).toList();

          state = state.copyWith(
            sets: AsyncValue.data(updatedSets),
          );
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(e, stack),
        error: e.toString(),
      );
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
      await loadSets();
    } catch (e, stack) {
      state = state.copyWith(
        sets: AsyncValue.error(e, stack),
        error: e.toString(),
      );
    }
  }
  Future<void> updateTrack(String setId, TrackInfo updatedTrack) async {
    try {
      Validators.validateTrackInfo(updatedTrack);

      state.sets.whenData((currentSets) {
        final setIndex = currentSets.indexWhere((s) => s.id == setId);
        if (setIndex == -1) {
          throw AppException('Set non trouvé', type: ErrorType.validation);
        }

        final set = currentSets[setIndex];
        final updatedSet = set.updateTrack(updatedTrack);

        Validators.validateMagicSet(updatedSet);
        _service.saveMagicSet(updatedSet);

        final newSets = [
          ...currentSets.sublist(0, setIndex),
          updatedSet,
          ...currentSets.sublist(setIndex + 1),
        ];

        state = state.copyWith(
          sets: AsyncValue.data(newSets),
        );
      });
    } catch (e, stack) {
      state = state.copyWith(
        error: e.toString(),
        sets: AsyncValue.error(e, stack),
      );
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
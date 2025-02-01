import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/magic_set_models.dart';
import '../services/magic_set_service.dart';
import 'unified_providers.dart';
import '../services/cache/unified_cache_service.dart';
import '../services/spotify/unified_spotify_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

final magicSetServiceProvider = Provider<MagicSetService>((ref) {
  final spotifyService = ref.watch(spotifyServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider).value!;
  return MagicSetService(cacheService, spotifyService);
});

final magicSetsProvider = StateNotifierProvider<MagicSetsNotifier, AsyncValue<List<MagicSet>>>((ref) {
  final service = ref.watch(magicSetServiceProvider);
  return MagicSetsNotifier(service);
});


final combinedDataProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final account = ref.watch(userStateProvider);
  final playlists = ref.watch(playlistsProvider);
  final likedTracks = ref.watch(likedTracksProvider);
  final magicSets = ref.watch(magicSetsProvider);

  if (account.isLoading || playlists.items.isEmpty || likedTracks.items.isEmpty || magicSets.isLoading) {
    return const AsyncValue.loading();
  }

  if (account.error != null || playlists.error != null || likedTracks.error != null || magicSets.hasError) {
    return AsyncValue.error(
      'Une erreur est survenue',
      StackTrace.current,
    );
  }

  final combinedData = {
    'account': account.value ?? {},
    'playlists': playlists.items,
    'playlistsCount': playlists.items.length,
    'likedTracks': likedTracks.items,
    'likedTracksCount': likedTracks.items.length,
    'magicSets': magicSets.value ?? [],
    'magicSetsCount': magicSets.value?.length ?? 0,
  };

  return AsyncValue.data(combinedData);
});


final tagsProvider = StateNotifierProvider<TagsNotifier, AsyncValue<List<Tag>>>((ref) {
  return TagsNotifier();
});

class TagsNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  TagsNotifier() : super(const AsyncValue.data([]));

  Future<void> addTag(Tag tag) async {
    state.whenData((tags) {
      state = AsyncValue.data([...tags, tag]);
    });
  }

  Future<void> updateTag(Tag updatedTag) async {
    state.whenData((tags) {
      final index = tags.indexWhere((t) => t.id == updatedTag.id);
      if (index != -1) {
        final newTags = List<Tag>.from(tags);
        newTags[index] = updatedTag;
        state = AsyncValue.data(newTags);
      }
    });
  }

  Future<void> deleteTag(String tagId) async {
    state.whenData((tags) {
      state = AsyncValue.data(tags.where((t) => t.id != tagId).toList());
    });
  }
}
final selectedSetProvider = StateProvider<MagicSet?>((ref) => null);


class MagicSetsNotifier extends StateNotifier<AsyncValue<List<MagicSet>>> {
  final MagicSetService _service;

  MagicSetsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadSets();
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


  Future<void> updateSet(MagicSet set) async {
    try {
      await _service.saveMagicSet(set);

      state.whenData((sets) {
        final index = sets.indexWhere((s) => s.id == set.id);
        if (index != -1) {
          final newSets = List<MagicSet>.from(sets);
          newSets[index] = set;
          state = AsyncValue.data(newSets);
        }
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
}

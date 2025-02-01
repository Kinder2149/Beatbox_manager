import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/magic_set_models.dart';
import 'cache/unified_cache_service.dart';
import 'spotify/unified_spotify_service.dart';
import 'dart:async';
import 'dart:convert';

class MagicSetService {
  final UnifiedCacheService _cacheService;
  final UnifiedSpotifyService _spotifyService;
  static const String _magicSetsCacheKey = 'magic_sets_cache';
  static const String _tagsCacheKey = 'tags_cache';

  MagicSetService(this._cacheService, this._spotifyService);

  // CRUD Operations
  Future<MagicSet> createMagicSet(String name, String playlistId, {String description = ''}) async {
    final newSet = MagicSet.create(
      name: name,
      playlistId: playlistId,
      description: description,
    );

    final sets = await getCachedSets();
    sets.add(newSet);
    await _cacheService.cacheMagicSets(sets);

    return newSet;
  }
  Future<void> saveMagicSet(MagicSet set) async {
    try {
      final sets = await getCachedSets();
      final index = sets.indexWhere((s) => s.id == set.id);

      if (index != -1) {
        sets[index] = set;
      } else {
        sets.add(set);
      }

      await _cacheService.cacheMagicSets(sets);
    } catch (e) {
      print('Erreur lors de la sauvegarde du magic set: $e');
      rethrow;
    }
  }

  Future<void> updateMagicSet(MagicSet set) async {
    final sets = await getCachedSets();
    final index = sets.indexWhere((s) => s.id == set.id);
    if (index != -1) {
      sets[index] = set.copyWith(updatedAt: DateTime.now());
      await _cacheService.cacheMagicSets(sets);
    }
  }

  Future<void> deleteMagicSet(String setId) async {
    try {
      final sets = await getCachedSets();
      sets.removeWhere((set) => set.id == setId);
      await _cacheService.cacheMagicSets(sets);
    } catch (e) {
      print('Erreur lors de la suppression du magic set: $e');
      rethrow;
    }
  }
  Future<void> handleError(String operation, dynamic error, StackTrace? stackTrace) async {
    print('Erreur lors de $operation: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
    // Vous pouvez ajouter ici une logique supplémentaire de gestion des erreurs
    throw Exception('Erreur lors de $operation: $error');
  }

  Future<T> withErrorHandling<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, stack) {
      print('Erreur lors de $operation: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }


  // Tag Operations
  Future<Tag> createTag(String name, Color color, TagScope scope) async {
    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
      scope: scope,
    );

    final tags = await _getCachedTags();
    tags.add(tag);
    await _cacheTags(tags);

    return tag;
  }

  Future<void> assignTagToTrack(String setId, String trackId, Tag tag) async {
    final sets = await getCachedSets();
    final setIndex = sets.indexWhere((s) => s.id == setId);
    if (setIndex != -1) {
      final tracks = List<TrackInfo>.from(sets[setIndex].tracks);
      final trackIndex = tracks.indexWhere((t) => t.trackId == trackId);

      if (trackIndex != -1) {
        tracks[trackIndex] = tracks[trackIndex].copyWith(
          tags: [...tracks[trackIndex].tags, tag],
        );

        sets[setIndex] = sets[setIndex].copyWith(
          tracks: tracks,
          updatedAt: DateTime.now(),
        );

        await _cacheSets(sets);
      }
    }
  }

  Future<void> assignTagToSet(String setId, Tag tag) async {
    final sets = await getCachedSets();
    final index = sets.indexWhere((s) => s.id == setId);
    if (index != -1) {
      sets[index] = sets[index].copyWith(
        tags: [...sets[index].tags, tag],
        updatedAt: DateTime.now(),
      );
      await _cacheSets(sets);
    }
  }

  // Template Operations
  Future<MagicSet> createFromTemplate(String templateId, String playlistId) async {
    final sets = await getCachedSets();
    final template = sets.firstWhere((s) => s.id == templateId && s.isTemplate);
    final newSet = MagicSet.fromTemplate(template, playlistId);

    sets.add(newSet);
    await _cacheSets(sets);

    return newSet;
  }

  Future<void> saveAsTemplate(String setId) async {
    final sets = await getCachedSets();
    final index = sets.indexWhere((s) => s.id == setId);
    if (index != -1) {
      sets[index] = sets[index].copyWith(isTemplate: true);
      await _cacheSets(sets);
    }
  }

  // Cache Operations
  Future<List<MagicSet>> getCachedSets() async {
    try {
      final cached = await _cacheService.getCachedMagicSets();
      return cached ?? [];
    } catch (e) {
      print('Erreur lors de la récupération des magic sets: $e');
      return [];
    }
  }

  Future<void> _cacheSets(List<MagicSet> sets) async {
    await _cacheService.set(_magicSetsCacheKey, sets.map((s) => s.toJson()).toList());
  }

  Future<List<Tag>> _getCachedTags() async {
    final data = await _cacheService.get<List<dynamic>>(_tagsCacheKey);
    return data?.map((json) => Tag.fromJson(json)).toList() ?? [];
  }

  Future<void> _cacheTags(List<Tag> tags) async {
    await _cacheService.set(_tagsCacheKey, tags.map((t) => t.toJson()).toList());
  }
}
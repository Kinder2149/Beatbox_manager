import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import '../models/magic_set_models.dart';
import 'cache/unified_cache_service.dart';
import 'spotify/unified_spotify_service.dart';
import 'package:collection/collection.dart';

class MagicSetService {
  final UnifiedCacheService _cacheService;
  final UnifiedSpotifyService _spotifyService;
  static const String _magicSetsCacheKey = 'magic_sets_cache';
  static const String _tagsCacheKey = 'tags_cache';
  static const String _templatesCacheKey = 'templates_cache';
  static const _cacheValidityDuration = Duration(minutes: 30);

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

  Future<void> saveAsTemplate(String setId) async {
    final set = await getSetById(setId);
    if (set == null) throw Exception('Set not found');

    final templateSet = set.copyWith(
      isTemplate: true,
      updatedAt: DateTime.now(),
    );

    await saveMagicSet(templateSet);
  }
  Future<String> exportSet(String setId, ExportFormat format) async {
    final set = await getSetById(setId);
    if (set == null) throw Exception('Set not found');

    switch (format) {
      case ExportFormat.JSON:
        return _exportToJson(set);
      case ExportFormat.PDF:
        return _exportToPdf(set);
      case ExportFormat.CSV:
        return _exportToCsv(set);
    }
  }

  String _exportToJson(MagicSet set) {
    return jsonEncode(set.toJson());
  }

  Future<String> _exportToPdf(MagicSet set) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(set.name),
              ),
              pw.Paragraph(text: set.description),
              pw.Header(
                level: 1,
                child: pw.Text('Tags'),
              ),
              pw.Column(
                children: set.tags.map((tag) =>
                    pw.Text('${tag.name} (${tag.scope})')
                ).toList(),
              ),
              pw.Header(
                level: 1,
                child: pw.Text('Tracks'),
              ),
              ...set.tracks.map((track) =>
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(track.trackId),
                      pw.Text('Notes: ${track.notes}'),
                      pw.Text('Tags: ${track.tags.map((t) => t.name).join(", ")}'),
                      if (track.customMetadata.isNotEmpty)
                        pw.Text('Metadata: ${jsonEncode(track.customMetadata)}'),
                    ],
                  ),
              ),
            ],
          );
        },
      ),
    );

    return base64Encode(await pdf.save());
  }

  String _exportToCsv(MagicSet set) {
    List<List<dynamic>> rows = [
      ['Track ID', 'Notes', 'Tags', 'Duration', 'Key', 'BPM', 'Custom Metadata']
    ];

    for (var track in set.tracks) {
      rows.add([
        track.trackId,
        track.notes,
        track.tags.map((t) => t.name).join(';'),
        track.duration.toString(),
        track.key ?? '',
        track.bpm ?? '',
        jsonEncode(track.customMetadata),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
  Future<List<MagicSet>> getTemplates() async {
    final sets = await getCachedSets();
    return sets.where((set) => set.isTemplate).toList();
  }

  // Ajouter ces méthodes pour l'export/import
  Future<String> exportSetToJson(String setId) async {
    final sets = await getCachedSets();
    final set = sets.firstWhere((s) => s.id == setId);
    return jsonEncode(set.toJson());
  }

  Future<String> exportSetToPdf(String setId) async {
    final set = await getSetById(setId);
    if (set == null) throw Exception('Set not found');

    final pdf = pw.Document();
    // ... Logique de génération PDF ...
    final bytes = await pdf.save(); // Ceci retourne un Uint8List
    return base64Encode(bytes); // Convertit en String base64
  }

  Future<void> importSet(String data) async {
    try {
      // Essayer d'abord comme JSON
      final jsonData = jsonDecode(data);
      final set = MagicSet.fromJson(jsonData);
      await saveMagicSet(set);
    } catch (e) {
      throw Exception('Format invalide: $e');
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
    final template = await getSetById(templateId);
    if (template == null) throw Exception('Template not found');

    final newSet = MagicSet.fromTemplate(template, playlistId);
    await saveMagicSet(newSet);
    return newSet;
  }

  // Utilitaire
  Future<MagicSet?> getSetById(String id) async {
    final sets = await getCachedSets();
    return sets.firstWhereOrNull((s) => s.id == id);
  }





  // Cache Operations
  Future<List<MagicSet>> getCachedSets() async {
    try {
      final cached = await _cacheService.get<List<dynamic>>(_magicSetsCacheKey);
      if (cached != null) {
        // Vérification de la validité du cache
        final lastUpdate = await _cacheService.get<String>('${_magicSetsCacheKey}_lastUpdate');
        if (lastUpdate != null) {
          final lastUpdateTime = DateTime.parse(lastUpdate);
          if (DateTime.now().difference(lastUpdateTime) < _cacheValidityDuration) {
            return cached.map((json) => MagicSet.fromJson(json)).toList();
          }
        }
      }
      return await _fetchAndCacheSets();
    } catch (e) {
      print('Erreur de cache: $e');
      return [];
    }
  }
  Future<List<MagicSet>> _fetchAndCacheSets() async {
    final sets = await _spotifyService.spotify!.playlists
        .me.all()
        .then((playlists) => playlists
        .where((p) => p.id != null)
        .map((p) => MagicSet.create(
      name: p.name ?? 'Sans nom',
      playlistId: p.id!,
    ))
        .toList());

    await _cacheService.set(_magicSetsCacheKey,
        sets.map((s) => s.toJson()).toList()
    );
    await _cacheService.set(
        '${_magicSetsCacheKey}_lastUpdate',
        DateTime.now().toIso8601String()
    );

    return sets;
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
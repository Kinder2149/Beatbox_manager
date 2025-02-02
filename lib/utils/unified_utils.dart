// lib/utils/unified_utils.dart

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/magic_set_models.dart';


// Constants
class SpotifyConstants {
  static const int pageSize = 50;
  static const Duration cacheValidityDuration = Duration(minutes: 30);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration requestDelay = Duration(milliseconds: 100);
}

class CacheKeys {
  static const String playlists = 'playlists_cache';
  static const String likedTracks = 'liked_tracks_cache';
  static const String playlistTracksPrefix = 'playlist_tracks_';
  static const String tokenKey = 'spotify_token';
  static const String refreshTokenKey = 'spotify_refresh_token';
  static const String tokenExpirationKey = 'spotify_token_expiration';
}

// Extensions
extension AsyncValueUI on AsyncValue {
  bool get isLoading => this is AsyncLoading;
  bool get hasError => this is AsyncError;
  bool get hasData => this is AsyncData;

  // Renommons la méthode pour éviter le conflit
  Widget whenOrNull({
    required Widget Function(dynamic data) data,
    Widget Function()? loading,
    Widget Function(Object error, StackTrace? stackTrace)? error,
  }) {
    if (this is AsyncLoading) {
      return loading?.call() ?? const Center(
        child: CircularProgressIndicator(),
      );
    } else if (this is AsyncError) {
      final err = (this as AsyncError);
      return error?.call(err.error, err.stackTrace) ?? Center(
        child: Text('Erreur: ${err.error.toString()}'),
      );
    } else if (this is AsyncData) {
      return data((this as AsyncData).value);
    }
    return const SizedBox.shrink();
  }
}

extension BuildContextExt on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(this).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }
}
class PaginationConfig {
  final int initialPageSize;
  final int subsequentPageSize;
  final int maxRetries;
  final Duration retryDelay;

  const PaginationConfig({
    this.initialPageSize = 50,
    this.subsequentPageSize = 50,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
}

// Pagination Manager
class PaginationManager<T> extends ChangeNotifier {
  final Future<List<T>> Function(int offset, {int? limit}) fetchData;
  final PaginationConfig config;

  PaginationManager({
    required this.fetchData,
    this.config = const PaginationConfig(),
  });

  List<T> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMoreItems = true;
  int _currentRetry = 0;
  bool _hasInitialData = false;

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMoreItems => _hasMoreItems;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;

  Future<void> loadInitial() async {
    if (_isLoading || _hasInitialData) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItems = await _fetchWithRetry(0, config.initialPageSize);
      _items = newItems;
      _hasMoreItems = newItems.length >= config.initialPageSize;
      _hasInitialData = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMoreItems) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newItems = await _fetchWithRetry(
          _items.length,
          config.subsequentPageSize
      );

      if (newItems.isEmpty) {
        _hasMoreItems = false;
      } else {
        _items.addAll(newItems);
        _hasMoreItems = newItems.length >= config.subsequentPageSize;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<T>> _fetchWithRetry(int offset, int pageSize) async {
    _currentRetry = 0;
    while (_currentRetry < config.maxRetries) {
      try {
        return await fetchData(offset, limit: pageSize);
      } catch (e) {
        _currentRetry++;
        if (_currentRetry >= config.maxRetries) rethrow;
        await Future.delayed(config.retryDelay);
      }
    }
    throw Exception('Échec après ${config.maxRetries} tentatives');
  }

  void refresh() {
    _items = [];
    _hasMoreItems = true;
    _error = null;
    _hasInitialData = false;
    loadInitial();
  }

  void setInitialData(List<T> data) {
    _items = data;
    _hasMoreItems = data.length >= config.initialPageSize;
    _hasInitialData = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _items = [];
    super.dispose();
  }
}

// Batch Request Manager
class BatchRequestManager {
  static const maxBatchSize = SpotifyConstants.pageSize;
  static const delayBetweenBatches = SpotifyConstants.requestDelay;

  Future<List<T>> executeBatched<T>(
      List<Future<T> Function()> requests, {
        void Function(int progress, int total)? onProgress,
      }) async {
    final results = <T>[];

    for (var i = 0; i < requests.length; i += maxBatchSize) {
      final batch = requests.skip(i).take(maxBatchSize);
      final batchResults = await Future.wait(batch.map((r) => r()));
      results.addAll(batchResults);

      onProgress?.call(results.length, requests.length);

      if (i + maxBatchSize < requests.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }

    return results;
  }
}

// Prioritized Data Loading
enum DataPriority { high, medium, low }

class _DataRequest {
  final DataPriority priority;
  final Future<void> Function() execute;
  final Completer<void> completer;

  _DataRequest({
    required this.priority,
    required this.execute,
    required this.completer,
  });

  int get priorityValue {
    switch (priority) {
      case DataPriority.high: return 3;
      case DataPriority.medium: return 2;
      case DataPriority.low: return 1;
    }
  }
}

class PrioritizedDataLoader {
  final List<_DataRequest> _queue = [];
  bool _isProcessing = false;

  Future<T> load<T>(
      Future<T> Function() request,
      DataPriority priority,
      ) async {
    final completer = Completer<T>();

    final dataRequest = _DataRequest(
      priority: priority,
      execute: () async {
        try {
          final result = await request();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      },
      completer: Completer<void>(),
    );

    _queue.add(dataRequest);
    _queue.sort((a, b) => b.priorityValue.compareTo(a.priorityValue));
    _processQueue();

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty) {
        final request = _queue.removeAt(0);
        await request.execute();
        request.completer.complete();
      }
    } finally {
      _isProcessing = false;
    }
  }
}

// Retry Mechanism
class RetryOptions {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;

  const RetryOptions({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffFactor = 2.0,
  });
}

Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
      RetryOptions options = const RetryOptions(),
    }) async {
  int attempt = 0;
  Duration delay = options.initialDelay;

  while (true) {
    try {
      attempt++;
      return await operation();
    } catch (e) {
      if (attempt >= options.maxAttempts) {
        rethrow;
      }
      await Future.delayed(delay);
      delay *= options.backoffFactor;
    }
  }
}

class MagicSetExporter {
  static Future<File> exportAsPDF(MagicSet set) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Magic Set: ${set.name}'),
              ),
              pw.Paragraph(text: set.description),
              pw.Header(
                level: 1,
                child: pw.Text('Tags'),
              ),
              pw.Column(
                children: set.tags.map((tag) =>
                    pw.Text('${tag.name} (${tag.scope.toString()})')
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
                    ],
                  ),
              ),
            ],
          );
        },
      ),
    );

    final file = File('magic_set_${set.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<String> exportAsJSON(MagicSet set) async {
    return jsonEncode(set.toJson());
  }

  static Future<File> exportAsCSV(MagicSet set) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add(['Track ID', 'Notes', 'Tags', 'Custom Fields']);

    // Data
    for (var track in set.tracks) {
      rows.add([
        track.trackId,
        track.notes,
        track.tags.map((t) => t.name).join(';'),
        track.customFields.toString(),
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final file = File('magic_set_${set.id}.csv');
    await file.writeAsString(csv);
    return file;
  }

  static Future<MagicSet> importFromJSON(String json) async {
    try {
      final data = jsonDecode(json);
      return MagicSet.fromJson(data);
    } catch (e) {
      throw FormatException('Invalid magic set format: $e');
    }
  }
}
class ValidationException implements Exception {
  final String message;
  final String? field;
  final dynamic value;

  ValidationException(this.message, {this.field, this.value});

  @override
  String toString() => 'ValidationException: $message${field != null ? ' (field: $field)' : ''}';
}

class Validators {
  static void validateMagicSet(MagicSet set) {
    if (set.name.trim().isEmpty) {
      throw ValidationException('Le nom du set ne peut pas être vide', field: 'name');
    }
    if (set.playlistId == null || set.playlistId!.trim().isEmpty) {
      throw ValidationException('L\'ID de playlist est requis', field: 'playlistId');
    }

    // Valider chaque piste
    for (var track in set.tracks) {
      validateTrackInfo(track);
    }

    // Valider les tags
    for (var tag in set.tags) {
      validateTag(tag);
    }
  }

  static void validateTrackInfo(TrackInfo track) {
    if (track.trackId.isEmpty) {
      throw ValidationException('L\'ID de piste est requis', field: 'trackId');
    }

    // Valider la durée
    if (track.duration.inMilliseconds < 0) {
      throw ValidationException('La durée doit être positive',
          field: 'duration',
          value: track.duration
      );
    }

    // Valider le BPM
    if (track.bpm != null && (track.bpm! < 0 || track.bpm! > 999)) {
      throw ValidationException('BPM invalide (doit être entre 0 et 999)',
          field: 'bpm',
          value: track.bpm
      );
    }
  }

  static void validateTag(Tag tag) {
    if (tag.name.isEmpty) {
      throw ValidationException('Le nom du tag ne peut pas être vide', field: 'name');
    }
    if (tag.id.isEmpty) {
      throw ValidationException('L\'ID du tag est requis', field: 'id');
    }
  }
}
enum ErrorType {
  validation,
  network,
  cache,
  authentication,
  unknown
}

class AppException implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(
      this.message, {
        this.type = ErrorType.unknown,
        this.originalError,
        this.stackTrace,
      });

  @override
  String toString() => 'AppException: $message (type: $type)';
}


class ErrorHandler {
  static void handleError(
      BuildContext context,
      dynamic error,
      StackTrace? stackTrace, {
        String? friendlyMessage,
        VoidCallback? onRetry,
      }) {
    // Log l'erreur
    print('Error: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');

    // Détermine le message à afficher
    String message = friendlyMessage ?? _getFriendlyMessage(error);

    // Affiche le SnackBar approprié
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: onRetry != null
            ? SnackBarAction(
          label: 'Réessayer',
          onPressed: onRetry,
        )
            : null,
        behavior: SnackBarBehavior.floating,
        backgroundColor: _getColorForError(error),
      ),
    );
  }

  static String _getFriendlyMessage(dynamic error) {
    if (error is ValidationException) {
      return 'Erreur de validation: ${error.message}';
    }
    if (error is AppException) {
      switch (error.type) {
        case ErrorType.network:
          return 'Erreur de connexion. Vérifiez votre connexion internet.';
        case ErrorType.cache:
          return 'Erreur de cache. Essayez de rafraîchir l\'application.';
        case ErrorType.authentication:
          return 'Erreur d\'authentification. Veuillez vous reconnecter.';
        default:
          return error.message;
      }
    }
    return 'Une erreur inattendue s\'est produite';
  }

  static Color _getColorForError(dynamic error) {
    if (error is ValidationException) return Colors.orange;
    if (error is AppException) {
      switch (error.type) {
        case ErrorType.network:
          return Colors.red;
        case ErrorType.authentication:
          return Colors.purple;
        default:
          return Colors.red;
      }
    }
    return Colors.red;
  }
}

mixin UnsavedChangesMixin<T extends StatefulWidget> on State<T> {
  bool _hasUnsavedChanges = false;

  set hasUnsavedChanges(bool value) {
    setState(() => _hasUnsavedChanges = value);
  }

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  Future<bool> onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
            'Vous avez des modifications non sauvegardées. '
                'Voulez-vous les sauvegarder avant de quitter ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ignorer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result == null) return false;
    if (result) {
      // Appeler la méthode de sauvegarde
      await saveChanges();
    }
    return true;
  }

  Future<void> saveChanges();
}
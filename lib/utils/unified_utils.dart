// lib/utils/unified_utils.dart

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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


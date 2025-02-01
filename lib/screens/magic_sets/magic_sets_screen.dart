// lib/screens/magic_sets/magic_sets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart' hide Player;
import '../../models/magic_set_models.dart';
import '../../providers/unified_providers.dart';
import '../../providers/magic_set_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/unified_widgets.dart';

enum PaginatedStatus {
  initial,
  loading,
  loaded,
  error
}

class PaginatedState<T> {
  final List<T> items;
  final PaginatedStatus status;
  final String? error;
  final bool hasMore;

  PaginatedState({
    required this.items,
    required this.status,
    this.error,
    this.hasMore = false,
  });

  // Méthodes utilitaires
  bool get isLoading => status == PaginatedStatus.loading;
  bool get isError => status == PaginatedStatus.error;
  bool get isLoaded => status == PaginatedStatus.loaded;
}


class MagicSetsScreen extends ConsumerStatefulWidget {
  const MagicSetsScreen({Key? key}) : super(key: key);

  @override
  MagicSetsScreenState createState() => MagicSetsScreenState();
}

class MagicSetsScreenState extends ConsumerState<MagicSetsScreen> {
  @override
  Widget build(BuildContext context) {
    final magicSets = ref.watch(magicSetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magic Sets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer),
            onPressed: () => Navigator.pushNamed(context, '/tag-manager'),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: magicSets.when(
          data: (sets) => sets.isEmpty
              ? _buildEmptyState()
              : _buildSetsList(sets),
          loading: () => const LoadingIndicator(
            message: 'Chargement des Magic Sets...',
          ),
          error: (error, stack) => ErrorDisplay(
            message: 'Erreur: $error',
            onRetry: () => ref.refresh(magicSetsProvider),
            onBack: () => Navigator.of(context).pop(), // Ajout du paramètre manquant
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSetDialog(),
        child: const Icon(Icons.add),
        backgroundColor: AppTheme.spotifyGreen,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: AppTheme.spotifyGreen.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun Magic Set',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier Magic Set pour commencer à organiser vos playlists !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsList(List<MagicSet> sets) {
    return ListView.builder(
      itemCount: sets.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final set = sets[index];
        return _MagicSetCard(
          set: set,
          onTap: () => _navigateToSetDetail(set),
        );
      },
    );
  }

  void _navigateToSetDetail(MagicSet set) {
    ref.read(selectedSetProvider.notifier).state = set;
    Navigator.pushNamed(
      context,
      '/magic-set-detail',
      arguments: set,
    );
  }

  Future<void> _showCreateSetDialog() async {
    final playlistsState = ref.read(playlistsProvider);

    if (playlistsState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des playlists...')),
      );
      return;
    }

    if (playlistsState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${playlistsState.error}')),
      );
      return;
    }

    final playlists = playlistsState.items;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune playlist disponible. Importez d\'abord des playlists.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => CreateSetDialog(playlists: playlists),
    );
  }
}

class _MagicSetCard extends StatelessWidget {
  final MagicSet set;
  final VoidCallback onTap;

  const _MagicSetCard({
    Key? key,
    required this.set,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.spotifyGreen,
          child: Icon(
            set.isTemplate ? Icons.bookmark : Icons.auto_awesome,
            color: Colors.white,
          ),
        ),
        title: Text(set.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (set.description.isNotEmpty)
              Text(
                set.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.music_note, size: 16, color: Colors.grey[600]),
                Text(' ${set.tracks.length}'),
                const SizedBox(width: 16),
                Icon(Icons.local_offer, size: 16, color: Colors.grey[600]),
                Text(' ${set.tags.length}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (set.isTemplate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Template',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class CreateSetDialog extends ConsumerStatefulWidget {
  final List<PlaylistSimple> playlists;

  const CreateSetDialog({
    Key? key,
    required this.playlists,
  }) : super(key: key);

  @override
  CreateSetDialogState createState() => CreateSetDialogState();
}

class CreateSetDialogState extends ConsumerState<CreateSetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPlaylistId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un Magic Set'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Entrez le nom du Magic Set',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez votre Magic Set',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPlaylistId,
                decoration: const InputDecoration(
                  labelText: 'Playlist',
                  hintText: 'Sélectionnez une playlist',
                ),
                items: widget.playlists.map((playlist) => DropdownMenuItem(
                  value: playlist.id,
                  child: Text(
                    playlist.name ?? 'Sans nom',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlaylistId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Une playlist est requise';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createSet,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Créer'),
        ),
      ],
    );
  }

  Future<void> _createSet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(magicSetsProvider.notifier).createSet(
        _nameController.text,
        _selectedPlaylistId!,
        description: _descriptionController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Magic Set créé avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// lib/screens/magic_sets/magic_set_detail_screen.dart - PARTIE 1

import 'package:flutter/material.dart';


import 'package:spotify/spotify.dart' as spotify hide Image;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/magic_set_models.dart';
import '../../providers/unified_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/unified_widgets.dart';
import '../../providers/magic_set_providers.dart';
import 'package:beatbox_manager/widgets/tag_details_dialog.dart';
import 'package:beatbox_manager/config/routes.dart';



class MagicSetDetailScreen extends ConsumerStatefulWidget {
  final MagicSet set;

  const MagicSetDetailScreen({
    Key? key,
    required this.set,
  }) : super(key: key);

  @override
  MagicSetDetailScreenState createState() => MagicSetDetailScreenState();
}

class MagicSetDetailScreenState extends ConsumerState<MagicSetDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedSet = ref.watch(selectedSetProvider);

    if (selectedSet == null) {
      return const Scaffold(
        body: Center(
          child: Text('Aucun Magic Set sélectionné'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, selectedSet),
          _buildContent(context, selectedSet),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTracksDialog(context, selectedSet),
        child: const Icon(Icons.add),
        backgroundColor: AppTheme.spotifyGreen,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MagicSet set) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(set.name),
        background: Container(
          decoration: AppTheme.gradientBackground,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                set.isTemplate ? Icons.bookmark : Icons.auto_awesome,
                size: 50,
                color: Colors.white70,
              ),
              const SizedBox(height: 8),
              if (set.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    set.description,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editSet(context, set),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(context, set),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, MagicSet set) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildStats(context, set),
        _buildTagsList(context, set),
        _buildTracksList(context, set),
      ]),
    );
  }

  Widget _buildStats(BuildContext context, MagicSet set) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.music_note,
              label: 'Tracks',
              value: set.tracks.length.toString(),
            ),
            _buildStatItem(
              context,
              icon: Icons.local_offer,
              label: 'Tags',
              value: set.tags.length.toString(),
            ),
            _buildStatItem(
              context,
              icon: Icons.timer,
              label: 'Durée',
              value: _formatDuration(set.totalDuration),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.spotifyGreen),
        const SizedBox(height: 4),
        Text(label, style: Theme
            .of(context)
            .textTheme
            .bodySmall),
        Text(value, style: Theme
            .of(context)
            .textTheme
            .titleMedium),
      ],
    );
  }

  Widget _buildTagsList(BuildContext context, MagicSet set) {
    if (set.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags', style: Theme
              .of(context)
              .textTheme
              .titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: set.tags.map((tag) =>
                Chip(
                  label: Text(tag.name),
                  backgroundColor: tag.color,
                  labelStyle: const TextStyle(color: Colors.white),
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(BuildContext context, MagicSet set) {
    if (set.tracks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Aucun titre dans ce Magic Set.\nAppuyez sur + pour en ajouter !',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: set.tracks.length,
      itemBuilder: (context, index) {
        final track = set.tracks[index];
        return _TrackListItem(
          track: track,
          onTap: () => _showTrackDetails(context, set, track),
          onTagTap: (tag) => _showTagDetails(context, tag),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _editSet(BuildContext context, MagicSet set) {
    Navigator.pushNamed(context, '/magic-set-editor', arguments: set);
  }

  void _showTagDetails(BuildContext context, Tag? tag) {
    showDialog(
      context: context,
      builder: (context) => TagDetailsDialog(tag: tag),
    );
  }
  void _showAddTracksDialog(BuildContext context, MagicSet set) async {
    final availableTracks = await ref.read(spotifyServiceProvider).spotify!.playlists
        .getTracksByPlaylistId(set.playlistId)
        .all()
        .then((pages) => pages.toList());

    if (!mounted) return;

    final selectedTrackIds = set.tracks.map((t) => t.trackId).toSet();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddTracksDialog(
        currentSet: set,
        availableTracks: availableTracks,
        selectedTracks: selectedTrackIds,
      ),
    );

    if (result == true) {
      // Le rafraîchissement est géré dans AddTracksDialog
      ref.read(selectedSetProvider.notifier).state = set;
    }
  }

  void _showOptionsMenu(BuildContext context, MagicSet set) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Sauvegarder comme template'),
            onTap: () async { // Au lieu de onPressed
              Navigator.pop(context);
              await ref.read(magicSetsProvider.notifier).saveAsTemplate(set.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template créé avec succès')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Exporter'),
            onTap: () => _showExportDialog(context, set),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Supprimer'),
            textColor: Colors.red,
            onTap: () => _showDeleteConfirmation(context, set),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, MagicSet set) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExportFormat.values.map((format) =>
              ListTile(
                title: Text(format.toString().split('.').last),
                onTap: () => _exportSet(context, set, format),
              ),
          ).toList(),
        ),
      ),
    );
  }

  Future<void> _exportSet(BuildContext context, MagicSet set, ExportFormat format) async {
    try {
      Navigator.pop(context); // Ferme le dialogue d'export
      final result = await ref.read(magicSetsProvider.notifier).exportSet(set.id, format);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Set exporté avec succès: $result')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, MagicSet set) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Magic Set ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${set.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Au lieu de primary
            ),
            onPressed: () async {
              await ref.read(magicSetsProvider.notifier).deleteSet(set.id);

              if (!mounted) return;

              Navigator.pop(context); // Ferme la confirmation
              Navigator.pop(context); // Retourne à la liste des sets

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Magic Set supprimé')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showTrackDetails(BuildContext context, MagicSet set, TrackInfo track) {
    Navigator.pushNamed(
      context,
      AppRoutes.trackDetail,
      arguments: {
        'setId': set.id,
        'track': track,
      },
    );
  }
}
class AddTracksDialog extends ConsumerStatefulWidget {
  final MagicSet currentSet;
  final List<spotify.Track> availableTracks;  // Ajoutez spotify.
  final Set<String> selectedTracks;

  const AddTracksDialog({
    Key? key,
    required this.currentSet,
    required this.availableTracks,
    required this.selectedTracks,
  }) : super(key: key);

  @override
  AddTracksDialogState createState() => AddTracksDialogState();
}
// Ajouter d'abord une classe TrackListItem qu'il manquait :
class _TrackListItem extends ConsumerWidget {
  final TrackInfo track;
  final VoidCallback onTap;
  final Function(Tag) onTagTap;

  const _TrackListItem({
    required this.track,
    required this.onTap,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackData = ref.watch(spotifyTrackProvider(track.trackId));

    return trackData.when(
      data: (spotifyTrack) => ListTile(
        onTap: onTap,
        leading: spotifyTrack.album?.images?.isNotEmpty ?? false
            ? SizedBox(
          width: 40,
          height: 40,
          child: Image.network(  // Ceci utilisera l'Image de Flutter
            spotifyTrack.album!.images!.first.url!,
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.music_note),
        title: Text(spotifyTrack.name ?? 'Sans titre'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spotifyTrack.artists?.map((a) => a.name).join(', ') ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (track.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: track.tags.map((tag) => ActionChip(
                  label: Text(tag.name),
                  backgroundColor: tag.color,
                  labelStyle: const TextStyle(color: Colors.white),
                  onPressed: () => onTagTap(tag),
                )).toList(),
              ),
          ],
        ),
        trailing: Text(_formatDuration(track.duration)),
      ),
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Chargement...'),
      ),
      error: (error, stack) => ListTile(
        leading: const Icon(Icons.error),
        title: Text('Erreur: $error'),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class AddTracksDialogState extends ConsumerState<AddTracksDialog> {
  late Set<String> _selectedTrackIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTrackIds = Set.from(widget.selectedTracks);
  }

  List<spotify.Track> get _filteredTracks {
    if (_searchQuery.trim().isEmpty) return widget.availableTracks;

    final queries = _searchQuery.toLowerCase().trim().split(' ')
        .where((q) => q.isNotEmpty).toList();

    return widget.availableTracks.where((track) {
      if (track.id == null) return false;

      // Construction sécurisée de la chaîne de recherche
      final searchTerms = [
        track.name?.toLowerCase() ?? '', // Utilisation de ?. pour gérer le null
        track.artists?.map((a) => a.name?.toLowerCase() ?? '').join(' ') ?? '',
        track.album?.name?.toLowerCase() ?? '',
        track.id?.toLowerCase() ?? '',
      ];

      final searchString = searchTerms.join(' ');

      // Vérifie si tous les termes de recherche sont présents
      return queries.every((query) => searchString.contains(query));
    }).toList();
  }

// Ajout d'une méthode helper pour trier les résultats par pertinence
  List<spotify.Track> _sortByRelevance(List<spotify.Track> tracks, String query) {
    final queryTerms = query.toLowerCase().trim().split(' ')
        .where((q) => q.isNotEmpty).toList();

    return List<spotify.Track>.from(tracks)..sort((a, b) {
      final aString = [
        a.name?.toLowerCase() ?? '',
        a.artists?.map((artist) => artist.name?.toLowerCase() ?? '').join(' ') ?? '',
      ].join(' ');

      final bString = [
        b.name?.toLowerCase() ?? '',
        b.artists?.map((artist) => artist.name?.toLowerCase() ?? '').join(' ') ?? '',
      ].join(' ');

      // Calcul du score de pertinence
      int aScore = queryTerms.where((term) => aString.contains(term)).length;
      int bScore = queryTerms.where((term) => bString.contains(term)).length;

      // Si les scores sont égaux, trie par nom
      if (aScore == bScore) {
        return (a.name ?? '').compareTo(b.name ?? '');
      }

      return bScore.compareTo(aScore); // Ordre décroissant
    });
  }

// Méthode pour obtenir les résultats filtrés et triés
  List<spotify.Track> getFilteredAndSortedTracks() {
    final filtered = _filteredTracks;
    if (_searchQuery.trim().isEmpty) return filtered;
    return _sortByRelevance(filtered, _searchQuery);
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter des titres'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTracks.length,
                itemBuilder: (context, index) {
                  final track = _filteredTracks[index];
                  final isSelected = _selectedTrackIds.contains(track.id);
                  final artists = track.artists?.map((a) => a.name).where((name) => name != null).join(', ') ?? '';
                  final duration = track.duration ?? Duration.zero;
                  final albumName = track.album?.name;

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true && track.id != null) {
                          _selectedTrackIds.add(track.id!);
                        } else if (track.id != null) {
                          _selectedTrackIds.remove(track.id!);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.name ?? 'Sans titre',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (artists.isNotEmpty)
                          Text(
                            artists,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (albumName != null)
                          Text(
                            albumName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    secondary: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    activeColor: Theme.of(context).primaryColor,
                    selected: isSelected,
                    dense: true,
                  );
                },
              )
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    try {
      final newTracks = widget.availableTracks
          .where((track) => _selectedTrackIds.contains(track.id))
          .map((track) => TrackInfo(
        trackId: track.id!,
        duration: track.duration ?? Duration.zero,
      ))
          .toList();

      var updatedSet = widget.currentSet;
      for (var track in newTracks) {
        updatedSet = updatedSet.addTrack(track);
      }

      await ref.read(magicSetsProvider.notifier).updateSet(updatedSet);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Titres ajoutés avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class TrackDetailsDialog extends ConsumerStatefulWidget {
  final MagicSet set;
  final TrackInfo trackInfo;
  final spotify.Track spotifyTrack;

  const TrackDetailsDialog({
    Key? key,
    required this.set,
    required this.trackInfo,
    required this.spotifyTrack,
  }) : super(key: key);

  @override
  TrackDetailsDialogState createState() => TrackDetailsDialogState();
}

class TrackDetailsDialogState extends ConsumerState<TrackDetailsDialog> {
  late TextEditingController _notesController;
  late List<Tag> _selectedTags;
  late Map<String, dynamic> _customMetadata;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.trackInfo.notes);
    _selectedTags = List.from(widget.trackInfo.tags);
    _customMetadata = Map.from(widget.trackInfo.customMetadata);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.spotifyTrack.name ?? 'Sans titre'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpotifyInfo(),
            const Divider(),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Ajouter des notes...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildTagSelector(),
            const SizedBox(height: 16),
            Text('Métadonnées', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildMetadataEditor(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
  Widget _buildSpotifyInfo() {
    final track = widget.spotifyTrack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.artists?.map((a) => a.name).join(', ') ?? '',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _formatDuration(track.duration ?? Duration.zero),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 16),
            Icon(Icons.audiotrack, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Key: ${_customMetadata['key'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 16),
            Icon(Icons.speed, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'BPM: ${_customMetadata['bpm'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    final tagsAsync = ref.watch(tagsProvider);

    return tagsAsync.when(
      data: (tags) => Wrap(
        spacing: 8,
        children: [
          ...tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              backgroundColor: tag.color.withOpacity(0.2),
              selectedColor: tag.color,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : tag.color,
              ),
            );
          }),
          ActionChip(
            label: const Icon(Icons.add, size: 20),
            onPressed: () => _showTagDetails(context, null),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }

  Widget _buildMetadataEditor() {
    return Column(
      children: [
        _buildMetadataField('key', 'Tonalité'),
        _buildMetadataField('bpm', 'BPM'),
      ],
    );
  }

  Widget _buildMetadataField(String key, String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
      ),
      controller: TextEditingController(text: _customMetadata[key]?.toString() ?? ''),
      onChanged: (value) {
        setState(() {
          _customMetadata[key] = value;
        });
      },
    );
  }

  Future<void> _saveChanges() async {
    try {
      final updatedTrack = widget.trackInfo.copyWith(
        notes: _notesController.text,
        tags: _selectedTags,
        customMetadata: _customMetadata,
      );

      final updatedSet = widget.set.updateTrack(updatedTrack);
      await ref.read(magicSetsProvider.notifier).updateSet(updatedSet);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showTagDetails(BuildContext context, Tag? tag) {
    showDialog(
      context: context,
      builder: (context) => TagDetailsDialog(tag: tag),
    );
  }
}

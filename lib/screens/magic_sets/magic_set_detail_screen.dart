// lib/screens/magic_sets/magic_set_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/magic_set_models.dart';
import '../../providers/unified_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/unified_widgets.dart';
import 'package:spotify/spotify.dart' hide Player;
import '../../providers/magic_set_providers.dart';

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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
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
          Text('Tags', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: set.tags.map((tag) => Chip(
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

  void _editSet(BuildContext context, MagicSet set) {
    Navigator.pushNamed(context, '/magic-set-editor', arguments: set);
  }

  Future<void> _showOptionsMenu(BuildContext context, MagicSet set) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (set.isTemplate)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Créer depuis le modèle'),
              onTap: () => Navigator.pop(context, 'create_from_template'),
            ),
          if (!set.isTemplate)
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Convertir en modèle'),
              onTap: () => Navigator.pop(context, 'convert_to_template'),
            ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Supprimer'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (result) {
      case 'create_from_template':
        await _createFromTemplate(context, set);
        break;
      case 'convert_to_template':
        await _convertToTemplate(context, set);
        break;
      case 'delete':
        await _confirmDelete(context, set);
        break;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showAddTracksDialog(BuildContext context, MagicSet set) async {
    // Implémentation à venir
  }

  Future<void> _showTrackDetails(BuildContext context, MagicSet set, TrackInfo track) async {
    // Implémentation à venir
  }

  void _showTagDetails(BuildContext context, Tag tag) {
    // Implémentation à venir
  }

  Future<void> _createFromTemplate(BuildContext context, MagicSet template) async {
    final playlists = ref.read(playlistsProvider).items;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer depuis le modèle'),
        content: DropdownButtonFormField<String>(
          value: null,
          items: playlists.map((playlist) {
            return DropdownMenuItem(
              value: playlist.id,
              child: Text(playlist.name ?? 'Sans nom'),
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Sélectionnez une playlist',
          ),
          onChanged: (value) => Navigator.pop(context, value),
        ),
      ),
    );

    if (result != null) {
      final newSet = MagicSet.fromTemplate(template, result);
      await ref.read(magicSetsProvider.notifier).createSet(
        newSet.name,
        newSet.playlistId,
        description: newSet.description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouveau Magic Set créé avec succès !')),
        );
      }
    }
  }

  Future<void> _convertToTemplate(BuildContext context, MagicSet set) async {
    final updatedSet = set.copyWith(
      isTemplate: true,
      updatedAt: DateTime.now(),
    );

    await ref.read(magicSetsProvider.notifier).updateSet(updatedSet);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Converti en modèle avec succès !')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, MagicSet set) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le Magic Set "${set.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(magicSetsProvider.notifier).deleteSet(set.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _TrackListItem extends StatelessWidget {
  final TrackInfo track;
  final VoidCallback onTap;
  final Function(Tag) onTagTap;

  const _TrackListItem({
    Key? key,
    required this.track,
    required this.onTap,
    required this.onTagTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.music_note),
      title: Text(track.trackId), // À remplacer par le vrai nom de la track
      subtitle: track.tags.isEmpty
          ? null
          : Wrap(
        spacing: 4,
        children: track.tags.map((tag) => GestureDetector(
          onTap: () => onTagTap(tag),
          child: Chip(
            label: Text(tag.name),
            backgroundColor: tag.color.withOpacity(0.7),
            labelStyle: const TextStyle(color: Colors.white),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )).toList(),
      ),
      trailing: track.notes.isNotEmpty
          ? const Icon(Icons.note, color: Colors.grey)
          : null,
    );
  }
}
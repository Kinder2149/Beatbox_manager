// lib/screens/magic_sets/track_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/magic_set_models.dart';
import '../../providers/magic_set_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/unified_widgets.dart';
import 'package:beatbox_manager/screens/magic_sets/tag_manager_screen.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../../utils/unified_utils.dart';

class TrackDetailScreen extends ConsumerStatefulWidget {
  final String setId;
  final TrackInfo track;

  const TrackDetailScreen({
    Key? key,
    required this.setId,
    required this.track,
  }) : super(key: key);

  @override
  TrackDetailScreenState createState() => TrackDetailScreenState();
}

class TrackDetailScreenState extends ConsumerState<TrackDetailScreen>
    with UnsavedChangesMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  List<Tag> _selectedTags = [];
  bool _isLoading = false;
  Map<String, dynamic> _originalValues = {};

  @override
  void initState() {
    super.initState();
    _originalValues = {
      'notes': widget.track.notes,
      'tags': List<Tag>.from(widget.track.tags),
      'metadata': Map<String, dynamic>.from(widget.track.customMetadata),
    };

    // Ajoutez le listener pour détecter les changements
    _notesController.addListener(() {
      hasUnsavedChanges = _hasChanges();
    });
  }

  bool _hasChanges() {
    return _notesController.text != _originalValues['notes'] ||
        !listEquals(_selectedTags, _originalValues['tags']);
  }


  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => onWillPop(),
    child: Scaffold(
    appBar: AppBar(
    title: const Text('Détails du titre'),
    actions: [
    IconButton(
    icon: const Icon(Icons.save),
    onPressed: _handleSave,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: _isLoading
            ? const LoadingIndicator(message: 'Sauvegarde en cours...')
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrackInfo(),
                const SizedBox(height: 24),
                _buildNotesSection(),
                const SizedBox(height: 24),
                _buildTagsSection(),
                const SizedBox(height: 24),
                _buildMetadataSection(),
              ],
            ),
          ),
        ),
      ),
    )
   );
  }

  Widget _buildTrackInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Durée: ${widget.track.duration.toString()}'),
            if (widget.track.key != null)
              Text('Tonalité: ${widget.track.key}'),
            if (widget.track.bpm != null)
              Text('BPM: ${widget.track.bpm}'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Ajoutez vos notes ici...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  onPressed: _showTagSelector,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags.map((tag) {
                return Chip(
                  label: Text(tag.name),
                  backgroundColor: tag.color,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _selectedTags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métadonnées',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Affichez ici les métadonnées personnalisées
            ...widget.track.customMetadata.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(entry.value.toString()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showTagSelector() async {
    final result = await Navigator.push<List<Tag>>(
      context,
      MaterialPageRoute(
        builder: (context) => TagManagerScreen(
          initialSelectedTags: _selectedTags,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
      });
    }
  }
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedTrack = widget.track.copyWith(
        notes: _notesController.text,
        tags: _selectedTags,
      );

      await ref.read(magicSetsProvider.notifier).updateTrack(
        widget.setId,
        updatedTrack,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Future<void> saveChanges() async {
    await _handleSave();
  }
}
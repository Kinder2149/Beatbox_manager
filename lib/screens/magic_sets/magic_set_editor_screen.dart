// lib/screens/magic_sets/magic_set_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/magic_set_models.dart';
import '../../providers/unified_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/unified_widgets.dart';
import 'package:spotify/spotify.dart';
import 'package:beatbox_manager/providers/magic_set_providers.dart';
import 'package:beatbox_manager/utils/unified_utils.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../../utils/unified_utils.dart';



class MagicSetEditorScreen extends ConsumerStatefulWidget {
  final MagicSet? set;

  const MagicSetEditorScreen({Key? key, this.set}) : super(key: key);

  @override
  MagicSetEditorScreenState createState() => MagicSetEditorScreenState();
}

class MagicSetEditorScreenState extends ConsumerState<MagicSetEditorScreen>
    with UnsavedChangesMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedPlaylistId;
  List<Tag> _selectedTags = [];
  bool _isTemplate = false;
  bool _isSaving = false;
  Map<String, dynamic> _originalValues = {};

  @override
  void initState() {
    super.initState();
    _originalValues = {
      'name': widget.set?.name ?? '',
      'description': widget.set?.description ?? '',
      'tags': List<Tag>.from(widget.set?.tags ?? []),
      'isTemplate': widget.set?.isTemplate ?? false,
    };
    _nameController = TextEditingController(text: widget.set?.name ?? '');
    _descriptionController = TextEditingController(text: widget.set?.description ?? '');
    _selectedTags = List.from(widget.set?.tags ?? []);

    // Ajouter les listeners pour détecter les changements
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }
  void _onFieldChanged() {
    hasUnsavedChanges = true;
  }
  void _onTagsChanged(List<Tag> tags) {
    setState(() {
      _selectedTags = tags;
      hasUnsavedChanges = true;
    });
  }
  bool _hasChanges() {
    return _nameController.text != _originalValues['name'] ||
        _descriptionController.text != _originalValues['description'] ||
        !listEquals(_selectedTags, _originalValues['tags']) ||
        _isTemplate != _originalValues['isTemplate'];
  }

  @override
  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _saveSet(context);
      hasUnsavedChanges = false;
    } finally {
      setState(() => _isSaving = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final playlistItems = playlists.items;

    return WillPopScope(
        onWillPop: () => onWillPop(),
    child: Scaffold(
      appBar: AppBar(
        title: Text(
            widget.set == null ? 'Nouveau Magic Set' : 'Modifier Magic Set'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveSet(context),
            ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBasicInfo(playlistItems),  // Utilisation de la bonne variable
              const SizedBox(height: 24),
              _buildTagsSection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
            ],
          ),
        ),
      ),
    ),
    );
  }


  Widget _buildBasicInfo(List<PlaylistSimple> playlists) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de base',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Entrez le nom du Magic Set',
                prefixIcon: Icon(Icons.edit),
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
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlaylistId,
              decoration: const InputDecoration(
                labelText: 'Playlist source',
                prefixIcon: Icon(Icons.playlist_play),
              ),
              items: playlists.map((playlist) =>
                  DropdownMenuItem(
                    value: playlist.id,
                    child: Text(
                      playlist.name ?? 'Sans nom',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
              onChanged: widget.set != null ? null : (value) {
                setState(() => _selectedPlaylistId = value);
              },
              validator: (value) {
                if (value == null && widget.set == null) {
                  return 'Une playlist est requise';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Gérer'),
                  onPressed: _showTagManager,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedTags.isEmpty)
              const Text(
                'Aucun tag sélectionné',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTags.map((tag) =>
                    Chip(
                      label: Text(tag.name),
                      backgroundColor: tag.color,
                      labelStyle: const TextStyle(color: Colors.white),
                      onDeleted: () {
                        setState(() {
                          _selectedTags.remove(tag);
                        });
                      },
                    )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Utiliser comme modèle'),
              subtitle: const Text(
                  'Les modèles peuvent être utilisés pour créer rapidement de nouveaux Magic Sets'
              ),
              value: _isTemplate,
              onChanged: (value) {
                setState(() => _isTemplate = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTagManager() async {
    final result = await Navigator.pushNamed(
      context,
      '/tag-manager',
      arguments: _selectedTags,
    );

    if (result is List<Tag>) {
      setState(() {
        _selectedTags = result;
      });
    }
  }

  // Modification du _saveSet
  Future<void> _saveSet(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newSet = widget.set?.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        tags: _selectedTags,
        isTemplate: _isTemplate,
        updatedAt: DateTime.now(),
      ) ?? MagicSet.create(
        name: _nameController.text,
        playlistId: _selectedPlaylistId!,
        description: _descriptionController.text,
        tags: _selectedTags,
        isTemplate: _isTemplate,
      );

      if (widget.set != null) {
        await ref.read(magicSetsProvider.notifier).updateSet(newSet);
      } else {
        await ref.read(magicSetsProvider.notifier).createSet(
          newSet.name,
          newSet.playlistId,
          description: newSet.description,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Magic Set sauvegardé avec succès !')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
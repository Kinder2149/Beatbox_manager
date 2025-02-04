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
import 'package:flutter/foundation.dart' show listEquals, mapEquals;


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
  final TextEditingController _notesController = TextEditingController();
  List<Tag> _selectedTags = [];
  bool _isLoading = false;
  Map<String, dynamic> _originalValues = {};
  Map<String, dynamic> _customMetadata = {};


  @override
  void initState() {
    super.initState();
    _notesController.text = widget.track.notes;
    _selectedTags = List.from(widget.track.tags);
    _customMetadata = Map.from(widget.track.customMetadata);

    // Ajouter l'initialisation des valeurs originales
    _originalValues = {
      'notes': widget.track.notes,
      'tags': List.from(widget.track.tags),
      'customMetadata': Map.from(widget.track.customMetadata),
    };

    _notesController.addListener(() {
      hasUnsavedChanges = _hasChanges();
    });
  }

  bool _hasChanges() {
    return _notesController.text != _originalValues['notes'] ||
        !listEquals(_selectedTags, _originalValues['tags']) ||
        !mapEquals(_customMetadata, _originalValues['customMetadata']);
  }


  @override
  void dispose() {
    _saveChanges(); // Sauvegarde automatique à la fermeture
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updatedTrack = widget.track.copyWith(
      notes: _notesController.text.trim(),
      tags: _selectedTags,
      customMetadata: _customMetadata,
    );

    try {
      await ref.read(magicSetsProvider.notifier).updateTrack(
        widget.setId,
        updatedTrack,
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Sauvegarde avant de quitter
          await _saveChanges();
          return true;
        },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Métadonnées',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddMetadataDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._customMetadata.entries.map((entry) => _buildMetadataItem(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(MapEntry<String, dynamic> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(entry.key),
          Row(
            children: [
              Text(entry.value.toString()),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editMetadata(entry.key),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () => _deleteMetadata(entry.key),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _showAddMetadataDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => MetadataDialog(),
    );

    if (result != null) {
      final key = result['key']!;
      final value = result['value']!;

      // Valider avant d'ajouter
      final keyError = MetadataValidator.validateKey(key);
      final valueError = MetadataValidator.validateValue(value, key);

      if (keyError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(keyError)),
          );
        }
        return;
      }

      if (valueError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(valueError)),
          );
        }
        return;
      }

      setState(() {
        _customMetadata[key] = value;
        hasUnsavedChanges = _hasChanges();
      });
    }
  }

  void _deleteMetadata(String key) {
    setState(() {
      _customMetadata.remove(key);
      hasUnsavedChanges = _hasChanges();
    });
  }

  Future<void> _editMetadata(String key) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => MetadataDialog(
        initialKey: key,
        initialValue: _customMetadata[key].toString(),
      ),
    );

    if (result != null) {
      setState(() {
        _customMetadata.remove(key);
        _customMetadata[result['key']!] = result['value'];
        hasUnsavedChanges = _hasChanges();
      });
    }
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
class MetadataDialog extends StatefulWidget {
  final String? initialKey;
  final String? initialValue;

  const MetadataDialog({
    Key? key,
    this.initialKey,
    this.initialValue,
  }) : super(key: key);

  @override
  MetadataDialogState createState() => MetadataDialogState();
}

class MetadataDialogState extends State<MetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.text = widget.initialKey ?? '';
    _valueController.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialKey != null ? 'Modifier la métadonnée' : 'Ajouter une métadonnée'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Clé',
                hintText: 'ex: BPM, Key, Energy...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La clé est requise';
                }
                return null;
              },
              enabled: widget.initialKey == null, // Désactiver si en mode édition
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Valeur',
                hintText: 'Valeur de la métadonnée',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La valeur est requise';
                }
                return null;
              },
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
          onPressed: _submit,
          child: Text(widget.initialKey != null ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'key': _keyController.text,
        'value': _valueController.text,
      });
    }
  }
}
class MetadataValidator {
  static const Set<String> reservedKeys = {
    'bpm',
    'key',
    'energy',
    'mode',
    'tempo',
  };

  static String? validateKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'La clé est requise';
    }
    if (reservedKeys.contains(value.toLowerCase())) {
      return 'Cette clé est réservée';
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(value)) {
      return 'La clé doit commencer par une lettre et ne contenir que des lettres, chiffres et _';
    }
    return null;
  }

  static String? validateValue(String? value, String key) {
    if (value == null || value.isEmpty) {
      return 'La valeur est requise';
    }

    // Validation spécifique selon le type de métadonnée
    switch (key.toLowerCase()) {
      case 'bpm':
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          return 'Le BPM doit être un nombre';
        }
        final bpm = int.tryParse(value);
        if (bpm == null || bpm < 0 || bpm > 300) {
          return 'BPM invalide (0-300)';
        }
        break;
      case 'key':
        if (!RegExp(r'^[A-G][b#]?m?$').hasMatch(value)) {
          return 'Format de tonalité invalide (ex: Am, C#, Gb)';
        }
        break;
    }

    return null;
  }
}
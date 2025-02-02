// lib/screens/magic_sets/template_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/magic_set_models.dart';
import '../../providers/unified_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/unified_widgets.dart';
import 'package:beatbox_manager/providers/magic_set_providers.dart';
import 'package:beatbox_manager/utils/unified_utils.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final MagicSet template;

  const TemplateEditorScreen({
    Key? key,
    required this.template,
  }) : super(key: key);

  @override
  TemplateEditorScreenState createState() => TemplateEditorScreenState();
}

class TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<Tag> _selectedTags;
  late Map<String, dynamic> _metadata;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _descriptionController = TextEditingController(text: widget.template.description);
    _selectedTags = List.from(widget.template.tags);
    _metadata = Map.from(widget.template.metadata);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markAsUnsaved() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Éditer le template'),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveTemplate,
              ),
          ],
        ),
        body: Container(
          decoration: AppTheme.gradientBackground,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildTagsSection(),
              const SizedBox(height: 24),
              _buildMetadataSection(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMetadataDialog,
          child: const Icon(Icons.add),
          tooltip: 'Ajouter une métadonnée',
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de base',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du template',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _markAsUnsaved(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _markAsUnsaved(),
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
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  onPressed: _showTagSelector,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedTags.isEmpty)
              const Center(
                child: Text(
                  'Aucun tag sélectionné',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTags.map((tag) => Chip(
                  label: Text(tag.name),
                  backgroundColor: tag.color.withOpacity(0.2),
                  labelStyle: TextStyle(color: tag.color),
                  onDeleted: () {
                    setState(() {
                      _selectedTags.remove(tag);
                      _markAsUnsaved();
                    });
                  },
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métadonnées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_metadata.isEmpty)
              const Center(
                child: Text(
                  'Aucune métadonnée définie',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _metadata.length,
                itemBuilder: (context, index) {
                  final key = _metadata.keys.elementAt(index);
                  final value = _metadata[key];
                  return ListTile(
                    title: Text(key),
                    subtitle: Text(value.toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _metadata.remove(key);
                          _markAsUnsaved();
                        });
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTagSelector() async {
    final result = await showDialog<List<Tag>>(
      context: context,
      builder: (context) => TagSelectorDialog(
        selectedTags: _selectedTags,
        availableTags: ref.read(tagsProvider).value ?? [],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
        _markAsUnsaved();
      });
    }
  }

  Future<void> _showAddMetadataDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddMetadataDialog(),
    );

    if (result != null) {
      setState(() {
        _metadata[result['key']] = result['value'];
        _markAsUnsaved();
      });
    }
  }

  Future<bool> _onWillPop() async {
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveTemplate();
    }

    return true;
  }

  Future<void> _saveTemplate() async {
    try {
      final updatedTemplate = widget.template.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        tags: _selectedTags,
        metadata: _metadata,
        updatedAt: DateTime.now(),
      );

      await ref.read(magicSetsProvider.notifier).updateSet(updatedTemplate);

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template sauvegardé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }
}

// Dialogs supplémentaires nécessaires
class TagSelectorDialog extends StatefulWidget {
  final List<Tag> selectedTags;
  final List<Tag> availableTags;

  const TagSelectorDialog({
    Key? key,
    required this.selectedTags,
    required this.availableTags,
  }) : super(key: key);

  @override
  TagSelectorDialogState createState() => TagSelectorDialogState();
}

class TagSelectorDialogState extends State<TagSelectorDialog> {
  late List<Tag> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner les tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.availableTags.length,
          itemBuilder: (context, index) {
            final tag = widget.availableTags[index];
            final isSelected = _selectedTags.any((t) => t.id == tag.id);
            return CheckboxListTile(
              value: isSelected,
              title: Text(tag.name),
              subtitle: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tag.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.removeWhere((t) => t.id == tag.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedTags),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class AddMetadataDialog extends StatefulWidget {
  const AddMetadataDialog({Key? key}) : super(key: key);

  @override
  AddMetadataDialogState createState() => AddMetadataDialogState();
}

class AddMetadataDialogState extends State<AddMetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une métadonnée'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Clé',
                hintText: 'Nom de la métadonnée',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La clé est requise';
                }
                return null;
              },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'key': _keyController.text,
                'value': _valueController.text,
              });
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
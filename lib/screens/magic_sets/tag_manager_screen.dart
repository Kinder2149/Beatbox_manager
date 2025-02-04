// lib/screens/magic_sets/tag_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/magic_set_models.dart';
import '../../providers/unified_providers.dart';
import '../../theme/app_theme.dart';
import 'package:beatbox_manager/providers/magic_set_providers.dart';
import 'package:beatbox_manager/widgets/tag_details_dialog.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../../utils/unified_utils.dart';


class TagManagerScreen extends ConsumerStatefulWidget {
  final List<Tag>? initialSelectedTags;

  const TagManagerScreen({
    Key? key,
    this.initialSelectedTags,
  }) : super(key: key);

  @override
  TagManagerScreenState createState() => TagManagerScreenState();
}

class TagManagerScreenState extends ConsumerState<TagManagerScreen>
    with UnsavedChangesMixin {
  List<Tag> _selectedTags = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  TagScope _selectedScope = TagScope.track;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      hasUnsavedChanges = _nameController.text.isNotEmpty || _isEditing;
    });
  }
  @override
  Future<void> saveChanges() async {
    if (_isEditing) {
      return _createTag();
    }
    return Future.value();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsProvider);

    return WillPopScope(
      onWillPop: () => onWillPop(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Tags'),
          actions: [
            if (widget.initialSelectedTags != null)
              TextButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Terminer', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context, _selectedTags),
              ),
          ],
        ),
        body: Container(
          decoration: AppTheme.gradientBackground,
          child: tagsState.when(
            data: (tags) => _buildTagsList(tags),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
          ),
        ),
        floatingActionButton: _buildActionButton(),
      ),
    );
  }

  Widget _buildTagCreator() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Créer un nouveau tag',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du tag',
                        hintText: 'Entrez le nom du tag',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildColorPicker(),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createTag,
                icon: const Icon(Icons.add),
                label: const Text('Créer le tag'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.spotifyGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _selectedColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
        child: const Icon(
          Icons.colorize,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTagsList(List<Tag> allTags) {
    if (allTags.isEmpty) {
      return const Center(
        child: Text(
          'Aucun tag créé\nAppuyez sur + pour en créer un',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: allTags.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final tag = allTags[index];
        final isSelected = _selectedTags.contains(tag);

        return Card(
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(tag.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.initialSelectedTags != null)
                  Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTag(tag),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTag(tag),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une couleur'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() => _selectedColor = color);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selectedColor),
              child: const Text('Sélectionner'),
            ),
          ],
        );
      },
    );

    if (color != null) {
      setState(() => _selectedColor = color);
    }
  }
  Widget _buildActionButton() {
    return FloatingActionButton(
      onPressed: () => _showCreateTagDialog(context),
      child: const Icon(Icons.add),
      backgroundColor: AppTheme.spotifyGreen,
    );
  }
  // Dans TagManagerScreen
  Future<void> _showCreateTagDialog(BuildContext context) async {
    setState(() => _isEditing = true);
    try {
      // Vérifier si le tag existe déjà
      final existingTags = ref.read(tagsProvider).value ?? [];
      if (existingTags.any((tag) => tag.name.toLowerCase() == _nameController.text.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un tag avec ce nom existe déjà')),
        );
        return;
      }
    _nameController.clear();
    setState(() => _selectedColor = Colors.blue);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un nouveau tag'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du tag',
                  hintText: 'Entrez le nom du tag',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildColorPicker(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result == true && _formKey.currentState!.validate()) {
      await _createTag();
    }
    } finally {
      setState(() => _isEditing = false);
    }
  }


  Future<void> _createTag() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation supplémentaire
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du tag ne peut pas être vide')),
      );
      return;
    }

    final newTag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      color: _selectedColor,
      scope: _selectedScope, // Utilisation de _selectedScope au lieu de PLAYLIST
    );

    try {
      await ref.read(tagsProvider.notifier).addTag(newTag);

      // Réinitialisation du formulaire
      _nameController.clear();
      setState(() {
        _selectedColor = Colors.blue;
        _selectedScope = TagScope.track; // Réinitialisation du scope
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tag créé avec succès !'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Ferme le dialogue si on est dans un dialogue
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du tag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  void _resetForm() {
    _nameController.clear();
    setState(() {
      _selectedColor = Colors.blue;
      _selectedScope = TagScope.track;
      _isEditing = false;
    });
  }

  Future<void> _updateTag(Tag tag) async {
    final updatedTag = tag.copyWith(
      name: _nameController.text,
      color: _selectedColor,
    );

    try {
      await ref.read(tagsProvider.notifier).updateTag(updatedTag);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag mis à jour avec succès !')),
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

  Future<void> _editTag(Tag tag) async {
    _nameController.text = tag.name;
    _selectedColor = tag.color;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le tag'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du tag'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildColorPicker(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result == true && _formKey.currentState!.validate()) {
      final updatedTag = tag.copyWith(
        name: _nameController.text,
        color: _selectedColor,
      );

      try {
        await ref.read(tagsProvider.notifier).updateTag(updatedTag);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tag mis à jour avec succès !'),
              backgroundColor: AppTheme.spotifyGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour du tag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    _nameController.clear();
    setState(() => _selectedColor = Colors.blue);
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le tag "${tag.name}" ?'),
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
      try {
        await ref.read(tagsProvider.notifier).deleteTag(tag.id);
        setState(() {
          _selectedTags.remove(tag);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tag supprimé avec succès !'),
              backgroundColor: AppTheme.spotifyGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression du tag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Widget pour le sélecteur de couleur
class ColorPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: pickerColor == color
                    ? Colors.white
                    : Colors.grey.shade300,
                width: pickerColor == color ? 2 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
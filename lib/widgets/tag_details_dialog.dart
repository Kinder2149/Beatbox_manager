import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/magic_set_models.dart';
import '../providers/unified_providers.dart';

class TagDetailsDialog extends ConsumerStatefulWidget {
  final Tag? tag;

  const TagDetailsDialog({
    Key? key,
    this.tag,
  }) : super(key: key);

  @override
  TagDetailsDialogState createState() => TagDetailsDialogState();
}

class TagDetailsDialogState extends ConsumerState<TagDetailsDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late TagScope _selectedScope;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _selectedColor = widget.tag?.color ?? Colors.blue;
    _selectedScope = widget.tag?.scope ?? TagScope.track;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'Nouveau tag' : 'Modifier le tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du tag',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TagScope>(
            value: _selectedScope,
            decoration: const InputDecoration(
              labelText: 'Portée',
            ),
            items: TagScope.values.map((scope) {
              return DropdownMenuItem(
                value: scope,
                child: Text(scope.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedScope = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final color = await showColorPicker();
              if (color != null) {
                setState(() {
                  _selectedColor = color;
                });
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(_selectedColor),
            ),
            child: const Text('Choisir une couleur'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveTag,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<Color?> showColorPicker() async {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
            ].map((color) => InkWell(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTag() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du tag est requis')),
      );
      return;
    }

    final tag = Tag(
      id: widget.tag?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      color: _selectedColor,
      scope: _selectedScope,
    );

    try {
      if (widget.tag == null) {
        await ref.read(tagsProvider.notifier).addTag(tag);
      } else {
        await ref.read(tagsProvider.notifier).updateTag(tag);
      }

      if (mounted) {
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
}
import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Player;

class PlaylistSelectionDialog extends StatelessWidget {
  final List<PlaylistSimple> playlists;

  const PlaylistSelectionDialog({
    Key? key,
    required this.playlists,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              title: Text(playlist.name ?? 'Sans nom'),
              onTap: () => Navigator.pop(context, playlist.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
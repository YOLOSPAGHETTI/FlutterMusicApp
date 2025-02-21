import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:music_app/components/text_marquee.dart';
import 'package:music_app/models/music_provider.dart';

class AddToPlaylistMenuItem extends PopupMenuItem<String> {
  final MusicProvider musicProvider;
  final bool isSong;
  final String listItem;

  AddToPlaylistMenuItem({
    super.key,
    required this.musicProvider,
    required this.isSong,
    required this.listItem,
  }) : super(
          child: _AddToPlaylistMenuItemContent(
            musicProvider: musicProvider,
            isSong: isSong,
            listItem: listItem,
          ),
        );
}

class _AddToPlaylistMenuItemContent extends StatelessWidget {
  final MusicProvider musicProvider;
  final bool isSong;
  final String listItem;

  const _AddToPlaylistMenuItemContent({
    required this.musicProvider,
    required this.isSong,
    required this.listItem,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close the menu before opening dialog

        LinkedHashSet<String> playlists = musicProvider.playlists;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Add To Playlist",
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
              content: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: TextMarquee(
                      text: playlists.elementAt(index),
                      style: TextStyle(),
                      maxWidth: 250,
                    ),
                    onTap: () {
                      if (isSong) {
                        musicProvider.addSongToPlaylist(
                            index, int.parse(listItem));
                      } else {
                        musicProvider.addSongsToPlaylist(index, listItem);
                      }
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
      child: Text('Add To Playlist'),
    );
  }
}

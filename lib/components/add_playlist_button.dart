import 'package:flutter/material.dart';
import 'package:music_app/models/music_provider.dart';

class AddPlaylistButton extends StatelessWidget {
  final MusicProvider musicProvider;
  const AddPlaylistButton({super.key, required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    TextEditingController addPlaylistController = TextEditingController();

    return IconButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                String errorMessage = "";

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    void pop() {
                      Navigator.of(context).pop();
                    }

                    void addPlaylist() async {
                      if (addPlaylistController.text.isEmpty) {
                        setState(() {
                          errorMessage = "Please give the playlist a name.";
                        });
                        return;
                      }
                      bool exists = await musicProvider
                          .addPlaylist(addPlaylistController.text);

                      if (exists) {
                        setState(() {
                          errorMessage =
                              "A playlist with this name already exists.";
                        });
                        return;
                      }
                      setState(() {
                        errorMessage = "";
                      });
                      pop();
                    }

                    return AlertDialog(
                      title: Text("Create Playlist",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary)),
                      content: SizedBox(
                        height: 100,
                        width: 200,
                        child: Column(
                          children: [
                            Expanded(
                                child: TextField(
                                    controller: addPlaylistController)),
                            Text(
                              errorMessage,
                              style: TextStyle(color: Colors.red),
                            )
                          ],
                        ),
                      ),
                      actions: [
                        Row(children: [
                          TextButton(
                            onPressed: () {
                              addPlaylist();
                            },
                            child: Text('ADD'),
                          ),
                          SizedBox(width: 50),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                errorMessage = "";
                              });
                              pop(); // Close the dialog
                            },
                            child: Text('CANCEL'),
                          ),
                        ])
                      ],
                    );
                  },
                );
              });
        },
        icon: Icon(Icons.add));
  }
}

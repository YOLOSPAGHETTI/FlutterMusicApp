import 'package:flutter/material.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/error_handler.dart';
import 'package:music_app/models/music_provider.dart';

class AddPlaylistButton extends StatelessWidget {
  final MusicProvider musicProvider;
  const AddPlaylistButton({super.key, required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    TextEditingController addPlaylistController = TextEditingController();
    ErrorHandler errorHandler = ErrorHandler();

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
                          errorHandler
                              .addMessage(missingPlaylistNameErrorMessage);
                          errorMessage = errorHandler.getErrorMessage();
                        });
                        return;
                      }
                      String name = addPlaylistController.text;
                      bool exists = await musicProvider.playlistExists(name);

                      if (exists) {
                        setState(() {
                          errorHandler
                              .addMessage(duplicatePlaylistNameErrorMessage);
                          errorMessage = errorHandler.getErrorMessage();
                        });
                        return;
                      } else {
                        await musicProvider.addPlaylist(name, false);
                      }
                      setState(() {
                        errorHandler
                            .removeMessage(missingPlaylistNameErrorMessage);
                        errorHandler
                            .removeMessage(duplicatePlaylistNameErrorMessage);
                        errorMessage = errorHandler.getErrorMessage();
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

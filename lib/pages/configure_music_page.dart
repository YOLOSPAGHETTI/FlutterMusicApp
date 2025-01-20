import 'package:flutter/material.dart';
import 'package:music_app/components/info_button_popup.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/components/text_field_list.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/pages/sync_music_page.dart';
import 'package:provider/provider.dart';

class ConfigureMusicPage extends StatefulWidget {
  final bool firstConfigure;
  const ConfigureMusicPage({super.key, required this.firstConfigure});

  @override
  State<ConfigureMusicPage> createState() => _ConfigureMusicPageState();
}

class _ConfigureMusicPageState extends State<ConfigureMusicPage> {
  List<TextEditingController> artistDelimiterControllers =
      <TextEditingController>[];
  List<TextEditingController> genreDelimiterControllers =
      <TextEditingController>[];
  List<String> songContainers = <String>[];
  List<String> artistContainers = <String>[];
  Map<String, List<TextEditingController>> songIgnoreControllers = {};
  Map<String, List<TextEditingController>> artistIgnoreControllers = {};

  @override
  void initState() {
    for (String container in containers) {
      songIgnoreControllers[container] = <TextEditingController>[];

      artistIgnoreControllers[container] = <TextEditingController>[];
    }

    super.initState();

    populatePageFromDatabase();
  }

  void populatePageFromDatabase() async {
    DatabaseHelper db = DatabaseHelper();
    List<Map<String, Object?>> resultsSeparateField =
        await db.customQuery("SELECT * FROM $tableSeparateFieldSettings", []);
    List<Map<String, Object?>> resultsFieldContainer =
        await db.customQuery("SELECT * FROM $tableFieldContainerSettings", []);

    setState(() {
      for (Map<String, Object?> row in resultsSeparateField) {
        if (row[columnField].toString() == columnArtist) {
          artistDelimiterControllers.add(
              TextEditingController(text: row[columnDelimiter].toString()));
        } else if (row[columnField] == columnGenre) {
          genreDelimiterControllers.add(
              TextEditingController(text: row[columnDelimiter].toString()));
        }
      }

      if (artistDelimiterControllers.isEmpty) {
        artistDelimiterControllers.add(TextEditingController());
      }
      if (genreDelimiterControllers.isEmpty) {
        genreDelimiterControllers.add(TextEditingController());
      }

      for (Map<String, Object?> row in resultsFieldContainer) {
        String container = row[columnContainer].toString();
        if (row[columnField].toString() == columnTitle) {
          if (!songContainers.contains(container)) {
            songContainers.add(container);
          }
          songIgnoreControllers[container]!.add(
              TextEditingController(text: row[columnIgnoreText].toString()));
        } else if (row[columnField].toString() == columnArtist) {
          artistIgnoreControllers[container]!.add(
              TextEditingController(text: row[columnIgnoreText].toString()));
        }
      }

      for (String container in containers) {
        if (songIgnoreControllers[container]!.isEmpty) {
          songIgnoreControllers[container]!.add(TextEditingController());
        }
        if (artistIgnoreControllers[container]!.isEmpty) {
          artistIgnoreControllers[container]!.add(TextEditingController());
        }
      }

      print("populatePageFromDatabase::isEmpty: " +
          artistDelimiterControllers.isEmpty.toString());
    });
  }

  void goToSyncMusicPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      // Turn controller map into String List map
      List<String> artistDelimiters = <String>[];
      List<String> genreDelimiters = <String>[];
      Map<String, List<String>> songIgnoreText = {};
      Map<String, List<String>> artistIgnoreText = {};

      for (TextEditingController controller in artistDelimiterControllers) {
        if (controller.text.isNotEmpty) {
          artistDelimiters.add(controller.text);
        }
      }

      for (TextEditingController controller in genreDelimiterControllers) {
        if (controller.text.isNotEmpty) {
          genreDelimiters.add(controller.text);
        }
      }

      for (String container in songContainers) {
        songIgnoreText[container] = <String>[];

        for (TextEditingController controller
            in songIgnoreControllers[container]!) {
          if (controller.text.isNotEmpty) {
            songIgnoreText[container]!.add(controller.text);
          }
        }
      }

      for (String container in artistContainers) {
        artistIgnoreText[container] = <String>[];

        for (TextEditingController controller
            in artistIgnoreControllers[container]!) {
          if (controller.text.isNotEmpty) {
            artistIgnoreText[container]!.add(controller.text);
          }
        }
      }

      return SyncMusicPage(
          artistDelimiters: artistDelimiters,
          genreDelimiters: genreDelimiters,
          songContainers: songContainers,
          artistContainers: artistContainers,
          songIgnoreText: songIgnoreText,
          artistIgnoreText: artistIgnoreText);
    }));
  }

  void addArtistDelimiters(TextEditingController controller, String listType) {
    setState(() {
      artistDelimiterControllers.add(controller);
    });
  }

  void removeArtistDelimitersAfterIndex(int index, String listType) {
    setState(() {
      print(index);
      for (int i = index; i < artistDelimiterControllers.length - 1; i++) {
        if (artistDelimiterControllers.length > i) {
          artistDelimiterControllers.removeAt(i);
        }
      }
    });
  }

  void addSongIgnoreText(TextEditingController controller, String listType) {
    setState(() {
      songIgnoreControllers[listType]!.add(controller);
    });
  }

  void removeSongIgnoreTextAfterIndex(int index, String listType) {
    setState(() {
      for (int i = index; i < songIgnoreControllers.length - 1; i++) {
        if (songIgnoreControllers[listType]!.length > i) {
          songIgnoreControllers[listType]!.removeAt(i);
        }
      }
    });
  }

  void addArtistIgnoreText(TextEditingController controller, String listType) {
    setState(() {
      artistIgnoreControllers[listType]!.add(controller);
    });
  }

  void removeArtistIgnoreTextAfterIndex(int index, String listType) {
    setState(() {
      for (int i = index; i < artistIgnoreControllers.length - 1; i++) {
        if (artistIgnoreControllers[listType]!.length > i) {
          artistIgnoreControllers[listType]!.removeAt(i);
        }
      }
    });
  }

  void addGenreDelimiters(TextEditingController controller, String listType) {
    setState(() {
      genreDelimiterControllers.add(controller);
    });
  }

  void removeGenreDelimitersAfterIndex(int index, String listType) {
    setState(() {
      print(index);
      for (int i = index; i < genreDelimiterControllers.length - 1; i++) {
        if (genreDelimiterControllers.length > i) {
          genreDelimiterControllers.removeAt(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(builder: (context, value, child) {
      return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text("Configure Your Music Data",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            automaticallyImplyLeading: !widget.firstConfigure,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.secondary),
          ),
          body: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                  child: Column(children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Configuring Your Music Data',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.tertiary)),
                          content: Text(
                              "You can customize your music data to allow songs to be configured with multiple associated artists and genres.\n\nYou can select delimiters (such as commas or pipes) to separate the artist and genre fields.\n\nYou can also select containers (such as parentheses) for the song title and artist fields. This will allow the app to pull artists from these fields and ignore certain text not in the artist name (such as Featuring).\n\nPlease note that the more of these you add, the longer it will take to sync your music library.",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.tertiary)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary, // Background color
                    foregroundColor:
                        Theme.of(context).colorScheme.secondary, // Text color
                  ),
                  child: Text('More Info',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary)),
                ),
                const SizedBox(height: 20),

                // SEPARATE ARTISTS
                Row(children: [
                  Text("Separate Artists",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 20)),
                  InfoButtonPopup(
                      title: "Separate Artists",
                      info:
                          "You can select delimiters (such as commas or pipes) to separate artists within the Artist field.")
                ]),
                const SizedBox(height: 20),
                TextFieldList(
                    list: artistDelimiterControllers,
                    addToList: addArtistDelimiters,
                    removeAfterIndex: removeArtistDelimitersAfterIndex,
                    labelText: "Delimiter",
                    listType: "",
                    width: 150),
                const SizedBox(height: 20),

                // SONG CONTAINER
                // PARENTHESES
                Text("Song Containers",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 20)),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: songContainers.contains(parentheses),
                  onChanged: (changed) {
                    setState(() {
                      if (songContainers.contains(parentheses)) {
                        songContainers.remove(parentheses);
                      } else {
                        songContainers.add(parentheses);
                      }
                    });
                  },
                  title: Text(parentheses),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: songContainers.contains(parentheses),
                  child: TextFieldList(
                      list: songIgnoreControllers[parentheses]!,
                      addToList: addSongIgnoreText,
                      removeAfterIndex: removeSongIgnoreTextAfterIndex,
                      labelText: "Ignore Text",
                      listType: parentheses,
                      width: 200),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: songContainers.contains(brackets),
                  onChanged: (changed) {
                    setState(() {
                      if (songContainers.contains(brackets)) {
                        songContainers.remove(brackets);
                      } else {
                        songContainers.add(brackets);
                      }
                    });
                  },
                  title: Text(brackets),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: songContainers.contains(brackets),
                  child: TextFieldList(
                      list: songIgnoreControllers[brackets]!,
                      addToList: addSongIgnoreText,
                      removeAfterIndex: removeSongIgnoreTextAfterIndex,
                      labelText: "Ignore Text",
                      listType: brackets,
                      width: 200),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: songContainers.contains(curlyBraces),
                  onChanged: (changed) {
                    setState(() {
                      if (songContainers.contains(curlyBraces)) {
                        songContainers.remove(curlyBraces);
                      } else {
                        songContainers.add(curlyBraces);
                      }
                    });
                  },
                  title: Text(curlyBraces),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: songContainers.contains(curlyBraces),
                  child: TextFieldList(
                      list: songIgnoreControllers[curlyBraces]!,
                      addToList: addSongIgnoreText,
                      removeAfterIndex: removeSongIgnoreTextAfterIndex,
                      labelText: "Ignore Text",
                      listType: curlyBraces,
                      width: 200),
                ),
                const SizedBox(height: 20),

                // ARTIST CONTAINER
                Text("Artist Containers",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 20)),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: artistContainers.contains(parentheses),
                  onChanged: (changed) {
                    setState(() {
                      if (artistContainers.contains(parentheses)) {
                        artistContainers.remove(parentheses);
                      } else {
                        artistContainers.add(parentheses);
                      }
                    });
                  },
                  title: Text(parentheses),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: artistContainers.contains(parentheses),
                  child: TextFieldList(
                      list: artistIgnoreControllers[parentheses]!,
                      addToList: addArtistIgnoreText,
                      removeAfterIndex: removeArtistIgnoreTextAfterIndex,
                      labelText: "Ignore Text",
                      listType: parentheses,
                      width: 200),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: artistContainers.contains(brackets),
                  onChanged: (changed) {
                    setState(() {
                      if (artistContainers.contains(brackets)) {
                        artistContainers.remove(brackets);
                      } else {
                        artistContainers.add(brackets);
                      }
                    });
                  },
                  title: Text(brackets),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: artistContainers.contains(brackets),
                  child: TextFieldList(
                      list: artistIgnoreControllers[brackets]!,
                      addToList: addArtistIgnoreText,
                      removeAfterIndex: removeArtistIgnoreTextAfterIndex,
                      labelText: "Ignore Text",
                      listType: brackets,
                      width: 200),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: artistContainers.contains(curlyBraces),
                  onChanged: (changed) {
                    setState(() {
                      if (artistContainers.contains(curlyBraces)) {
                        artistContainers.remove(curlyBraces);
                      } else {
                        artistContainers.add(curlyBraces);
                      }
                    });
                  },
                  title: Text(curlyBraces),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: artistContainers.contains(curlyBraces),
                  child: TextFieldList(
                      list: artistIgnoreControllers[curlyBraces]!,
                      addToList: addArtistIgnoreText,
                      removeAfterIndex: removeArtistIgnoreTextAfterIndex,
                      labelText: "Ignore Text",
                      listType: curlyBraces,
                      width: 200),
                ),
                const SizedBox(height: 20),

                // SEPARATE GENRES
                Text("Separate Genres",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 20)),
                const SizedBox(height: 20),
                TextFieldList(
                    list: genreDelimiterControllers,
                    addToList: addGenreDelimiters,
                    removeAfterIndex: removeGenreDelimitersAfterIndex,
                    labelText: "Delimiter",
                    listType: "",
                    width: 150),
                const SizedBox(height: 50),

                // Sync Button
                ElevatedButton(
                    onPressed: goToSyncMusicPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary, // Background color
                      foregroundColor:
                          Theme.of(context).colorScheme.secondary, // Text color
                    ),
                    child: Text("Sync Music",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary))),
              ]))),
          bottomNavigationBar: Visibility(
            visible: value.currentQueueIndex != -1 && value.queue.isNotEmpty,
            child: BottomAppBar(
              color: Theme.of(context).colorScheme.primary,
              shape: CircularNotchedRectangle(), // Optional for FAB notch
              child: MusicPlayerControls(value, musicProvider: value),
            ),
          ));
    });
  }
}

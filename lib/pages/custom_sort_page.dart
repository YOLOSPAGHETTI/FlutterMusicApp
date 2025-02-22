import 'package:flutter/material.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/error_handler.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/pages/home_page.dart';
import 'package:provider/provider.dart';

class CustomSortPage extends StatefulWidget {
  const CustomSortPage({super.key});

  @override
  State<CustomSortPage> createState() => _CustomSortPageState();
}

class _CustomSortPageState extends State<CustomSortPage> {
  ErrorHandler errorHandler = ErrorHandler();
  List<String> sortOrder = List<String>.filled(6, "");
  List<TextEditingController> searchControllers =
      List<TextEditingController>.filled(7, TextEditingController());
  String errorMessage = "";
  final String duplicateErrorMessage = "Cannot have duplicate sort fields.";
  final String yearDuplicateErrorMessage =
      "Cannot have both years and decades in sorting.";

  bool saveAsPlaylist = false;
  TextEditingController playlistNameController = TextEditingController();

  void goToHomePage(MusicProvider musicProvider) async {
    checkForYearsAndDecades();
    checkForDuplicates();
    await checkPlaylistName(musicProvider);

    if (errorMessage.isEmpty) {
      List<String> tempSortOrder = <String>[];
      Map<String, String> searchStrings = {};

      for (int i = 0; i < 6; i++) {
        String sortString = sortOrder[i];
        if (sortString.isNotEmpty) {
          tempSortOrder.add(sortString);
          searchStrings[sortString] = searchControllers[i].text;
        }
      }
      tempSortOrder.add(tableSongs);
      searchStrings[tableSongs] = searchControllers[6].text;

      //print("goToHomePage::sortOrder: $sortOrder");
      musicProvider.setSort(tempSortOrder, searchStrings);

      if (saveAsPlaylist) {
        String playlistName = playlistNameController.text;
        await musicProvider.addPlaylist(playlistName, true);
        await musicProvider.addPlaylistSort(playlistName);
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return HomePage();
        }));
      }
    }
  }

  void clearLaterFields(int index) {
    String field = sortOrder[index];
    // Make later fields empty when this one is empty
    if (field.isEmpty) {
      for (int i = index; i < 6; i++) {
        sortFields[i].isEmpty;
        searchControllers[i].text = "";
      }
    }
  }

  void checkForDuplicates() {
    bool duplicateError = false;
    Map<String, int> fieldExists = {};

    for (int i = 0; i < 6; i++) {
      if (sortOrder[i].isNotEmpty && fieldExists[sortOrder[i]] != null) {
        duplicateError = true;
        break;
      }
      fieldExists[sortOrder[i]] = i;
    }
    if (duplicateError) {
      errorHandler.addMessage(duplicateErrorMessage);
    } else {
      errorHandler.removeMessage(duplicateErrorMessage);
    }
    setState(() {
      errorMessage = errorHandler.getErrorMessage();
    });
  }

  void checkForYearsAndDecades() {
    setState(() {
      if (sortOrder.contains(sortYears) && sortOrder.contains(sortDecades)) {
        errorHandler.addMessage(yearDuplicateErrorMessage);
      } else {
        errorHandler.removeMessage(yearDuplicateErrorMessage);
      }
      errorMessage = errorHandler.getErrorMessage();
    });
  }

  Future<void> checkPlaylistName(MusicProvider musicProvider) async {
    String name = playlistNameController.text;
    if (saveAsPlaylist) {
      if (name.isEmpty) {
        errorHandler.addMessage(missingPlaylistNameErrorMessage);
      } else {
        errorHandler.removeMessage(missingPlaylistNameErrorMessage);
      }
      errorMessage = errorHandler.getErrorMessage();

      if (errorMessage.isEmpty) {
        // Check if playlist name already exists, add it later in the goToHomePage method
        bool exists = await musicProvider.playlistExists(name);
        if (exists) {
          errorHandler.addMessage(duplicatePlaylistNameErrorMessage);
        } else {
          errorHandler.removeMessage(duplicatePlaylistNameErrorMessage);
        }
        errorMessage = errorHandler.getErrorMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(builder: (context, value, child) {
      return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text("Music Player",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.secondary),
          ),
          /*drawer: MusicPlayerDrawer(
            musicProvider: value,
          ),*/
          body: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Custom Sort',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary)),
                              content: Text(
                                  "You can sort your music by any of these fields in any order (ex. Album, Artist, Song). Songs will always come last. You can also filter on any of the fields here (ex. Genre = Rock).",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary)),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
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
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .secondary, // Text color
                      ),
                      child: Text('More Info',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary)),
                    ),
                    const SizedBox(height: 20),
                    // 1
                    Row(
                      children: [
                        Text("1: "),
                        const SizedBox(width: 25),
                        DropdownButton<String>(
                            value: sortOrder[0],
                            onChanged: (String? newValue) {
                              setState(() {
                                sortOrder[0] = newValue!;
                                clearLaterFields(0);
                                checkForDuplicates();
                              });
                            },
                            items: sortFields.map((String sortString) {
                              return DropdownMenuItem<String>(
                                  value: sortString, child: Text(sortString));
                            }).toList()),
                        const SizedBox(width: 25),
                        Expanded(
                            child: TextField(
                          controller: searchControllers[0],
                        ))
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 2
                    Visibility(
                      visible: sortOrder[0].isNotEmpty,
                      child: Row(
                        children: [
                          Text("2: "),
                          const SizedBox(width: 25),
                          DropdownButton<String>(
                              value: sortOrder[1],
                              onChanged: (String? newValue) {
                                setState(() {
                                  sortOrder[1] = newValue!;
                                  clearLaterFields(1);
                                  checkForDuplicates();
                                });
                              },
                              items: sortFields.map((String sortString) {
                                return DropdownMenuItem<String>(
                                    value: sortString, child: Text(sortString));
                              }).toList()),
                          const SizedBox(width: 25),
                          Expanded(
                              child: TextField(
                            controller: searchControllers[1],
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 3
                    Visibility(
                      visible:
                          sortOrder[0].isNotEmpty && sortOrder[1].isNotEmpty,
                      child: Row(
                        children: [
                          Text("3: "),
                          const SizedBox(width: 25),
                          DropdownButton<String>(
                              value: sortOrder[2],
                              onChanged: (String? newValue) {
                                setState(() {
                                  sortOrder[2] = newValue!;
                                  clearLaterFields(2);
                                  checkForDuplicates();
                                });
                              },
                              items: sortFields.map((String sortString) {
                                return DropdownMenuItem<String>(
                                    value: sortString, child: Text(sortString));
                              }).toList()),
                          const SizedBox(width: 25),
                          Expanded(
                              child: TextField(
                            controller: searchControllers[2],
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 4
                    Visibility(
                      visible: sortOrder[0].isNotEmpty &&
                          sortOrder[1].isNotEmpty &&
                          sortOrder[2].isNotEmpty,
                      child: Row(
                        children: [
                          Text("4: "),
                          const SizedBox(width: 25),
                          DropdownButton<String>(
                              value: sortOrder[3],
                              onChanged: (String? newValue) {
                                setState(() {
                                  sortOrder[3] = newValue!;
                                  clearLaterFields(3);
                                  checkForDuplicates();
                                });
                              },
                              items: sortFields.map((String sortString) {
                                return DropdownMenuItem<String>(
                                    value: sortString, child: Text(sortString));
                              }).toList()),
                          const SizedBox(width: 25),
                          Expanded(
                              child: TextField(
                            controller: searchControllers[3],
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 5
                    Visibility(
                      visible: sortOrder[0].isNotEmpty &&
                          sortOrder[1].isNotEmpty &&
                          sortOrder[2].isNotEmpty &&
                          sortOrder[3].isNotEmpty,
                      child: Row(
                        children: [
                          Text("5: "),
                          const SizedBox(width: 25),
                          DropdownButton<String>(
                              value: sortOrder[4],
                              onChanged: (String? newValue) {
                                setState(() {
                                  sortFields[4] = newValue!;
                                  checkForDuplicates();
                                });
                              },
                              items: sortFields.map((String sortString) {
                                return DropdownMenuItem<String>(
                                    value: sortString, child: Text(sortString));
                              }).toList()),
                          const SizedBox(width: 25),
                          Expanded(
                              child: TextField(
                            controller: searchControllers[4],
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Visibility(
                      visible: sortOrder[0].isNotEmpty &&
                          sortOrder[1].isNotEmpty &&
                          sortOrder[2].isNotEmpty &&
                          sortOrder[3].isNotEmpty &&
                          sortOrder[4].isNotEmpty,
                      child: Row(
                        children: [
                          Text("6: "),
                          const SizedBox(width: 25),
                          DropdownButton<String>(
                              value: sortOrder[5],
                              onChanged: (String? newValue) {
                                setState(() {
                                  sortFields[5] = newValue!;
                                  checkForDuplicates();
                                });
                              },
                              items: sortFields.map((String sortString) {
                                return DropdownMenuItem<String>(
                                    value: sortString, child: Text(sortString));
                              }).toList()),
                          const SizedBox(width: 25),
                          Expanded(
                              child: TextField(
                            controller: searchControllers[5],
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Songs
                    Row(
                      children: [
                        Text("Songs:"),
                        const SizedBox(width: 25),
                        Expanded(
                            child: TextField(
                          controller: searchControllers[5],
                        ))
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Save As Playlist

                    CheckboxListTile(
                      value: saveAsPlaylist,
                      onChanged: (changed) {
                        setState(() {
                          saveAsPlaylist = !saveAsPlaylist;
                        });
                      },
                      title: Text("Save As Playlist"),
                    ),
                    const SizedBox(height: 20),
                    Visibility(
                      visible: saveAsPlaylist,
                      child: Row(
                        children: [
                          const SizedBox(width: 25),
                          Text("Playlist Name:"),
                          const SizedBox(width: 25),
                          Expanded(
                              child: TextField(
                            controller: playlistNameController,
                          ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Visibility(
                      visible: errorMessage.isNotEmpty,
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                        onPressed: () {
                          goToHomePage(value);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary, // Background color
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .secondary, // Text color
                        ),
                        child: Text("Sort",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.secondary))),
                  ],
                ),
              )),
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

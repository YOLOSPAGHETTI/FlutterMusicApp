import 'package:flutter/material.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/file_helper.dart';
import 'package:music_app/models/music_builder.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:provider/provider.dart';

class EditDetailsPage extends StatefulWidget {
  final MusicProvider musicProvider;
  final int songId;
  const EditDetailsPage(
      {super.key, required this.musicProvider, required this.songId});

  @override
  State<EditDetailsPage> createState() => _EditDetailsPageState();
}

class _EditDetailsPageState extends State<EditDetailsPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController artistController = TextEditingController();
  TextEditingController albumController = TextEditingController();
  TextEditingController genreController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  String message = "";

  @override
  void initState() {
    super.initState();
    populateDetails();
  }

  void populateDetails() {
    Song song = widget.musicProvider.getSongFromId(widget.songId);

    setState(() {
      titleController.text = song.title;
      artistController.text = song.artist;
      albumController.text = song.album;
      genreController.text = song.genre;
      yearController.text = song.year;
    });
  }

  void saveTags() async {
    FileHelper fileHelper = FileHelper();
    MusicBuilder musicBuilder = MusicBuilder(widget.musicProvider);
    DatabaseHelper db = DatabaseHelper();

    Song song = widget.musicProvider.getSongFromId(widget.songId);
    song.title = titleController.text;
    song.artist = artistController.text;
    song.album = albumController.text;
    song.genre = genreController.text;
    song.year = yearController.text;

    fileHelper.updateFileTags(song);

    //await db.delete(tableSongs, widget.songId);
    //await db.deleteSongBySource(song.source);
    //print("saveTags:: deleted song");
    //await musicBuilder.buildSong(song);
    await musicBuilder.updateSong(song.id, song);
    print("saveTags:: rebuilt song");
    setState(() {
      message = "Tags saved successfully.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(builder: (context, value, child) {
      return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text("Edit Details",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.secondary),
          ),
          body: Container(
              /*decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12)),*/
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Song Title:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              )),
                          SizedBox(
                              width: 200,
                              child: TextField(
                                controller: titleController,
                              ))
                        ]),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Artist:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              )),
                          SizedBox(
                              width: 200,
                              child: TextField(controller: artistController))
                        ]),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Album:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              )),
                          SizedBox(
                              width: 200,
                              child: TextField(controller: albumController))
                        ]),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Genre:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              )),
                          SizedBox(
                              width: 200,
                              child: TextField(controller: genreController))
                        ]),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Year:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              )),
                          SizedBox(
                              width: 200,
                              child: TextField(controller: yearController))
                        ]),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary),
                            child: Text("Cancel",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              saveTags();
                            },
                            style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary),
                            child: Text("Save",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          )
                        ]),
                  ],
                ),
              )),
          bottomNavigationBar:
              Consumer<MusicProvider>(builder: (context, value, child) {
            return Visibility(
              visible: value.currentQueueIndex != -1 && value.queue.isNotEmpty,
              child: BottomAppBar(
                color: Theme.of(context).colorScheme.primary,
                shape: CircularNotchedRectangle(), // Optional for FAB notch
                child: MusicPlayerControls(value, musicProvider: value),
              ),
            );
          }));
    });
  }
}

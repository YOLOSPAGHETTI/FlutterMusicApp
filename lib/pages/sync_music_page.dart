import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_app/models/file_helper.dart';
import 'package:music_app/models/music_builder.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/home_page.dart';

class SyncMusicPage extends StatefulWidget {
  final List<String> artistDelimiters;
  final List<String> genreDelimiters;
  final List<String> songContainers;
  final List<String> artistContainers;
  final Map<String, List<String>> songIgnoreText;
  final Map<String, List<String>> artistIgnoreText;

  const SyncMusicPage(
      {super.key,
      required this.artistDelimiters,
      required this.genreDelimiters,
      required this.songContainers,
      required this.artistContainers,
      required this.songIgnoreText,
      required this.artistIgnoreText});

  @override
  State<SyncMusicPage> createState() => _SyncMusicPageState();
}

class _SyncMusicPageState extends State<SyncMusicPage> {
  String currentAction = "Finding music files";
  double progress = 0;
  late FileHelper fileHelper;
  late MusicBuilder musicBuilder;

  void updateProgress(double value) {
    setState(() {
      progress = value; // Update the progress value
    });
  }

  @override
  void initState() {
    super.initState();
    syncMusic();
  }

  void syncMusic() async {
    fileHelper = FileHelper(updateProgress);
    musicBuilder = MusicBuilder(updateProgress);

    List<File> musicFiles = await fileHelper.getMusicFiles();
    setState(() {
      currentAction = "Pulling tag data";
    });
    List<Song> songs = await fileHelper.getSongsFromFiles(musicFiles);
    setState(() {
      currentAction = "Populating database";
    });
    await musicBuilder.rebuildDb();
    musicBuilder.populateConfigurationSettings(
        widget.artistDelimiters,
        widget.genreDelimiters,
        widget.songContainers,
        widget.artistContainers,
        widget.songIgnoreText,
        widget.artistIgnoreText);
    await musicBuilder.populateDatabase(songs);

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate after the current widget is built
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => HomePage()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
            title: Text("Syncing Your Music Library",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            automaticallyImplyLeading: false),
        body: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(currentAction, style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    color: Theme.of(context).colorScheme.secondary,
                  )
                ],
              ),
            )));
  }
}

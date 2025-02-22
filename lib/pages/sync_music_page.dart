import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_app/models/file_helper.dart';
import 'package:music_app/models/music_builder.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/home_page.dart';
import 'package:provider/provider.dart';

class SyncMusicPage extends StatefulWidget {
  const SyncMusicPage({
    super.key,
  });

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
    fileHelper = FileHelper();
    fileHelper.setProgressFunction(updateProgress);
    MusicProvider musicProvider =
        Provider.of<MusicProvider>(context, listen: false);
    musicBuilder = MusicBuilder(musicProvider);
    musicBuilder.setProgressFunction(updateProgress);

    List<File> musicFiles = await fileHelper.getMusicFiles();
    setState(() {
      currentAction = "Pulling tag data";
    });
    List<Song> songs = await fileHelper.getSongsFromFiles(musicFiles);
    setState(() {
      currentAction = "Populating database";
    });
    await musicBuilder.recreateMusicTables();
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

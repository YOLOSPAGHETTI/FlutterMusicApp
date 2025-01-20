import 'package:flutter/material.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:provider/provider.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(builder: (context, value, child) {
      final List<int> queue = value.queue;
      final int currentSongId = queue.elementAt(value.currentQueueIndex);
      final Song currentSong = value.getSongFromId(currentSongId);

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text("Music Player",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.secondary),
        ),
        body: ListView.builder(
            itemCount: queue.length,
            itemBuilder: (context, index) {
              return SizedBox(
                  height: listTileHeight,
                  child: ListTile(
                    title:
                        Text(value.getSongFromId(queue.elementAt(index)).title),
                    subtitle: Text(
                        value.getSongFromId(queue.elementAt(index)).artist),
                    /*onTap: () => value.sortString == tableSongs
                            ? goToSong(index)
                            : loadItemList(index),*/
                    onLongPress: () {},
                  ));
            }),
      );
    });
  }
}

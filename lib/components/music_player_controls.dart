import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:music_app/components/text_marquee.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/song_page.dart';

class MusicPlayerControls extends StatelessWidget {
  final MusicProvider musicProvider;

  const MusicPlayerControls(MusicProvider value,
      {super.key, required this.musicProvider});

  String formatTime(Duration duration) {
    String twoDigitSeconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    String formattedTime = "${duration.inMinutes}:$twoDigitSeconds";

    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> queue = musicProvider.queue;
    final int currentSongId = queue[musicProvider.currentQueueIndex];
    final Song currentSong = musicProvider.getSongFromId(currentSongId);
    //print("CurrentSong: " + currentSong.title);

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SongPage()),
            );
          },
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: currentSong.albumArt.isNotEmpty
                  ? Image.memory(
                      currentSong.albumArt,
                      fit: BoxFit.cover, // Adjust fit as needed
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image,
                            size: 250.0); // Fallback for decompression errors
                      },
                    )
                  : Icon(Icons.image))),
      SizedBox(width: 10),
      GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SongPage()),
            );
          },
          child: Column(children: [
            TextMarquee(
              text: currentSong.title,
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold),
              maxWidth: 140,
            ),
            TextMarquee(
              text: currentSong.artist,
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.secondary),
              maxWidth: 140,
            )
          ])),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: musicProvider.playPreviousSong,
        child: Icon(
          Icons.skip_previous,
          color: Theme.of(context).colorScheme.secondary,
          size: 32,
        ),
      ),
      GestureDetector(
        onTap: musicProvider.pauseOrResume,
        child: Icon(
          musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Theme.of(context).colorScheme.secondary,
          size: 32,
        ),
      ),
      GestureDetector(
        onTap: musicProvider.playNextSong,
        child: Icon(
          Icons.skip_next,
          color: Theme.of(context).colorScheme.secondary,
          size: 32,
        ),
      )
    ]);
  }
}

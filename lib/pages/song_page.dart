import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:music_app/components/neu_box.dart';
import 'package:music_app/components/text_marquee.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/queue_page.dart';
import 'package:provider/provider.dart';

class SongPage extends StatelessWidget {
  const SongPage({super.key});

  String formatTime(Duration duration) {
    String twoDigitSeconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    String formattedTime = "${duration.inMinutes}:$twoDigitSeconds";

    return formattedTime;
  }

  IconData getRepeatIconFromValue(int repeat) {
    IconData icon = Icons.repeat;
    if (repeat == 2) {
      icon = Icons.repeat_one;
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(builder: (context, value, child) {
      final List<int> queue = value.queue;
      final int currentSongId = queue[value.currentQueueIndex];
      final Song currentSong = value.getSongFromId(currentSongId);
      bool favorite = currentSong.favorite;

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
          body: SafeArea(
              child: Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              NeuBox(
                  child: Column(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: currentSong.albumArt.isNotEmpty
                          ? Image.memory(
                              currentSong.albumArt,
                              fit: BoxFit.cover, // Adjust fit as needed
                              width: 250.0,
                              height: 250.0,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image,
                                    size:
                                        250.0); // Fallback for decompression errors
                              },
                            )
                          : Icon(Icons.image)),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextMarquee(
                            text: currentSong.title,
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.bold),
                            maxWidth: 250,
                          ),
                          TextMarquee(
                            text: currentSong.artist,
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.normal),
                            maxWidth: 250,
                          ),
                        ],
                      ),
                    ]),
                  )
                ],
              )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const QueuePage()),
                          );
                        },
                        icon: Icon(
                          Icons.queue_music,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        )),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          print(favorite);
                          currentSong.favorite = !favorite;
                          value.setFavorite(
                              currentSong.id, currentSong.favorite);
                        },
                        icon: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: 32,
                        )),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        )),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  Slider(
                    min: 0,
                    max: value.totalDuration.inSeconds.toDouble(),
                    value: value.currentDuration.inSeconds.toDouble(),
                    activeColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: Colors.grey[400],
                    onChanged: (double double) {},
                    onChangeEnd: (double double) {
                      value.audioHandler!
                          .seek(Duration(seconds: double.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatTime(value.currentDuration)),
                        Text(formatTime(value.totalDuration)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: IconButton(
                    onPressed: () {
                      value.toggleShuffle();
                    },
                    icon: value.shuffle
                        ? Icon(Icons.shuffle_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary)
                        : Stack(alignment: Alignment.center, children: [
                            Icon(Icons.shuffle_rounded,
                                size: 22,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary), // Base repeat icon
                            Icon(Icons.not_interested,
                                size: 32,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary), // Overlay cancel icon
                          ]),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          value.playPreviousSong();
                        },
                        icon: Icon(
                          Icons.skip_previous,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          value.pauseOrResume();
                        },
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        value.playNextSong();
                      },
                      icon: Icon(
                        Icons.skip_next,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          int repeat = value.repeat;
                          if (repeat < 2) {
                            repeat++;
                          } else {
                            repeat = 0;
                          }
                          value.repeat = repeat;
                        },
                        icon: value.repeat == 0
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.repeat,
                                      size: 22,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary), // Base repeat icon
                                  Icon(Icons.not_interested,
                                      size: 32,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary), // Overlay cancel icon
                                ],
                              )
                            : Icon(
                                getRepeatIconFromValue(value.repeat),
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              )),
                  ),
                ],
              )
            ]),
          )));
    });
  }
}

import 'package:flutter/material.dart';
import 'package:music_app/components/add_to_playlist_menu_item.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/components/text_marquee.dart';
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
    final GlobalKey listViewKey = GlobalKey();
    int longPressIndex = 0;

    return Consumer<MusicProvider>(builder: (context, value, child) {
      final List<int> queue = value.queue;
      final int currentSongId = queue[value.currentQueueIndex];
      final Song currentSong = value.getSongFromId(currentSongId);
      //print("queuePage::queue: $queue");

      return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text("Queue",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.secondary),
          ),
          body: ListView.builder(
              key: listViewKey,
              itemCount: queue.length,
              itemBuilder: (context, index) {
                return SizedBox(
                    height: listTileHeight,
                    child: GestureDetector(
                        onLongPressStart: (details) async {
                          // Calculate the position of the menu based on the tap position
                          final RenderBox renderBox =
                              listViewKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          final Offset globalOffset =
                              renderBox.localToGlobal(Offset.zero);
                          final double left = details.globalPosition.dx;
                          final double top = details.globalPosition.dy;
                          List<PopupMenuEntry<String>> menuItems = [];

                          menuItems.add(
                            AddToPlaylistMenuItem(
                                musicProvider: value,
                                isSong: true,
                                listItem: queue[index].toString()),
                          );

                          // Implement
                          if (value.isSongList()) {
                            menuItems.add(
                              PopupMenuItem<String>(
                                value: 'details',
                                child: Text('Edit Details'),
                                onTap: () {},
                              ),
                            );
                          }

                          if (menuItems.isEmpty) return;

                          final selectedValue = await showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              left,
                              top,
                              globalOffset.dx + renderBox.size.width - left,
                              globalOffset.dy + renderBox.size.height - top,
                            ),
                            items: menuItems,
                          );

                          if (selectedValue != null) {
                            print('Selected: $selectedValue');
                            // Handle your selected action
                          }
                        },
                        child: ListTile(
                          title: TextMarquee(
                            text: value
                                .getSongFromId(queue.elementAt(index))
                                .title,
                            style: TextStyle(
                              color: value.currentQueueIndex == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.tertiary,
                            ),
                            maxWidth: 250,
                          ),
                          subtitle: TextMarquee(
                            text: value
                                .getSongFromId(queue.elementAt(index))
                                .artist,
                            style: TextStyle(
                                color: value.currentQueueIndex == index
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.tertiary),
                            maxWidth: 250,
                          ),
                          tileColor: value.currentQueueIndex == index
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                          onTap: () => value.playSongFromQueue(index),
                        )));
              }),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_app/components/add_playlist_button.dart';
import 'package:music_app/components/add_to_playlist_menu_item.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/components/music_player_drawer.dart';
import 'package:music_app/components/quick_sort_sidebar.dart';
import 'package:music_app/components/text_marquee.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/pages/check_permissions_page.dart';
import 'package:music_app/pages/edit_details_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool dbPopulated = false;
  late final MusicProvider musicProvider;
  final GlobalKey _listViewKey = GlobalKey();

  // Search
  bool isSearchActive = false;
  TextEditingController searchController = TextEditingController();

  // Scroll
  final ScrollController _scrollController = ScrollController();
  Map<String, double> scrollPositions = {};
  double scrollOffset = listTileHeight * 5;
  double _currentVelocity = 0.0;
  Timer? _velocityTracker;
  double oldScrollOffset = 0;
  double jumpOffset = 0;
  static const int simulatedScrollTime = 5000;

  int longPressIndex = 0;

  @override
  void initState() {
    musicProvider = Provider.of<MusicProvider>(context, listen: false);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      goToCheckPermissionPage();
    });
    _scrollController.addListener(_onScroll);
    loadSongs();
  }

  void goToCheckPermissionPage() async {
    await setDatabasePopulated();
    /*if (dbPopulated) {
      DatabaseHelper db = DatabaseHelper();
      db.dropTables();
    }*/
    if (!dbPopulated) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckPermissionsPage()),
        );
      }
    }
  }

  Future<void> setDatabasePopulated() async {
    if (!dbPopulated) {
      DatabaseHelper db = DatabaseHelper();
      dbPopulated = await db.isDatabasePopulated();
    }
  }

  void loadSongs() async {
    await setDatabasePopulated();
    if (dbPopulated) {
      if (musicProvider.sortString == sortSongs) {
        musicProvider.getPlaylists();
        musicProvider.loadSongs();
      }
    }
  }

  void loadItemList(int itemIndex) {
    /*musicProvider.searchStrings[musicProvider.sortString] =
        musicProvider.items[itemIndex];*/
    scrollPositions[musicProvider.sortString] =
        _scrollController.position.pixels;
    musicProvider.getNextSort(itemIndex);
  }

  void _onScroll() {
    double position = _scrollController.position.pixels;
    double end = _scrollController.position.maxScrollExtent;

    if (position >= end - scrollOffset) {
      musicProvider.appendToLimitedList(true);
    } else if (position < scrollOffset && !musicProvider.atTopOfList()) {
      musicProvider.appendToLimitedList(false);

      double jump = loadIncrement * listTileHeight;
      //print("onScroll::position: $end");
      //print("onScroll::jump: $jump");
      if (end > position + jump) {
        jumpOffset = position + jump + scrollOffset;
        _scrollController.jumpTo(jumpOffset);
        //print("onScroll::currentVelocity1: $_currentVelocity");
        continueScrolling(_currentVelocity);
      }
    }

    _velocityTracker?.cancel();

    _velocityTracker = Timer(const Duration(milliseconds: 16), () {
      // Calculate scroll velocity based on position change
      double newOffset = _scrollController.offset;
      //print("onScroll::currentVelocity2: $_currentVelocity");
      if (newOffset != jumpOffset) {
        _currentVelocity = newOffset - oldScrollOffset;
        oldScrollOffset = newOffset;
      }
    });
  }

  void continueScrolling(double velocity) {
    if (velocity == 0) return;

    // Calculate a target position based on the velocity
    double targetOffset =
        _scrollController.offset + (velocity * (simulatedScrollTime / 1000));

    // Use animateTo for a smooth scroll
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(
          milliseconds: simulatedScrollTime), // Adjust duration as needed
      curve: Curves.easeOut,
    );
  }

  void goBack() async {
    bool hasPrevious = await musicProvider.getPreviousSort();
    //print("hasPrevious: $hasPrevious");
    if (!hasPrevious) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } else {
      double position = scrollPositions[musicProvider.sortString] == null
          ? 0
          : scrollPositions[musicProvider.sortString]!;
      print(position);
      _scrollController.jumpTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(builder: (context, value, child) {
      List<int> songIds = value.limitedSongIds;
      List<String> items = value.limitedItems;

      return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            goBack();
          },
          child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: isSearchActive
                    ? TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                            hintText: 'Search',
                            //border: InputBorder.none,
                            fillColor: Theme.of(context).colorScheme.surface,
                            filled: true),
                        onChanged: (searchQuery) {
                          print("Search query: $value");
                          value.query(searchQuery);
                        },
                      )
                    : Row(children: [
                        Text(value.sortString,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                        SizedBox(width: 10),
                        Visibility(
                            visible: value.sortString == sortPlaylists,
                            child: AddPlaylistButton(musicProvider: value))
                      ]),
                leading: value.isFirstSort
                    ? null
                    : Builder(
                        builder: (context) {
                          return IconButton(
                            icon: Icon(Icons.arrow_back), // Default back icon
                            onPressed: () async {
                              // Custom onPressed logic
                              goBack();
                              //print("pressed back on app bar");
                            },
                          );
                        },
                      ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.secondary),
                actions: [
                  if (!isSearchActive)
                    IconButton(
                      icon: Icon(Icons.search,
                          color: Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        setState(() {
                          isSearchActive = true; // Show the TextField
                        });
                      },
                    ),
                  if (isSearchActive)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        value.query("");
                        setState(() {
                          searchController.text = "";
                          isSearchActive = false;
                        });
                      },
                    ),
                ],
              ),
              drawer: value.isFirstSort
                  ? MusicPlayerDrawer(
                      musicProvider: musicProvider,
                    )
                  : null,
              body: Stack(children: [
                ListView.builder(
                    key: _listViewKey,
                    controller: _scrollController,
                    itemCount:
                        value.isSongList() ? songIds.length : items.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                          height: listTileHeight,
                          child: GestureDetector(
                              onLongPressStart: (details) async {
                                // Calculate the position of the menu based on the tap position
                                final RenderBox renderBox = _listViewKey
                                    .currentContext!
                                    .findRenderObject() as RenderBox;
                                final Offset globalOffset =
                                    renderBox.localToGlobal(Offset.zero);
                                final double left = details.globalPosition.dx;
                                final double top = details.globalPosition.dy;
                                List<PopupMenuEntry<String>> menuItems = [];

                                menuItems.add(
                                  PopupMenuItem<String>(
                                    value: 'queue',
                                    child: Text('Add To Queue'),
                                    onTap: () {
                                      value.addToQueue(index);
                                    },
                                  ),
                                );

                                // Implement for lists that don't just include songs
                                if (value.isSongList()) {
                                  menuItems.add(
                                    AddToPlaylistMenuItem(
                                        musicProvider: value,
                                        isSong: true,
                                        listItem: songIds[index].toString()),
                                  );
                                } else {
                                  menuItems.add(
                                    AddToPlaylistMenuItem(
                                        musicProvider: value,
                                        isSong: false,
                                        listItem: items[index]),
                                  );
                                }

                                // Implement
                                if (value.isSongList()) {
                                  menuItems.add(
                                    PopupMenuItem<String>(
                                      value: 'details',
                                      child: Text('Edit Details'),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EditDetailsPage(
                                                      musicProvider: value,
                                                      songId: songIds[index])),
                                        );
                                      },
                                    ),
                                  );
                                }

                                if (value.sortString == sortPlaylists) {
                                  menuItems.add(
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete'),
                                      onTap: () {
                                        longPressIndex = index;
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Delete Playlist",
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary)),
                                              content: Text(
                                                  "Are you sure you want to delete this playlist?"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () {
                                                      value.deletePlaylist(
                                                          longPressIndex);
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    },
                                                    child: Text('Yes')),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
                                                  },
                                                  child: Text('No'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                                }

                                print("build:: " + menuItems.toString());

                                if (menuItems.isEmpty) return;

                                final selectedValue = await showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    left,
                                    top,
                                    globalOffset.dx +
                                        renderBox.size.width -
                                        left,
                                    globalOffset.dy +
                                        renderBox.size.height -
                                        top,
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
                                  text: value.isSongList()
                                      ? value
                                          .getSongFromId(songIds[index])
                                          .title
                                      : items[index],
                                  style: TextStyle(
                                    color: value.playingSongIndex == index
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                  ),
                                  maxWidth: 250,
                                ),
                                subtitle: TextMarquee(
                                  text: value.isSongList()
                                      ? value
                                          .getSongFromId(songIds[index])
                                          .artist
                                      : "",
                                  style: TextStyle(
                                      color: value.playingSongIndex == index
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .tertiary),
                                  maxWidth: 250,
                                ),
                                tileColor: value.playingSongIndex == index
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.transparent,
                                onTap: () => value.isSongList()
                                    ? value.startQueue(index)
                                    : loadItemList(index),
                              )));
                    }),
                Visibility(
                    visible: value.shouldShowSidebar,
                    child: value.orderType == orderAlphabetically
                        ? QuickSortSidebar(
                            musicProvider: value,
                            items: alphabet,
                            scrollController: _scrollController,
                            itemHeight: 22,
                            itemWidth: 40,
                          )
                        : QuickSortSidebar(
                            musicProvider: value,
                            items: value.chronologicalQuickSort.keys.toList(),
                            scrollController: _scrollController,
                            itemHeight: 40,
                            itemWidth: 50,
                          ))
              ]),
              bottomNavigationBar: Visibility(
                visible:
                    value.currentQueueIndex != -1 && value.queue.isNotEmpty,
                child: BottomAppBar(
                  color: Theme.of(context).colorScheme.primary,
                  shape: CircularNotchedRectangle(), // Optional for FAB notch
                  child: MusicPlayerControls(value, musicProvider: value),
                ),
              )));
    });
  }
}

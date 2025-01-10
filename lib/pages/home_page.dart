import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_app/components/music_player_controls.dart';
import 'package:music_app/components/music_player_drawer.dart';
import 'package:music_app/components/quick_sort_sidebar.dart';
import 'package:music_app/components/text_marquee.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/check_permissions_page.dart';
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

  TextEditingController addPlaylistController = TextEditingController();

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
      if (musicProvider.sortString == tableSongs) {
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

    if (!musicProvider.isLoading) {
      if (position > end - scrollOffset) {
        musicProvider.appendToLimitedList(true);
      } else if (position < scrollOffset &&
          musicProvider.firstLoadedIndex > 0) {
        musicProvider.appendToLimitedList(false);

        double jump = musicProvider.loadIncrement * listTileHeight;
        end = _scrollController.position.maxScrollExtent;
        //print("onScroll::position: $end");
        //print("onScroll::jump: $jump");
        if (end > position + jump) {
          jumpOffset = position + jump + scrollOffset;
          _scrollController.jumpTo(jumpOffset);
          //print("onScroll::currentVelocity1: $_currentVelocity");
          continueScrolling(_currentVelocity);
        }
      }
    }

    _velocityTracker?.cancel();

    _velocityTracker = Timer(const Duration(milliseconds: 16), () {
      // Calculate scroll velocity based on position change
      double newOffset = _scrollController.offset;
      //print("onScroll::currentVelocity2: $_currentVelocity");
      if (newOffset != jumpOffset && !musicProvider.isLoading) {
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
      List<Song> songs = value.limitedSongs;
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
                            visible: value.sortString == tablePlaylists,
                            child: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        String errorMessage = "";

                                        return StatefulBuilder(
                                          builder: (BuildContext context,
                                              StateSetter setState) {
                                            void addPlaylist() async {
                                              if (addPlaylistController
                                                  .text.isEmpty) {
                                                setState(() {
                                                  errorMessage =
                                                      "Please give the playlist a name.";
                                                });
                                                return;
                                              }
                                              bool exists = await musicProvider
                                                  .addPlaylist(
                                                      addPlaylistController
                                                          .text);

                                              if (exists) {
                                                setState(() {
                                                  errorMessage =
                                                      "A playlist with this name already exists.";
                                                });
                                                return;
                                              }
                                              setState(() {
                                                errorMessage = "";
                                              });
                                              if (mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            }

                                            return AlertDialog(
                                              title: Text("Create Playlist",
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary)),
                                              content: SizedBox(
                                                height: 100,
                                                width: 200,
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                        child: TextField(
                                                            controller:
                                                                addPlaylistController)),
                                                    Text(
                                                      errorMessage,
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                Row(children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      addPlaylist();
                                                    },
                                                    child: Text('ADD'),
                                                  ),
                                                  SizedBox(width: 50),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        errorMessage = "";
                                                      });
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    },
                                                    child: Text('CANCEL'),
                                                  ),
                                                ])
                                              ],
                                            );
                                          },
                                        );
                                      });
                                },
                                icon: Icon(Icons.add)))
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
                    itemCount: value.isSongList() ? songs.length : items.length,
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
                                    child: Text('Queue'),
                                    onTap: () {
                                      value.addToQueue(index);
                                    },
                                  ),
                                );

                                menuItems.add(
                                  PopupMenuItem<String>(
                                    value: 'playlist',
                                    child: Text('Add To Playlist'),
                                    onTap: () {
                                      List<String> playlists = value.playlists;
                                      longPressIndex = index;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("Add To Playlist",
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary)),
                                            content: ListView.builder(
                                                itemCount: playlists.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                      title: TextMarquee(
                                                        text: playlists[index],
                                                        style: TextStyle(),
                                                        maxWidth: 250,
                                                      ),
                                                      onTap: () {
                                                        value.addSongToPlaylist(
                                                            index,
                                                            longPressIndex);
                                                        Navigator.of(context)
                                                            .pop();
                                                      });
                                                }),
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
                                  ),
                                );

                                // Implement
                                if (value.isSongList()) {
                                  menuItems.add(
                                    PopupMenuItem<String>(
                                      value: 'details',
                                      child: Text('Details'),
                                      onTap: () {},
                                    ),
                                  );
                                }

                                if (value.sortString == tablePlaylists) {
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
                                      ? songs[index].title
                                      : items[index],
                                  style: TextStyle(),
                                  maxWidth: 250,
                                ),
                                subtitle: TextMarquee(
                                  text: value.isSongList()
                                      ? songs[index].artist
                                      : "",
                                  style: TextStyle(),
                                  maxWidth: 250,
                                ),
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
                          )
                        : QuickSortSidebar(
                            musicProvider: value,
                            items: decades,
                            scrollController: _scrollController,
                            itemHeight: 40,
                          ))
              ]),
              bottomNavigationBar: Visibility(
                visible:
                    value.currentQueueIndex != -1 && value.fullQueue.isNotEmpty,
                child: BottomAppBar(
                  color: Theme.of(context).colorScheme.primary,
                  shape: CircularNotchedRectangle(), // Optional for FAB notch
                  child: MusicPlayerControls(value, musicProvider: value),
                ),
              )));
    });
  }
}

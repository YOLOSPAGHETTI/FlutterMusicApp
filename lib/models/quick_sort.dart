import 'dart:collection';

import 'package:music_app/constants.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/music_sorter.dart';
import 'package:music_app/models/song.dart';

class QuickSort {
  int startIndex;
  int endIndex;
  double position;

  QuickSort(
      {required this.startIndex,
      required this.endIndex,
      required this.position});

  void initialize(MusicProvider musicProvider, String item, int lastPosition) {
    int index = 0;
    String sortString = musicProvider.sortString;
    List<Song> songs = musicProvider.songs;
    LinkedHashSet<String> items = musicProvider.items;
    int loadIncrement = musicProvider.loadIncrement;
    if (sortString == tableSongs) {
      index = getQuickSortPositionForSongs(item, lastPosition, musicProvider);
      startIndex = musicProvider.getStartForLimitedList(index);
      endIndex = musicProvider.getEndForLimitedList(index, songs.length);
    } else {
      index = getQuickSortPositionForItems(item, lastPosition, musicProvider);
      startIndex = musicProvider.getStartForLimitedList(index);
      endIndex = musicProvider.getEndForLimitedList(index, items.length);
    }
    if (startIndex == 0) {
      position = index.toDouble() * listTileHeight;
    } else {
      position = loadIncrement.toDouble() * listTileHeight;
    }
  }

  int getQuickSortPositionForSongs(
      String sortItem, int lastPosition, MusicProvider musicProvider) {
    int position = 0;
    List<Song> songs = musicProvider.songs;
    String orderType = musicProvider.orderType;
    MusicSorter sorter = musicProvider.sorter;
    List<Song> tempSongs = <Song>[];
    tempSongs.addAll(songs);

    if (orderType != orderAlphabetically) {
      sortItem = sortItem.substring(0, 3);
    }

    for (int i = 0; i < tempSongs.length; i++) {
      Song song = songs[i];
      String title = song.title;
      if (orderType == orderAlphabetically) {
        title = sorter.cleanString(title);
        if (title.toUpperCase().startsWith(sortItem)) {
          //print(title);
          position = i;
          break;
        }
      } else {
        if (title.startsWith(sortItem)) {
          position = i;
          break;
        }
      }
    }

    print("getQuickSortPositionForSongs::sortItem: $sortItem");
    print("getQuickSortPositionForSongs::position: $position");
    return position == 0 ? lastPosition : position;
  }

  int getQuickSortPositionForItems(
      String sortItem, int lastPosition, MusicProvider musicProvider) {
    int position = 0;
    LinkedHashSet<String> items = musicProvider.items;
    String orderType = musicProvider.orderType;
    MusicSorter sorter = musicProvider.sorter;
    List<String> tempItems = <String>[];
    tempItems.addAll(items);

    if (orderType != orderAlphabetically) {
      sortItem = sortItem.substring(0, 3);
    }

    for (int i = 0; i < tempItems.length; i++) {
      String item = tempItems[i];
      item = sorter.cleanString(item);
      if (orderType == orderAlphabetically) {
        if (item.toUpperCase().startsWith(sortItem)) {
          position = i;
          break;
        }
      } else {
        if (item.startsWith(sortItem)) {
          position = i;
          break;
        }
      }
    }

    //print("getQuickSortPositionForItems::sortItem: $sortItem");
    //print("getQuickSortPositionForItems::position: $position");
    return position == 0 ? lastPosition : position;
  }
}

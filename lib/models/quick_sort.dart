import 'dart:collection';

import 'package:music_app/constants.dart';
import 'package:music_app/models/lazy_list.dart';
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

  int initialize(MusicProvider musicProvider, String item, int lastPosition) {
    int index = 0;
    List<int> songIds = musicProvider.songIds;
    LinkedHashSet<String> items = musicProvider.items;
    if (musicProvider.isSongList()) {
      LazyList<int> songList = LazyList<int>();
      index = getQuickSortPositionForSongs(item, lastPosition, musicProvider);
      startIndex = songList.getValidStart(index);
      endIndex = songList.getValidEnd(index, songIds.length);
    } else {
      LazyList<String> itemList = LazyList<String>();
      index = getQuickSortPositionForItems(item, lastPosition, musicProvider);
      startIndex = itemList.getValidStart(index);
      endIndex = itemList.getValidEnd(index, items.length);
    }
    if (startIndex == 0) {
      position = index.toDouble() * listTileHeight;
    } else {
      position = loadIncrement.toDouble() * listTileHeight;
    }
    return index;
  }

  int getQuickSortPositionForSongs(
      String sortItem, int lastPosition, MusicProvider musicProvider) {
    int position = 0;
    List<int> songIds = musicProvider.songIds;
    String orderType = musicProvider.orderType;
    MusicSorter sorter = musicProvider.sorter;
    Map<String, String> chronologicalQuickSort =
        musicProvider.chronologicalQuickSort;
    List<int> tempSongIds = <int>[];
    tempSongIds.addAll(songIds);

    if (orderType == orderAlphabetically) {
      for (int i = 0; i < tempSongIds.length; i++) {
        Song song = musicProvider.getSongFromId(tempSongIds[i]);
        String title = song.title;
        title = sorter.cleanString(title);
        if (title.toUpperCase().startsWith(sortItem)) {
          //print(title);
          position = i;
          break;
        }
      }
    } else {
      position = songIds.indexOf(int.parse(chronologicalQuickSort[sortItem]!));
    }

    //print("getQuickSortPositionForSongs::sortItem: $sortItem");
    //print("getQuickSortPositionForSongs::position: $position");
    return position == 0 ? lastPosition : position;
  }

  int getQuickSortPositionForItems(
      String sortItem, int lastPosition, MusicProvider musicProvider) {
    int position = 0;
    LinkedHashSet<String> items = musicProvider.items;
    String orderType = musicProvider.orderType;
    MusicSorter sorter = musicProvider.sorter;
    Map<String, String> chronologicalQuickSort =
        musicProvider.chronologicalQuickSort;
    List<String> tempItems = <String>[];
    tempItems.addAll(items);

    if (orderType == orderAlphabetically) {
      for (int i = 0; i < tempItems.length; i++) {
        String item = tempItems[i];
        item = sorter.cleanString(item);

        //print("getQuickSortPositionForItems::item: $item");
        //print("getQuickSortPositionForItems::sortItem: $sortItem");
        if (item.toUpperCase().startsWith(sortItem)) {
          position = i;
          break;
        }
      }
    } else {
      position = items.toList().indexOf(chronologicalQuickSort[sortItem]!);
    }

    //print("getQuickSortPositionForItems::sortItem: $sortItem");
    //print("getQuickSortPositionForItems::position: $position");
    return position == 0 ? lastPosition : position;
  }
}

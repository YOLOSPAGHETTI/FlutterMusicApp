import 'dart:collection';

import 'package:music_app/constants.dart';

class LazyList<E> extends ListBase<E> {
  final List<E> list = <E>[];
  bool isLoading = false;
  int firstLoadedIndex = 0;
  int lastLoadedIndex = 0;

  LazyList();

  @override
  set length(int newLength) {
    list.length = newLength;
  }

  @override
  int get length => list.length;

  @override
  E operator [](int index) => list[index];

  @override
  void operator []=(int index, E value) {
    list[index] = value;
  }

  void loadStart(List<E> listToAdd) {
    if (listToAdd.isEmpty) return;
    int startIndex = getValidStart(0);
    int endIndex = getValidEnd(0, listToAdd.length);
    if (startIndex >= endIndex) return;
    load(startIndex, endIndex, listToAdd);
  }

  void append(bool fromEnd, List<E> listToAdd) async {
    int startIndex = firstLoadedIndex;
    int endIndex = lastLoadedIndex;
    if (fromEnd) {
      endIndex = getValidEnd(lastLoadedIndex + loadIncrement, listToAdd.length);
    } else if (firstLoadedIndex > 0) {
      startIndex = firstLoadedIndex - loadIncrement;
      if (startIndex < 0) {
        startIndex = 0;
      }
    }

    load(startIndex, endIndex, listToAdd);
  }

  void load(int startIndex, int endIndex, List<E> listToAdd) async {
    if (!isLoading) {
      if (listToAdd.isEmpty || startIndex >= endIndex) return;
      isLoading = true;
      firstLoadedIndex = startIndex;
      lastLoadedIndex = endIndex;
      //print("loadLimitedList::lastLoadedIndex: $firstLoadedIndex");
      //print("loadLimitedList::lastLoadedIndex: $lastLoadedIndex");
      /*print("loadLimitedList::_limitedSongsLength: " +
          _limitedSongIds.length.toString());*/
      list.clear();
      list.addAll(listToAdd.sublist(firstLoadedIndex, lastLoadedIndex));
      print("append::listSize: " + list.length.toString());
    }
    isLoading = false;
  }

  int getValidStart(int position) {
    int startIndex = position - loadIncrement;
    if (startIndex < 0) {
      startIndex = 0;
    }
    return startIndex;
  }

  int getValidEnd(int position, int listLength) {
    if (listLength == 0) return 0; // Prevent null case
    int endIndex = position + loadIncrement;
    if (endIndex > listLength) {
      endIndex = listLength;
    }
    return endIndex;
  }
}

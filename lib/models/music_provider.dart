import 'dart:collection';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/list_history.dart';
import 'package:music_app/models/music_sorter.dart';
import 'package:music_app/models/quick_sort.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:music_app/models/song.dart';

class MusicProvider extends ChangeNotifier {
  final MusicSorter sorter = MusicSorter();

  // Lists
  final List<Song> songs = <Song>[];
  final List<Song> _limitedSongs = <Song>[];
  final Queue<Song> manualQueue = Queue<Song>();
  final Queue<Song> autoQueue = Queue<Song>();
  final Queue<Song> _fullQueue = Queue<Song>();
  final Map<String, ListHistory> itemTree = {};
  final LinkedHashSet<String> items = LinkedHashSet();
  final List<String> _limitedItems = <String>[];
  final Map<String, QuickSort> quickSortMap = {};
  final List<String> _playlists = <String>[];
  bool _isLoading = false;
  int firstLoadedIndex = 0;
  int lastLoadedIndex = 0;
  int loadIncrement = 100;

  // Playback
  int _currentQueueIndex = -1;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _shuffle = false;
  int _repeat = 0; // 0 = off, 1 = repeat, 2 = repeat1

  // Sorting
  String _sortString = tableSongs;
  final List<String> _sortOrder = <String>[tableSongs];
  final Map<String, String> _searchStrings = {};
  final Map<String, String> selectedItems = {};
  bool _isFirstSort = true;
  bool _shouldShowSidebar = true;
  String _orderType = orderAlphabetically;

  // Getters
  // Lists
  List<Song> get limitedSongs => _limitedSongs;
  Queue<Song> get fullQueue => _fullQueue;
  List<String> get limitedItems => _limitedItems;
  bool get isLoading => _isLoading;
  List<String> get playlists => _playlists;

  // Playback
  int get currentQueueIndex => _currentQueueIndex;
  bool get isPlaying => _isPlaying;
  Duration get currentDuration => _currentDuration;
  Duration get totalDuration => _totalDuration;
  bool get shuffle => _shuffle;
  int get repeat => _repeat;

  // Sorting
  String get sortString => _sortString;
  List<String> get sortOrder => _sortOrder;
  bool get isFirstSort => _isFirstSort;
  bool get shouldShowSidebar => _shouldShowSidebar;
  String get orderType => _orderType;
  Map<String, String> get searchStrings => _searchStrings;

  MusicProvider() {
    listenToDuration();
  }

  // Loading
  void loadSongs() async {
    songs.clear();
    _limitedSongs.clear();
    print("loadSongs::_sortOrder: $_sortOrder");
    await sorter.populateSongs(this);
    if (_limitedSongs.isEmpty) {
      loadStartOfList(songs.length);
    }
    populateQuickSort();
  }

  void loadSongsWithFilter() async {
    songs.clear();
    _limitedSongs.clear();
    _sortString = tableSongs;
    setIsFirstSort();
    await sorter.populateSongsWithFilter(this);
    if (_limitedSongs.isEmpty) {
      loadStartOfList(songs.length);
    }
    populateQuickSort();
  }

  void loadFavoriteSongs() async {
    songs.clear();
    _limitedSongs.clear();
    setIsFirstSort();
    await sorter.populateFavoriteSongs(this);
    if (_limitedSongs.isEmpty) {
      loadStartOfList(songs.length);
    }
    populateQuickSort();
  }

  void loadItemsWithFilter() async {
    items.clear();
    safeNotify();

    List<String> itemList = <String>[];
    await sorter.populateItemListWithFilter(this);
    if (_limitedItems.isEmpty) {
      loadStartOfList(items.length);
    }

    // Populate item tree so we remember historical data
    print("loadItemsWithFilter::itemList: $itemList");
    itemList.addAll(items);
    populateQuickSort();

    Map<String, QuickSort> tempQuickSort = {};
    tempQuickSort.addAll(quickSortMap);

    itemTree[_sortString] =
        ListHistory(items: itemList, quickSort: tempQuickSort);
  }

  void loadPlaylists() async {
    items.clear();
    safeNotify();

    List<String> itemList = <String>[];
    _playlists.addAll(await sorter.getPlaylists());
    items.addAll(_playlists);
    loadStartOfList(items.length);

    // Populate item tree so we remember historical data
    itemList.addAll(items);
    populateQuickSort();

    Map<String, QuickSort> tempQuickSort = {};
    tempQuickSort.addAll(quickSortMap);

    itemTree[_sortString] =
        ListHistory(items: itemList, quickSort: tempQuickSort);
  }

  Future<void> loadPreviousItems() async {
    if (!itemTree.containsKey(_sortString)) {
      loadPageList();
    } else {
      items.clear();
      items.addAll(itemTree[_sortString]!.items);
      loadLimitedList(
          itemTree[_sortString]!.startIndex, itemTree[_sortString]!.endIndex);
    }
    populateQuickSort();
    safeNotify();
  }

  void query(String query) {
    if (_sortString == tableSongs) {
      List<Song> tempSongs = sorter.searchSongs(songs, query);
      _limitedSongs.clear();
      _limitedSongs.addAll(tempSongs);
    } else {
      items.clear();
      items.addAll(sorter.searchItems(itemTree[_sortString]!.items, query));
    }
    safeNotify();
  }

  void addSong(Song song) {
    songs.add(song);
    print("addSong::limitedSongs: $limitedSongs");
    if (limitedSongs.isEmpty) {
      //print("addSong::songsLength: " + songs.length.toString());
      //print("addSong::populationSize: " + sorter.populationSize.toString());
      if (songs.length > loadIncrement) {
        loadStartOfList(songs.length);
      }
    }
    notifyListeners();
  }

  void addItem(String item) {
    items.add(item);
    if (limitedItems.isEmpty) {
      if (items.length > loadIncrement) {
        loadStartOfList(items.length);
      }
    }
    notifyListeners();
  }

  void setIsFirstSort() {
    _isFirstSort = _sortOrder[0] == _sortString;
    safeNotify();
  }

  void setOrderType() {
    String songOrderType = SettingsProvider().songOrderType;
    String albumOrderType = SettingsProvider().albumOrderType;

    if (_sortString == tableSongs && sortOrder.length > 1) {
      _orderType = songOrderType;
    } else if (_sortString == columnAlbum) {
      _orderType = albumOrderType;
    } else if (_sortString == columnYear) {
      _orderType = orderChronolically;
    } else {
      _orderType = orderAlphabetically;
    }
  }

  // Sorting
  bool getPreviousSort() {
    if (isFirstSort) {
      return false;
    }
    selectedItems.remove(_sortString);
    itemTree.remove(_sortString);
    int sortIndex = _sortOrder.indexOf(_sortString);
    if (sortIndex - 1 >= 0) {
      _sortString = _sortOrder[sortIndex - 1];
    }
    setIsFirstSort();
    loadPreviousItems();

    notifyListeners();
    return true;
  }

  void getNextSort(int itemIndex) {
    print("getNextSort::sortString: $_sortString");
    // Get selected item
    String query = _limitedItems.elementAt(itemIndex);
    selectedItems[_sortString] = query;

    // Set historical limitedList indexes
    itemTree[_sortString]!.startIndex = firstLoadedIndex;
    itemTree[_sortString]!.endIndex = lastLoadedIndex;

    print("getNextSort::sortOrder: $_sortOrder");
    int sortIndex = _sortOrder.indexOf(_sortString);
    if (sortIndex + 1 < _sortOrder.length) {
      _sortString = _sortOrder[sortIndex + 1];
    }
    setIsFirstSort();
    print("getNextSort::sortString2: $_sortString");
    loadPageList();

    safeNotify();
  }

  void setSortSingle(String sortString) {
    _sortString = sortString;
    clearSortLists();
    _sortOrder.add(sortString);

    print("setSortSingle::_sortOrder: $_sortOrder");
    loadPageList();
  }

  void setSort(List<String> sortOrder, Map<String, String> searchStrings) {
    _sortString = sortOrder[0];
    clearSortLists();

    for (String sort in sortOrder) {
      if (sort.isNotEmpty) {
        _sortOrder.add(sort);
      }
      String search = searchStrings[sort] ?? "";
      if (search.isNotEmpty) {
        _searchStrings[sort] = search;
      }
    }
    loadPageList();
  }

  void clearSortLists() {
    _sortOrder.clear();
    _searchStrings.clear();
    selectedItems.clear();
    itemTree.clear();
  }

  void loadPageList() {
    _limitedSongs.clear();
    _limitedItems.clear();
    if (_sortString == tableSongs) {
      loadSongsWithFilter();
    } else if (_sortString == columnFavorite) {
      loadFavoriteSongs();
    } else if (sortOrder.length == 1 && sortOrder.contains(tablePlaylists)) {
      loadPlaylists();
    } else {
      _sortOrder.add(tableSongs);
      loadItemsWithFilter();
    }
    safeNotify();
  }

  bool isSongList() {
    if (_sortString == tableSongs || _sortString == columnFavorite) {
      return true;
    }
    return false;
  }

  // Quick Sort
  void setShouldShowSidebar() {
    if (_sortString == columnModifiedDate) {
      _shouldShowSidebar = false;
    } else if ((isSongList()) && _limitedSongs.length <= 5) {
      _shouldShowSidebar = false;
    } else if (_sortString != tableSongs && items.length <= 5) {
      _shouldShowSidebar = false;
    } else {
      _shouldShowSidebar = true;
    }
  }

  double getPositionFromQuickSort(String item) {
    if (quickSortMap[item] != null) {
      loadLimitedList(
          quickSortMap[item]!.startIndex, quickSortMap[item]!.endIndex);

      notifyListeners();
    }
    print(item);
    return quickSortMap[item] == null ? 0 : quickSortMap[item]!.position;
  }

  List<String> getQuickSortItemList() {
    if (_orderType == orderAlphabetically) {
      return alphabet;
    } else {
      return decades; // Dynamically populate this with decades/years
    }
  }

  void populateQuickSort() {
    setOrderType();
    setShouldShowSidebar();
    if (_shouldShowSidebar) {
      if (itemTree.containsKey(_sortString)) {
        quickSortMap.clear();
        quickSortMap.addAll(itemTree[_sortString]!.quickSort);
      } else {
        int lastPosition = 0;
        List<String> list = getQuickSortItemList();
        for (String item in list) {
          QuickSort quickSort =
              QuickSort(startIndex: 0, endIndex: 0, position: 0);
          quickSort.initialize(this, item, lastPosition);
          quickSortMap[item] = quickSort;
        }
      }
    }
  }

  // Limited List
  void loadStartOfList(int listLength) {
    int startIndex = getStartForLimitedList(0);
    int endIndex = getEndForLimitedList(0, listLength);
    loadLimitedList(startIndex, endIndex);
  }

  void loadLimitedList(int startIndex, int endIndex) async {
    _isLoading = true;
    firstLoadedIndex = startIndex;
    lastLoadedIndex = endIndex;
    print("loadLimitedList::lastLoadedIndex: $firstLoadedIndex");
    print("loadLimitedList::lastLoadedIndex: $lastLoadedIndex");
    if (isSongList()) {
      print("loadLimitedList::_limitedSongsLength: " +
          _limitedSongs.length.toString());
      _limitedSongs.clear();
      _limitedSongs.addAll(songs.sublist(firstLoadedIndex, lastLoadedIndex));
    } else {
      print("loadLimitedList::_limitedItemsLength: " +
          _limitedItems.length.toString());
      _limitedItems.clear();
      _limitedItems
          .addAll(items.toList().sublist(firstLoadedIndex, lastLoadedIndex));
    }
    notifyListeners();
    _isLoading = false;
  }

  void appendToLimitedList(bool fromEnd) async {
    _isLoading = true;
    int startIndex = firstLoadedIndex;
    int endIndex = lastLoadedIndex;
    if (fromEnd) {
      endIndex = lastLoadedIndex + loadIncrement;
      if (isSongList()) {
        endIndex = getEndForLimitedList(endIndex, songs.length);
      } else {
        endIndex = getEndForLimitedList(endIndex, items.length);
      }
    } else if (firstLoadedIndex > 0) {
      startIndex = firstLoadedIndex - loadIncrement;
      if (startIndex < 0) {
        startIndex = 0;
      }
    }

    loadLimitedList(startIndex, endIndex);
    _isLoading = false;
  }

  int getStartForLimitedList(int position) {
    int startIndex = position - loadIncrement;
    if (startIndex < 0) {
      startIndex = 0;
    }
    return startIndex;
  }

  int getEndForLimitedList(int position, int listLength) {
    int endIndex = position + loadIncrement;
    if (endIndex > listLength) {
      endIndex = listLength;
    }
    return endIndex;
  }

  void setFavorite(int songId, bool newFavorite) {
    sorter.setFavorite(songId, newFavorite);
    if (_sortString == columnFavorite) {
      loadFavoriteSongs();
    }
  }

  // Playlists
  void getPlaylists() async {
    _playlists.addAll(await sorter.getPlaylists());
  }

  Future<bool> addPlaylist(String name) async {
    bool exists = await sorter.addPlaylist(name);
    if (!exists) {
      addItem(name);
      itemTree[_sortString]!.items.add(name);
      populateQuickSort();
      _playlists.add(name);
    }
    return exists;
  }

  Future<void> deletePlaylist(int index) async {
    String name = _limitedItems[index];
    sorter.deletePlaylist(name);
    _playlists.remove(name);
    items.remove(name);
    _limitedItems.remove(name);

    notifyListeners();
  }

  Future<bool> addSongToPlaylist(int playlistIndex, int songIndex) async {
    bool exists = true;
    // Implement for other sort strings
    if (isSongList()) {
      int id = _limitedSongs[songIndex].id;
      String name = _playlists[playlistIndex];
      bool exists = await sorter.addSongToPlaylist(name, id);
      if (!exists) {
        // Show message saying song has been added
      }
    }
    return exists;
  }

  void safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify listeners after the current frame is rendered
    });
  }

  // Playback controls
  void play() async {
    final String path = _fullQueue.elementAt(_currentQueueIndex).source;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(path));
    _isPlaying = true;
    notifyListeners();
  }

  void pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  void pauseOrResume() async {
    if (_isPlaying) {
      pause();
    } else {
      resume();
    }
    notifyListeners();
  }

  void seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void playNextSong() async {
    //print("Current Song: $_currentQueueIndex");
    if (_repeat == 2) {
      if (_isPlaying) {
        seek(Duration.zero);
      } else {
        play();
      }
    } else {
      if (_currentQueueIndex < _fullQueue.length - 1) {
        _currentQueueIndex = _currentQueueIndex + 1;
      } else if (repeat == 1) {
        _currentQueueIndex = 0;
      }
    }
    //print("New Song: $_currentQueueIndex");
    play();
  }

  void playPreviousSong() async {
    //print("playprev");
    if (_currentDuration.inSeconds > 2) {
      seek(Duration.zero);
    } else {
      if (_currentQueueIndex > 0) {
        _currentQueueIndex = _currentQueueIndex - 1;
      } else {
        _currentQueueIndex = _fullQueue.length - 1;
      }
    }
    play();
  }

  void listenToDuration() {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentDuration = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      notifyListeners();
      playNextSong();
    });
  }

  set repeat(int repeat) {
    _repeat = repeat;
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_shuffle) {
      shuffleQueue();
    }
    notifyListeners();
  }

  // Queues
  void startQueue(int currentSongIndex) {
    autoQueue.clear();
    if (manualQueue.isNotEmpty) {
      manualQueue.removeFirst();
    }
    _currentQueueIndex = 0;
    Song currentSong = _limitedSongs[currentSongIndex];
    manualQueue.addFirst(currentSong);

    int songIndex = songs.indexOf(currentSong);
    autoQueue.addAll(songs.sublist(songIndex + 1, songs.length));

    _fullQueue.clear();
    _fullQueue.addAll(manualQueue);
    _fullQueue.addAll(autoQueue);

    if (shuffle) {
      shuffleQueue();
    }
    play();
  }

  void addToQueue(int index) async {
    if (isSongList()) {
      manualQueue.addLast(_limitedSongs[index]);
    } else {
      String query = _limitedItems[index];
      Map<String, String> selectedItemsNew = {};
      selectedItemsNew.addAll(selectedItems);
      selectedItemsNew[_sortString] = query;
      List<Song> songsToAdd = await sorter.getSongsWithFilter(
          sortOrder, searchStrings, selectedItemsNew);
      manualQueue.addAll(songsToAdd);
    }
    fullQueue.clear();
    fullQueue.addAll(manualQueue);
    fullQueue.addAll(autoQueue);
    // Add more queue logic for other sortStrings
  }

  void shuffleQueue() {
    //print("shuffling");
    // Step 1: Convert the queue to a list
    Song currentSong = _fullQueue.removeFirst();
    print(currentSong.title);
    List<Song> list = _fullQueue.toList();

    // Step 2: Shuffle the list
    final random = Random();
    for (int i = list.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1); // Random index between 0 and i
      var temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }

    // Step 3: Clear the queue and refill it with shuffled elements
    manualQueue.clear();
    autoQueue.clear();
    manualQueue.addFirst(currentSong);
    _currentQueueIndex = 0;
    autoQueue.addAll(list);
    _fullQueue.addAll(manualQueue);
    _fullQueue.addAll(autoQueue);
    notifyListeners();
  }
}

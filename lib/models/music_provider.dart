import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/audio_handler.dart';
import 'package:music_app/models/list_history.dart';
import 'package:music_app/models/music_sorter.dart';
import 'package:music_app/models/quick_sort.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:music_app/models/song.dart';

class MusicProvider extends ChangeNotifier {
  late AudioHandler audioHandler;
  final MusicSorter sorter = MusicSorter();

  // Lists
  final List<int> songIds = <int>[];
  final List<int> _limitedSongIds = <int>[];
  final Map<String, ListHistory> itemTree = {};
  final LinkedHashSet<String> items = LinkedHashSet();
  final List<String> _limitedItems = <String>[];
  final Map<String, QuickSort> quickSortMap = {};
  final List<String> _playlists = <String>[];
  int _playingSongIndex = -1;
  bool _isLoading = false;
  int firstLoadedIndex = 0;
  int lastLoadedIndex = 0;
  int loadIncrement = 100;

  // Sorting
  String _sortString = sortSongs;
  final List<String> _sortOrder = <String>[sortSongs];
  final Map<String, String> _searchStrings = {};
  final Map<String, String> selectedItems = {};
  bool _isFirstSort = true;
  bool _shouldShowSidebar = true;
  String _orderType = orderAlphabetically;
  final Map<String, String> _chronologicalQuickSort = {};

  // Playback
  bool _isPlaying = false;
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _shuffle = false;
  int _repeat = 0; // 0 = off, 1 = repeat, 2 = repeat1

  // Queue
  final List<int> _queue = <int>[];
  final List<int> manualQueue = <int>[];
  int _currentQueueIndex = -1;

  // Getters
  // Lists
  List<int> get limitedSongIds => _limitedSongIds;
  List<int> get queue => _queue;
  List<String> get limitedItems => _limitedItems;
  bool get isLoading => _isLoading;
  List<String> get playlists => _playlists;
  int get playingSongIndex => _playingSongIndex;
  Map<String, String> get chronologicalQuickSort => _chronologicalQuickSort;

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
    init();
  }

  void init() async {
    audioHandler = await initAudioService(this);
  }

  // Loading
  void loadSongs() async {
    songIds.clear();
    _limitedSongIds.clear();
    print("loadSongs::_sortOrder: $_sortOrder");
    await sorter.populateSongs(this);
    if (_limitedSongIds.isEmpty) {
      loadStartOfList(songIds.length);
    }
    populateQuickSort();
  }

  void loadSongsWithFilter() async {
    songIds.clear();
    _limitedSongIds.clear();
    _sortString = sortSongs;
    setIsFirstSort();
    await sorter.populateSongsWithFilter(this);
    if (_limitedSongIds.isEmpty) {
      loadStartOfList(songIds.length);
    }
    populateQuickSort();
  }

  void loadFavoriteSongs() async {
    songIds.clear();
    _limitedSongIds.clear();
    setIsFirstSort();
    await sorter.populateFavoriteSongs(this);
    if (_limitedSongIds.isEmpty) {
      loadStartOfList(songIds.length);
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
    setOrderType();
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
    if (_sortString == sortSongs) {
      List<int> tempSongs = sorter.searchSongs(songIds, query);
      _limitedSongIds.clear();
      _limitedSongIds.addAll(tempSongs);
    } else {
      items.clear();
      items.addAll(sorter.searchItems(itemTree[_sortString]!.items, query));
    }
    safeNotify();
  }

  void addSong(int songId) {
    songIds.add(songId);
    print("addSong::limitedSongs: $limitedSongIds");
    if (limitedSongIds.isEmpty) {
      //print("addSong::songsLength: " + songs.length.toString());
      //print("addSong::populationSize: " + sorter.populationSize.toString());
      if (songIds.length > loadIncrement) {
        loadStartOfList(songIds.length);
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
    String yearOrderType = SettingsProvider().yearOrderType;

    print("setOrderType::_sortString: $_sortString");
    if (_sortString == sortSongs && sortOrder.length > 1) {
      _orderType = songOrderType;
    } else if (_sortString == sortAlbums) {
      _orderType = albumOrderType;
    } else if (_sortString == sortYears || _sortString == sortDecades) {
      _orderType = yearOrderType;
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
    if (!isSongList()) {
      _sortOrder.add(sortSongs);
    }

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
    _limitedSongIds.clear();
    _limitedItems.clear();

    setOrderType();
    if (_sortString == sortSongs) {
      loadSongsWithFilter();
    } else if (_sortString == sortFavorites) {
      loadFavoriteSongs();
    } else if (sortOrder.length == 2 && sortOrder.contains(sortPlaylists)) {
      loadPlaylists();
    } else {
      loadItemsWithFilter();
    }
    safeNotify();
  }

  bool isSongList() {
    if (_sortString == sortSongs || _sortString == sortFavorites) {
      return true;
    }
    return false;
  }

  // Quick Sort
  set chronologicalQuickSort(Map<String, String> items) {
    _chronologicalQuickSort.clear();
    _chronologicalQuickSort.addAll(items);
    notifyListeners();
  }

  void setShouldShowSidebar() {
    bool songList = isSongList();
    if (_sortString == sortDateAdded) {
      _shouldShowSidebar = false;
    } else if (songList && _limitedSongIds.length <= quickSortMinimumLimit) {
      _shouldShowSidebar = false;
    } else if (!songList && items.length <= quickSortMinimumLimit) {
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
      return chronologicalQuickSort.keys.toList();
    }
  }

  void populateQuickSort() {
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
          lastPosition = quickSort.initialize(this, item, lastPosition);
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
    //print("loadLimitedList::lastLoadedIndex: $firstLoadedIndex");
    //print("loadLimitedList::lastLoadedIndex: $lastLoadedIndex");
    if (isSongList()) {
      /*print("loadLimitedList::_limitedSongsLength: " +
          _limitedSongIds.length.toString());*/
      _limitedSongIds.clear();
      _limitedSongIds
          .addAll(songIds.sublist(firstLoadedIndex, lastLoadedIndex));
      if (_currentQueueIndex != -1) {
        _playingSongIndex = _limitedSongIds.indexOf(_queue[_currentQueueIndex]);
      }
    } else {
      /*print("loadLimitedList::_limitedItemsLength: " +
          _limitedItems.length.toString());*/
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
        endIndex = getEndForLimitedList(endIndex, songIds.length);
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
    if (_sortString == sortFavorites) {
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
      loadPlaylists();
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
      int id = _limitedSongIds[songIndex];
      String name = _playlists[playlistIndex];
      bool exists = await sorter.addSongToPlaylist(name, id);
      if (!exists) {
        // Show message saying song has been added
      }
    }
    return exists;
  }

  Song getSongFromId(int id) {
    return sorter.allSongs[id]!;
  }

  void safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify listeners after the current frame is rendered
    });
  }

  // Playback
  set isPlaying(bool isPlaying) {
    _isPlaying = isPlaying;
    notifyListeners();
  }

  void pauseOrResume() async {
    if (_isPlaying) {
      _isPlaying = false;
      audioHandler.pause();
    } else {
      _isPlaying = true;
      audioHandler.resume();
    }
    notifyListeners();
  }

  void playNextSong() async {
    if (audioHandler.playerIsReady()) {
      if (_repeat == 2) {
        if (_isPlaying) {
          audioHandler.seek(Duration.zero);
        }
      } else {
        if (_currentQueueIndex < _queue.length - 1) {
          _currentQueueIndex++;
          _playingSongIndex++;
          manualQueue.remove(_queue[_currentQueueIndex]);
          audioHandler.seekToNext();
        } else if (_repeat == 1) {
          _currentQueueIndex = 0;
          audioHandler.restartPlaylist();
          audioHandler.play();
        } else {
          _currentQueueIndex = -1;
          audioHandler.restartPlaylist();
        }
      }
    }
  }

  void playPreviousSong() async {
    if (audioHandler.playerIsReady()) {
      if (_currentDuration.inSeconds > 2 || _currentQueueIndex == 0) {
        audioHandler.seek(Duration.zero);
      } else {
        _currentQueueIndex--;
        _playingSongIndex--;
        audioHandler.seekToPrevious();
      }
    }
  }

  set totalDuration(Duration totalDuration) {
    _totalDuration = totalDuration;
    notifyListeners();
  }

  set currentDuration(Duration currentDuration) {
    _currentDuration = currentDuration;
    notifyListeners();
  }

  set repeat(int repeat) {
    _repeat = repeat;
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (shuffle) {
      shuffleQueue();
    }
    notifyListeners();
  }

  Song getCurrentSong() {
    int songId = _queue[_currentQueueIndex];
    return getSongFromId(songId);
  }

  // Queue
  set currentQueueIndex(int currentQueueIndex) {
    _currentQueueIndex = currentQueueIndex;
    notifyListeners();
  }

  void startQueue(int currentSongIndex) async {
    audioHandler.restartPlaylist();
    audioHandler.clearPlaylist();

    _playingSongIndex = currentSongIndex;

    int songId = _limitedSongIds[currentSongIndex];
    int songIndex = songIds.indexOf(songId);
    List<int> songIdsToPlay = <int>[songId];
    songIdsToPlay.addAll(songIds.sublist(songIndex + 1, songIds.length));

    _currentQueueIndex = 0;
    manualQueue.insert(0, songId);

    audioHandler.addToPlaylist(songIdsToPlay);

    _queue.clear();
    _queue.addAll(songIdsToPlay);

    if (_shuffle) {
      shuffleQueue();
    }
    audioHandler.updateSongAndPlay();
  }

  void addToQueue(int index) async {
    if (isSongList()) {
      addSongToQueue(_limitedSongIds[index]);
    } else {
      String query = _limitedItems[index];
      Map<String, String> selectedItemsNew = {};
      selectedItemsNew.addAll(selectedItems);
      selectedItemsNew[_sortString] = query;
      List<int> songIdsToAdd = await sorter.getSongsWithFilter(
          sortOrder, searchStrings, selectedItemsNew);
      addSongsToQueue(songIdsToAdd);
    }
  }

  void addSongToQueue(int songId) async {
    int position = getNextManualQueuePosition();
    manualQueue.add(songId);
    audioHandler.addToPlaylistAtIndex(<int>[songId], position);

    _queue.insert(position, songId);
  }

  void addSongsToQueue(List<int> songIds) async {
    int position = getNextManualQueuePosition();
    manualQueue.addAll(songIds);
    audioHandler.addToPlaylistAtIndex(songIds, position);

    _queue.insertAll(position, songIds);
  }

  void shuffleQueue() async {
    //print("shuffling");
    // Step 1: Convert the queue to a list
    List<int> autoQueue = <int>[];
    autoQueue.addAll(_queue);
    int currentSongId = -1;
    if (autoQueue.isNotEmpty) {
      currentSongId = autoQueue.removeAt(0);
      autoQueue.shuffle();
    }

    // Step 2: Shuffle the list
    /*final random = Random();
    for (int i = list.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1); // Random index between 0 and i
      var temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }*/

    // Step 3: Clear the queue and refill it with shuffled elements
    manualQueue.clear();
    if (currentSongId != -1) {
      manualQueue.add(currentSongId);
    }
    _currentQueueIndex = 0;
    _queue.clear();
    _queue.addAll(manualQueue);
    _queue.addAll(autoQueue);
    notifyListeners();

    // Figure out how to shuffle using the playlist var
    audioHandler.shufflePlaylist(_queue, _currentQueueIndex);
  }

  int getNextManualQueuePosition() {
    int lastManualQueueElement = -1;
    if (manualQueue.isNotEmpty) {
      lastManualQueueElement = manualQueue[manualQueue.length - 1];
    }
    int lastPosition = _queue.indexOf(lastManualQueueElement);
    if (lastPosition < _currentQueueIndex) {
      lastPosition = _currentQueueIndex;
    }

    return lastPosition + 1;
  }
}

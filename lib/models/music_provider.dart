import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/audio_handler.dart';
import 'package:music_app/models/file_helper.dart';
import 'package:music_app/models/lazy_list.dart';
import 'package:music_app/models/list_history.dart';
import 'package:music_app/models/music_sorter.dart';
import 'package:music_app/models/quick_sort.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:music_app/models/song.dart';

class MusicProvider extends ChangeNotifier {
  late AudioHandler audioHandler;
  final MusicSorter sorter = MusicSorter();

  // Lists
  final Map<int, Song> _allSongs = {};
  final List<int> songIds = <int>[];
  final LazyList<int> _limitedSongIds = LazyList<int>();
  final Map<String, ListHistory> itemTree = {};
  final LinkedHashSet<String> items = LinkedHashSet();
  final LazyList<String> _limitedItems = LazyList<String>();
  final Map<String, QuickSort> quickSortMap = {};
  final LinkedHashMap<String, bool> _playlists = LinkedHashMap();
  int _playingSongIndex = -1;

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
  Map<int, Song> get allSongs => _allSongs;
  List<int> get limitedSongIds => _limitedSongIds;
  List<int> get queue => _queue;
  List<String> get limitedItems => _limitedItems;
  Map<String, bool> get playlists => _playlists;
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
    SettingsProvider().populateAllSettingsFromDatabase();
  }

  void addSong(int songId, Song song) {
    _allSongs[songId] = song;
  }

  void addSongs(Map<int, Song> songs) {
    _allSongs.addAll(songs);
  }

  // Loading
  void loadSongs() async {
    songIds.clear();
    await sorter.populateFirstSongs(this);
    loadSongsFromList();
    await sorter.populateAllSongs(this);

    FileHelper fileHelper = FileHelper();
    fileHelper.loadAlbumArt(this);
    populateQuickSort();
  }

  void reloadSong(int songId) async {
    await sorter.populateAllSongs(this);
  }

  void loadSongsWithFilter() async {
    songIds.clear();
    _sortString = sortSongs;
    setIsFirstSort();
    await sorter.populateSongsWithFilter(this);
    loadSongsFromList();
    populateQuickSort();
  }

  void loadFavoriteSongs() async {
    songIds.clear();
    setIsFirstSort();
    await sorter.populateFavoriteSongs(this);
    loadSongsFromList();
    populateQuickSort();
  }

  void loadItemsWithFilter() async {
    items.clear();
    safeNotify();

    await sorter.populateItemListWithFilter(this);
    loadItemsFromList();
    populateQuickSort();
    populateListHistory();
  }

  void loadPlaylists() async {
    items.clear();
    safeNotify();

    _playlists.addAll(await sorter.populatePlaylists());
    items.addAll(_playlists.keys);
    loadItemsFromList();
    populateQuickSort();
    populateListHistory();
  }

  Future<void> loadPreviousItems() async {
    setOrderType();
    if (!itemTree.containsKey(_sortString)) {
      loadPageList();
    } else {
      items.clear();
      ListHistory history = itemTree[_sortString]!;
      items.addAll(history.items);
      _limitedItems.load(history.startIndex, history.endIndex, history.items);
    }
    populateQuickSort();
    notifyListeners();
  }

  void loadSongsFromList() {
    _limitedSongIds.loadStart(songIds);
    setPlayingSongIndex();
    notifyListeners();
  }

  void loadItemsFromList() {
    _limitedItems.loadStart(items.toList());
    notifyListeners();
  }

  void setAlbumArtForSong(int songId, Uint8List albumArt) {
    allSongs[songId]!.albumArt = albumArt;
  }

  void query(String query) {
    if (_sortString == sortSongs) {
      List<int> tempSongs = sorter.searchSongs(songIds, query, allSongs);
      _limitedSongIds.loadStart(tempSongs);
    } else {
      List<String> tempItems = sorter.searchItems(items.toList(), query);
      _limitedItems.loadStart(tempItems);
    }
    safeNotify();
  }

  void addSongToList(int songId) {
    songIds.add(songId);
    //print("addSong::limitedSongs: $limitedSongIds");
    if (limitedSongIds.isEmpty) {
      //print("addSong::songsLength: " + songs.length.toString());
      //print("addSong::populationSize: " + sorter.populationSize.toString());
      if (songIds.length > loadIncrement) {
        loadSongsFromList();
      }
    }
    notifyListeners();
  }

  void addItemToList(String item) {
    items.add(item);
    if (limitedItems.isEmpty) {
      if (items.length > loadIncrement) {
        loadItemsFromList();
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

    //print("setOrderType::_sortString: $_sortString");
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
    print("getPreviousSort::_sortString: $_sortString");
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

  void getNextSort(int itemIndex) async {
    print("getNextSort::sortString: $_sortString");
    // Get selected item
    String query = _limitedItems.elementAt(itemIndex);
    selectedItems[_sortString] = query;

    // Set historical limitedList indexes
    itemTree[_sortString]!.startIndex = _limitedItems.firstLoadedIndex;
    itemTree[_sortString]!.endIndex = _limitedItems.lastLoadedIndex;

    //print("getNextSort::sortOrder: $_sortOrder");
    if (_sortString == sortPlaylists) {
      bool isSorted = await sorter.playlistIsSorted(query);
      print("getNextSort::isSorted: $isSorted");
      if (isSorted) {
        await setSortForPlaylist(query);
      }
    }
    int sortIndex = _sortOrder.indexOf(_sortString);
    if (sortIndex + 1 < _sortOrder.length) {
      _sortString = _sortOrder[sortIndex + 1];
    }
    setIsFirstSort();
    //print("getNextSort::sortString2: $_sortString");
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

    //print("setSortSingle::_sortOrder: $_sortOrder");
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

  Future<void> setSortForPlaylist(String name) async {
    List<String> playlistSortOrder =
        await sorter.getSortOrderFromPlaylistSort(name);
    Map<String, String> playlistSearchStrings =
        await sorter.getSearchStringsFromPlaylistSort(name);
    _sortOrder.clear();
    _sortOrder.addAll(playlistSortOrder);
    _searchStrings.addAll(playlistSearchStrings);
  }

  void clearSortLists() {
    print("clearSortLists");
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

  void appendToLimitedList(bool fromEnd) {
    if (isSongList()) {
      _limitedSongIds.append(fromEnd, songIds);
    } else {
      _limitedItems.append(fromEnd, items.toList());
    }
    notifyListeners();
  }

  bool isSongList() {
    if (_sortString == sortSongs || _sortString == sortFavorites) {
      return true;
    }
    return false;
  }

  bool atTopOfList() {
    if (isSongList()) {
      return _limitedSongIds.firstLoadedIndex == 0;
    }
    return _limitedItems.firstLoadedIndex == 0;
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
      QuickSort quickSort = quickSortMap[item]!;

      if (isSongList()) {
        _limitedSongIds.load(quickSort.startIndex, quickSort.endIndex, songIds);
        setPlayingSongIndex();
      } else {
        _limitedItems.load(
            quickSort.startIndex, quickSort.endIndex, items.toList());
      }

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
        ListHistory history = itemTree[_sortString]!;
        quickSortMap.clear();
        quickSortMap.addAll(history.quickSort);
        chronologicalQuickSort.clear();
        chronologicalQuickSort.addAll(history.chronologicalQuickSort);
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

  void populateListHistory() {
    List<String> itemList = <String>[];
    itemList.addAll(items);

    Map<String, QuickSort> tempQuickSort = {};
    Map<String, String> tempChronologicalQuickSort = {};
    tempQuickSort.addAll(quickSortMap);
    tempChronologicalQuickSort.addAll(chronologicalQuickSort);

    itemTree[_sortString] = ListHistory(
        items: itemList,
        quickSort: tempQuickSort,
        chronologicalQuickSort: tempChronologicalQuickSort);
  }

  void setFavorite(int songId, bool newFavorite) {
    sorter.setFavorite(songId, newFavorite);
    if (_sortString == sortFavorites) {
      loadFavoriteSongs();
    }
  }

  void setPlayingSongIndex() {
    if (_currentQueueIndex != -1) {
      _playingSongIndex = _limitedSongIds.indexOf(_queue[_currentQueueIndex]);
    }
  }

  // Playlists
  void populatePlaylists() async {
    _playlists.addAll(await sorter.populatePlaylists());
  }

  List<String> getUnsortedPlaylists() {
    List<String> unsortedPlaylists = <String>[];
    for (String name in _playlists.keys) {
      if (!_playlists[name]!) {
        unsortedPlaylists.add(name);
      }
    }
    return unsortedPlaylists;
  }

  Future<bool> playlistExists(String name) async {
    return await sorter.playlistExists(name);
  }

  Future<void> addPlaylist(String name, bool isSorted) async {
    await sorter.addPlaylist(name, isSorted);

    loadPlaylists();
  }

  Future<void> deletePlaylist(int index) async {
    String name = _limitedItems[index];
    sorter.deletePlaylist(name);
    _playlists.remove(name);
    items.remove(name);
    _limitedItems.remove(name);

    notifyListeners();
  }

  Future<bool> addSongToPlaylist(int playlistIndex, int songId) async {
    bool exists = true;
    // Implement for other sort strings
    String name = _playlists.keys.elementAt(playlistIndex);
    exists = await sorter.addSongToPlaylist(name, songId);
    return exists;
  }

  Future<void> addSongsToPlaylist(int playlistIndex, String item) async {
    // Implement for other sort strings
    String name = _playlists.keys.elementAt(playlistIndex);

    Map<String, String> selectedItemsNew = {};
    selectedItemsNew.addAll(selectedItems);
    selectedItemsNew[_sortString] = item;
    List<int> songIdsToAdd = await sorter.getSongsWithFilter(
        sortOrder, searchStrings, selectedItemsNew);

    for (int songId in songIdsToAdd) {
      await sorter.addSongToPlaylist(name, songId);
    }
  }

  Future<void> deleteSongFromPlaylist(int songIndex) async {
    // Implement for other sort strings
    String name = selectedItems[sortPlaylists]!;
    int songId = _limitedSongIds[songIndex];
    await sorter.deleteSongFromPlaylist(name, songId);

    _limitedSongIds.removeAt(songIndex);
    songIds.remove(songId);
    notifyListeners();
  }

  Future<void> addPlaylistSort(String name) async {
    await sorter.addPlaylistSort(name, _sortOrder, _searchStrings);
  }

  Song getSongFromId(int id) {
    return _allSongs[id]!;
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

  void skipToNext() {
    if (audioHandler.playerIsReady()) {
      if (_repeat == 2) {
        if (_isPlaying) {
          audioHandler.seek(Duration.zero);
        }
      } else {
        if (_currentQueueIndex < _queue.length - 1) {
          if (!_isPlaying) {
            setToNextSong();
          }
          audioHandler.seekToNext();
        } else if (_repeat == 1) {
          audioHandler.restartPlaylist();
          audioHandler.play();
        } else {
          audioHandler.restartPlaylist();
        }
      }
    }
  }

  void skipToPrevious() {
    if (audioHandler.playerIsReady()) {
      if (_currentDuration.inSeconds > 2 || _currentQueueIndex == 0) {
        audioHandler.seek(Duration.zero);
      } else {
        if (!_isPlaying) {
          setToPreviousSong();
        }
        audioHandler.seekToPrevious();
      }
    }
  }

  void setToNextSong() async {
    if (audioHandler.playerIsReady()) {
      if (_repeat != 2) {
        print("setToNextSong::_currentQueueIndex: $_currentQueueIndex");
        if (_currentQueueIndex < _queue.length - 1) {
          _currentQueueIndex++;
          _playingSongIndex++;
          manualQueue.remove(_queue[_currentQueueIndex]);
        } else if (_repeat == 1) {
          _currentQueueIndex = 0;
        } else {
          _currentQueueIndex = -1;
        }
      }
    }
    print("setToNextSong::_currentQueueIndex: $_currentQueueIndex");
  }

  void setToPreviousSong() async {
    if (audioHandler.playerIsReady()) {
      if (_currentDuration.inSeconds > 2 || _currentQueueIndex == 0) {
      } else {
        print("setToPreviousSong::_currentQueueIndex: $_currentQueueIndex");
        _currentQueueIndex--;
        _playingSongIndex--;
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

  void playSongFromQueue(int queueIndex) {
    print("playSongFromQueue::queueIndex: $queueIndex");
    _currentQueueIndex = queueIndex;
    notifyListeners();
    audioHandler.addToPlaylistFromQueue(queueIndex);
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

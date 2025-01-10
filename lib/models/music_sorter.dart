import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:intl/intl.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:music_app/models/song.dart';

class MusicSorter {
  DatabaseHelper db = DatabaseHelper();
  Map<int, Song> allSongs = {};
  bool allSongsPopulated = false;
  late SettingsProvider settingsProvider;

  void populateSongsFromDatabaseResults(
      List<Map<String, Object?>> results, MusicProvider provider) async {
    for (Map<String, Object?> row in results) {
      int id = row[columnId] as int;
      String title = row[columnTitle].toString();
      String album = row[columnAlbum].toString();
      String artist = row[columnArtist].toString();
      String albumArtist = row[columnAlbumArtist].toString();
      String genre = row[columnGenre].toString();
      String year = row[columnYear].toString();
      String source = row[columnSource].toString();
      int trackNumber = row[columnTrackNumber] as int;
      int totalTrackCount = row[columnTotalTrackCount] as int;
      int duration = row[columnDuration] as int;

      int favoriteInt =
          row[columnFavorite] == null ? 0 : row[columnFavorite] as int;
      bool favorite = favoriteInt == 1 ? true : false;

      DateFormat format = DateFormat("dd-MMM-yyyy");
      DateTime modifiedDate = format.parse(row[columnModifiedDate].toString());

      //Uint8List albumArt = await getAlbumArt(File(source));

      Song song = Song(
          id: id,
          title: title,
          artist: artist,
          album: album,
          albumArtist: albumArtist,
          genre: genre,
          year: year,
          trackNumber: trackNumber,
          totalTrackCount: totalTrackCount,
          duration: duration,
          modifiedDate: modifiedDate,
          albumArt: Uint8List(0),
          source: source,
          favorite: favorite);

      if (!allSongsPopulated) {
        allSongs[id] = song;
      }
      provider.addSong(song);
      //print(title);
    }
    allSongsPopulated = true;
    //print("done loading songs");
    loadAlbumArt();
  }

  Future<void> loadAlbumArt() async {
    Iterator<Song> iterator = allSongs.values.iterator;
    while (iterator.moveNext()) {
      Song song = iterator.current;
      song.albumArt = await getAlbumArt(File(song.source));
    }
  }

  Future<Uint8List> getAlbumArt(File file) async {
    Uint8List albumArt = Uint8List(0);
    try {
      Tag? tag = await AudioTags.read(file.path);
      albumArt = tag?.pictures[0].bytes ?? Uint8List(0);
    } catch (e) {
      print(e.toString());
    }
    return albumArt;
  }

  Future<void> populateSongs(MusicProvider provider) async {
    print(allSongs.isEmpty);
    if (allSongs.isEmpty) {
      List<String> projection = [
        columnId,
        columnTitle,
        columnAlbum,
        columnArtist,
        columnAlbumArtist,
        columnGenre,
        columnYear,
        columnSource,
        columnTrackNumber,
        columnTotalTrackCount,
        columnDuration,
        columnModifiedDate,
        columnFavorite
      ];
      List<String> selectionArgs = ["%"];
      String orderBy = getOrderBy(tableSongs, provider.sortOrder);
      List<Map<String, Object?>> results = await db.normalQuery(
          "$tableSongs AS S",
          projection,
          "Title LIKE ?",
          selectionArgs,
          orderBy);

      populateSongsFromDatabaseResults(results, provider);
    } else {
      Iterator<Song> iterator = allSongs.values.iterator;
      while (iterator.moveNext()) {
        Song song = iterator.current;
        provider.addSong(song);
      }
    }
  }

  Future<void> populateSongsWithFilter(MusicProvider provider) async {
    List<String> sortOrder = provider.sortOrder;
    Map<String, String> searchStrings = provider.searchStrings;
    Map<String, String> selectedItems = provider.selectedItems;
    List<Map<String, Object?>> results =
        await getSongResultsWithFilter(sortOrder, searchStrings, selectedItems);
    for (Map<String, Object?> row in results) {
      int id = row[columnId] as int;
      //String title = row[columnTitle].toString();
      //print(title);
      if (allSongs[id] != null) {
        provider.addSong(allSongs[id]!);
      }
    }
  }

  Future<List<Song>> getSongsWithFilter(
      List<String> sortOrder,
      Map<String, String> searchStrings,
      Map<String, String> selectedItems) async {
    List<Song> songs = <Song>[];
    List<Map<String, Object?>> results =
        await getSongResultsWithFilter(sortOrder, searchStrings, selectedItems);
    for (Map<String, Object?> row in results) {
      int id = row[columnId] as int;
      //String title = row[columnTitle].toString();
      //print(title);
      if (allSongs[id] != null) {
        songs.add(allSongs[id]!);
      }
    }

    return songs;
  }

  Future<List<Map<String, Object?>>> getSongResultsWithFilter(
      List<String> sortOrder,
      Map<String, String> searchStrings,
      Map<String, String> selectedItems) async {
    List<String> params = buildParams(sortOrder, searchStrings, selectedItems);
    String query =
        buildQuery(tableSongs, sortOrder, searchStrings, selectedItems);
    //print("populateSongsWithFilter::query: $query");
    //print("populateSongsWithFilter::params: $params");

    return await db.customQuery(query, params);
  }

  Future<void> populateFavoriteSongs(MusicProvider provider) async {
    String query =
        "SELECT $columnId, $columnTitle FROM $tableSongs WHERE $columnFavorite = 1";
    print(query);
    List<Map<String, Object?>> results = await db.customQuery(query, []);
    for (Map<String, Object?> row in results) {
      int id = row[columnId] as int;
      if (allSongs[id] != null) {
        provider.addSong(allSongs[id]!);
      }
    }
  }

  void populateItemsFromDatabaseResults(List<Map<String, Object?>> results,
      String projection, MusicProvider provider) {
    for (Map<String, Object?> row in results) {
      String itemName = row[projection].toString();

      provider.addItem(itemName);
      //print(itemName);
    }
  }

  Future<void> populateItemListWithFilter(MusicProvider provider) async {
    String sortString = provider.sortString;
    List<String> sortOrder = provider.sortOrder;
    Map<String, String> searchStrings = provider.searchStrings;
    Map<String, String> selectedItems = provider.selectedItems;
    print("populateItemListWithFilter::sortString: $sortString");
    print("populateItemListWithFilter::sortOrder: $sortOrder");
    print("populateItemListWithFilter::searchStrings: $searchStrings");
    print("populateItemListWithFilter::selectedItems: $selectedItems");
    List<String> params = buildParams(sortOrder, searchStrings, selectedItems);
    String query =
        buildQuery(sortString, sortOrder, searchStrings, selectedItems);
    print("populateItemListWithFilter::query: $query");
    print("populateItemListWithFilter::params: $params");

    List<Map<String, Object?>> results = await db.customQuery(query, params);
    print("populateItemListWithFilter::results: $results");
    print("populateItemListWithFilter::sortString: $sortString");
    for (Map<String, Object?> row in results) {
      String item = row[sortString].toString();
      provider.addItem(item);
    }
  }

  // Playlists
  Future<List<String>> getPlaylists() async {
    List<String> playlists = <String>[];
    String query = "SELECT $columnName FROM $tablePlaylists";
    print(query);
    List<Map<String, Object?>> results = await db.customQuery(query, []);
    for (Map<String, Object?> row in results) {
      playlists.add(row[columnName]!.toString());
    }
    return playlists;
  }

  Future<bool> addPlaylist(String name) async {
    DatabaseHelper db = DatabaseHelper();
    String currentPlaylist = await db.easyShortQuery(
        tablePlaylists, columnName, "$columnName = ?", name);

    if (currentPlaylist.isNotEmpty) {
      return true;
    } else {
      Map<String, String> data = {};
      data[columnName] = name;
      db.insert(tablePlaylists, data);
    }
    return false;
  }

  Future<void> deletePlaylist(String name) async {
    String deleteFromPlaylistSongsQuery =
        "DELETE FROM $tablePlaylistSongs WHERE $columnPlaylistName = ?";
    db.customQuery(deleteFromPlaylistSongsQuery, [name]);

    String deleteFromPlaylistsQuery =
        "DELETE FROM $tablePlaylists WHERE $columnName = ?";
    db.customQuery(deleteFromPlaylistsQuery, [name]);
  }

  Future<bool> addSongToPlaylist(String name, int id) async {
    DatabaseHelper db = DatabaseHelper();
    List<String> currentPlaylistSongs = await db.easyQuery(
        tablePlaylistSongs, columnSongId, "$columnPlaylistName = ?", [name]);

    if (currentPlaylistSongs.contains(id.toString())) {
      return true;
    } else {
      Map<String, String> data = {};
      int sequence = currentPlaylistSongs.length + 1;
      data[columnPlaylistName] = name;
      data[columnSongId] = id.toString();
      data[columnSequence] = sequence.toString();
      db.insert(tablePlaylistSongs, data);
    }
    return false;
  }

  // Search
  List<String> searchItems(List<String> list, String query) {
    // Clean the query as well
    String cleanedQuery = cleanString(query);

    // Filter the list and return only the matches (case-insensitive and ignoring "The " and "A ").
    return list.where((item) {
      return cleanString(item).contains(cleanedQuery);
    }).toList();
  }

  List<Song> searchSongs(List<Song> list, String query) {
    // Clean the query as well
    String cleanedQuery = cleanString(query);

    // Filter the list and return only the matches (case-insensitive and ignoring "The " and "A ").
    return list.where((song) {
      return cleanString(song.title).contains(cleanedQuery);
    }).toList();
  }

  String cleanString(String str) {
    bool ignoreThe = SettingsProvider().ignoreThe;
    bool ignoreA = SettingsProvider().ignoreA;
    String regexString = '';

    if (ignoreThe && ignoreA) {
      regexString = r'^(the|a)\s';
    } else if (ignoreThe) {
      regexString = r'^(the)\s';
    } else if (ignoreA) {
      regexString = r'^(a)\s';
    }

    str = str.trim().toLowerCase();
    RegExp regex = RegExp(regexString);
    str = str.replaceFirst(regex, ''); // Remove "The " or "A " at the start
    return str;
  }

  void setFavorite(int songId, bool newFavorite) {
    int favoriteInt = newFavorite ? 1 : 0;
    Map<String, int> data = {};
    data[columnFavorite] = favoriteInt;
    db.update(tableSongs, songId, data);
  }

  String buildQuery(String sortString, List<String> sortOrder,
      Map<String, String> searchStrings, Map<String, String> selectedItems) {
    String select = "";
    String from = "";
    String where = "";
    String orderBy = getOrderBy(sortString, sortOrder);

    for (String sort in sortOrder) {
      if (sort == tablePlaylists) {
        select += "P.$columnName";
        from += getJoinType(from, sortString);
        from += "$tablePlaylists AS P\n";
        where += getWhere(
            where, sort, "P.$columnPlaylistName", searchStrings, selectedItems);
      } else if (sort == columnArtist) {
        select += "A.$columnArtist";
        from += getJoinType(from, sort);
        from += "$tableArtists AS A\n";
        where += getWhere(where, sort, "A.$sort", searchStrings, selectedItems);
      } else if (sort == columnAlbum) {
        select += "S.$columnAlbum";
        where += getWhere(where, sort, "S.$sort", searchStrings, selectedItems);
      } else if (sort == columnGenre) {
        select += "G.$columnGenre";
        from += getJoinType(from, sort);
        from += "$tableGenres AS G\n";
        where += getWhere(where, sort, "G.$sort", searchStrings, selectedItems);
      } else if (sort == columnYear) {
        select += "S.$columnYear";
        where += getWhere(where, sort, "S.$sort", searchStrings, selectedItems);
      } else if (sort == columnModifiedDate) {
        select += "S.$columnModifiedDate";
        where += getWhere(where, sort, "S.$sort", searchStrings, selectedItems);
      } else if (sort == tableSongs) {
        select += "S.$columnId, S.$columnTitle";
        from += getJoinType(from, sort);
        from += "$tableSongs AS S \n";
        where += getWhere(
            where, sort, "S.$columnTitle", searchStrings, selectedItems);
      }
      //print("buildQuery::from: $from");
      select += ", ";
    }
    //print("buildQuery::from: $from");
    select = select.substring(0, select.length - 2);
    //print("buildQuery::from: $from");
    if (where.length == 6) {
      where = "";
    }

    if (sortOrder.contains(columnArtist)) {
      from +=
          "JOIN $tableSongArtists AS SA ON S.$columnId = SA.$columnSongId AND A.$columnId = SA.$columnArtistId\n";
    }
    if (sortOrder.contains(columnGenre)) {
      from +=
          "JOIN $tableSongGenres AS SG ON S.ID = SG.$columnSongId AND G.$columnId = SG.$columnGenreId";
    }
    if (sortOrder.contains(tablePlaylists)) {
      from +=
          "LEFT JOIN $tablePlaylistSongs AS SP ON S.$columnId = SP.$columnSongId AND P.$columnName = SP.$columnPlaylistName";
    }

    return "SELECT DISTINCT $select $from $where ORDER BY $orderBy";
  }

  String getJoinType(String from, String sortString) {
    String join = "";
    if (from.isEmpty) {
      join = "FROM ";
    } else {
      join = "JOIN ";
    }

    return join;
  }

  String getWhere(String oldWhere, String sortString, String column,
      Map<String, String> searchStrings, Map<String, String> selectedItems) {
    String where = "";
    String and = "AND ";
    if (oldWhere.isEmpty) {
      and = "WHERE ";
    }
    String search = searchStrings[sortString] ?? "";
    if (search.isNotEmpty) {
      where += "$and $column LIKE ? COLLATE NOCASE\n";
      and = "AND ";
    }
    String item = selectedItems[sortString] ?? "";
    if (item.isNotEmpty) {
      where += "$and $column = ?\n";
      and = "AND ";
    }
    return where;
  }

  List<String> buildParams(List<String> sortOrder,
      Map<String, String> searchStrings, Map<String, String> selectedItems) {
    List<String> selection = <String>[];

    selection =
        addParsedSearchString(searchStrings[tableSongs], selection, tableSongs);

    for (String sort in sortOrder) {
      if (sort != tableSongs) {
        //print("buildParams::sort $sort");
        selection = addParsedSearchString(searchStrings[sort], selection, sort);
        String item = selectedItems[sort] ?? "";
        if (item.isNotEmpty) {
          selection.add(item);
        }
      }
    }
    return selection;
  }

  List<String> addParsedSearchString(
      String? searchString, List<String> selection, String sortString) {
    //print("addParsedSearchString::searchString: $searchString");
    String parsedString = searchString ?? "";
    if (parsedString.isNotEmpty) {
      selection.add("%$parsedString%");
    }
    //print("addParsedSearchString::parsedString: $parsedString");
    return selection;
  }

  String getOrderBy(String sortString, List<String> sortOrder) {
    String songOrderType = SettingsProvider().songOrderType;
    String albumOrderType = SettingsProvider().albumOrderType;
    String yearOrderType = SettingsProvider().yearOrderType;

    String orderBy = "";

    if (sortString == columnArtist) {
      orderBy = getOrderByWithIgnore("A.$columnArtist");
    } else if (sortString == columnAlbum) {
      if (albumOrderType == orderAlphabetically) {
        orderBy = getOrderByWithIgnore("S.$columnAlbum");
      } else if (albumOrderType == orderChronolically) {
        orderBy = "S.$columnYear";
      } else if (albumOrderType == orderReverseChronolically) {
        orderBy = "S.$columnYear DESC";
      }
    } else if (sortString == columnGenre) {
      orderBy = getOrderByWithIgnore("G.$columnGenre");
    } else if (sortString == columnYear) {
      if (yearOrderType == orderChronolically) {
        orderBy = "S.$columnYear";
      } else if (yearOrderType == orderReverseChronolically) {
        orderBy = "S.$columnYear DESC";
      }
    } else if (sortString == columnModifiedDate) {
      orderBy = "substr(S.ModifiedDate,7)||\n" +
          "case when substr(S.ModifiedDate,4,3) = 'Jan' then 01\n" +
          "when substr(S.ModifiedDate,4,3) = 'Feb' then '02'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Mar' then '03'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Apr' then '04'\n" +
          "when substr(S.ModifiedDate,4,3) = 'May' then '05'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Jun' then '06'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Jul' then '07'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Aug' then '08'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Sep' then '09'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Oct' then '10'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Nov' then '11'\n" +
          "when substr(S.ModifiedDate,4,3) = 'Dec' then '12'\n" +
          "end||\n" +
          "substr(S.ModifiedDate,1,2)";
    } else if (sortString == tablePlaylists) {
      orderBy = getOrderByWithIgnore("P.$columnName");
    } else if (sortString == tableSongs) {
      if (sortOrder.length > 1) {
        if (songOrderType == orderChronolically) {
          return "S.$columnYear, S.$columnTrackNumber";
        } else if (songOrderType == orderChronolically) {
          return "S.$columnYear DESC";
        }
      }
      orderBy = getOrderByWithIgnore("S.$columnTitle");
    }

    return orderBy;
  }

  String getOrderByWithIgnore(String column) {
    bool ignoreThe = SettingsProvider().ignoreThe;
    bool ignoreA = SettingsProvider().ignoreA;

    String orderBy = "";

    if (ignoreThe && ignoreA) {
      orderBy = "CASE WHEN $column LIKE 'The %' THEN SUBSTR($column, 5)\n" +
          "WHEN $column LIKE 'A %' THEN SUBSTR($column, 3)\n" +
          "ELSE $column end COLLATE NOCASE";
    } else if (ignoreThe) {
      orderBy = "CASE WHEN $column LIKE 'The %' THEN SUBSTR($column, 5)\n" +
          "ELSE $column end COLLATE NOCASE";
    } else if (ignoreA) {
      orderBy = "CASE WHEN $column LIKE 'A %' THEN SUBSTR($column, 3)\n" +
          "ELSE $column end COLLATE NOCASE";
    } else {
      orderBy = "$column COLLATE NOCASE";
    }

    return orderBy;
  }
}

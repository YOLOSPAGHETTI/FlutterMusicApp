import 'package:intl/intl.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/music_parser.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:music_app/models/song.dart';

class MusicBuilder {
  MusicProvider musicProvider;
  DatabaseHelper db = DatabaseHelper();
  List<String> artistDelimiters = SettingsProvider().artistDelimiters;
  List<String> genreDelimiters = SettingsProvider().genreDelimiters;
  Map<String, List<String>> songIgnoreText = SettingsProvider().songIgnoreText;
  Map<String, List<String>> artistIgnoreText =
      SettingsProvider().artistIgnoreText;
  bool parseArtists = false;

  Map<int, Song> allSongs = {};
  Map<String, int> allArtists = {};
  Map<String, int> allGenres = {};
  Map<String, Map<String, int>> allAlbums = {};

  List<Map<String, dynamic>> bulkInsertSongs = [];
  List<Map<String, dynamic>> bulkInsertArtists = [];
  List<Map<String, dynamic>> bulkInsertSongArtists = [];
  List<Map<String, dynamic>> bulkInsertGenres = [];
  List<Map<String, dynamic>> bulkInsertSongGenres = [];

  double progress = 0;

  Function(double)? onProgressUpdate;

  MusicBuilder(this.musicProvider);

  void setProgressFunction(Function(double) onProgressUpdate) {
    this.onProgressUpdate = onProgressUpdate;
  }

  Future<void> rebuildDb() async {
    print("Attempting rebuild");
    await db.rebuildDb();
  }

  Future<void> populateDatabase(List<Song> songs) async {
    parseArtists = artistDelimiters.isNotEmpty ||
        songIgnoreText.isNotEmpty ||
        artistIgnoreText.isNotEmpty;

    buildSongsBulk(songs);
    print("populateDatabase:: Finished populating db");
    musicProvider.addSongs(allSongs);
  }

  Future<void> buildSongsBulk(List<Song> songs) async {
    int totalSongs = songs.length;
    int currentSong = 0;
    int bulkSize = 0;
    int songId = await db.getNextId(tableSongs);
    int artistId = await db.getNextId(tableArtists);
    int genreId = await db.getNextId(tableGenres);

    for (Song song in songs) {
      String title = song.title;
      String artist = song.artist;
      String genre = song.genre;
      print("buildSongsBulk::artistId: $artistId");

      if (song.title.isNotEmpty) {
        allSongs[songId] = song;
        Map<String, dynamic> songValues = songToRow(songId, song);
        bulkInsertSongs.add(songValues);
        songId++;

        MusicParser parser =
            MusicParser(artistText: artist, songText: title, genreText: genre);

        if (parseArtists) {
          List<String> artists = parser.getArtists(
              artistDelimiters, songIgnoreText, artistIgnoreText);
          for (String parsedArtist in artists) {
            bool exists = buildArtistBulk(songId, artistId, parsedArtist);
            if (!exists) {
              artistId++;
            }
          }
        } else {
          bool exists = buildArtistBulk(songId, artistId, artist);
          if (!exists) {
            artistId++;
          }
        }

        if (genreDelimiters.isNotEmpty) {
          List<String> genres = parser.getGenres(genreDelimiters);
          for (String parsedGenre in genres) {
            bool exists = buildGenreBulk(songId, genreId, parsedGenre);
            if (!exists) {
              genreId++;
            }
          }
        } else {
          bool exists = buildGenreBulk(songId, genreId, genre);
          if (!exists) {
            genreId++;
          }
        }

        //insertAlbum(album, song.albumArtist, song.trackNumber, song.duration);
        //print("Populated song: " + title);
        //print("Populated artist: " + artist);

        bulkSize++;
        print("buildSongsBulk:: bulkSize: $bulkSize");
        print("buildSongsBulk:: bulkInsertSongs: $bulkInsertSongs");
        if (bulkSize >= bulkInsertSize) {
          bulkSize = 0;
          await bulkInsert();
        }
      }
      currentSong++;
      progress = currentSong / totalSongs;
      if (onProgressUpdate != null) {
        onProgressUpdate!(progress);
      }
    }
  }

  Future<void> updateSong(int id, Song song) async {
    // Finish editing all associated tables
    String query =
        "UPDATE $tableSongs SET $columnTitle = ?, $columnArtist = ?, $columnAlbum = ?, $columnYear = ? WHERE $columnId = ?";
    await db.customQuery(
        query, [song.title, song.artist, song.album, song.year, id.toString()]);
  }

  Future<String> getSongIdFromSource(String source) async {
    String songId = await db.easyShortQuery(
        tableSongs, columnId, "$columnSource = ?", source);

    return songId;
  }

  bool buildArtistBulk(int songId, int artistId, String artist) {
    bool exists = false;
    if (allArtists.containsKey(artist)) {
      artistId = allArtists[artist]!;
      exists = true;
    } else {
      Map<String, dynamic> artistValues = {};
      artistValues[columnId] = artistId;
      artistValues[columnArtist] = artist;
      bulkInsertArtists.add(artistValues);
      allArtists[artist] = artistId;
    }
    Map<String, dynamic> songArtistValues = {};
    songArtistValues[columnSongId] = songId;
    songArtistValues[columnArtistId] = artistId;
    bulkInsertSongArtists.add(songArtistValues);

    return exists;
  }

  bool buildGenreBulk(int songId, int genreId, String genre) {
    bool exists = false;
    if (allGenres.containsKey(genre)) {
      genreId = allGenres[genre]!;
      exists = true;
    } else {
      Map<String, dynamic> genreValues = {};
      genreValues[columnId] = genreId;
      genreValues[columnGenre] = genre;
      bulkInsertGenres.add(genreValues);
      allGenres[genre] = genreId;
    }
    Map<String, dynamic> songGenreValues = {};
    songGenreValues[columnSongId] = songId;
    songGenreValues[columnGenreId] = genreId;
    bulkInsertSongGenres.add(songGenreValues);

    return exists;
  }

  // Inserts an album into the database
  /*void insertAlbum(String album, String songAlbumArtist, int trackNumber,
      int duration) async {
    int albumId;
    if (albums.containsKey(album) &&
        albums[album]!.containsKey(songAlbumArtist)) {
      albumId = albums[album]![songAlbumArtist]!;

      String oldDuration = await db.easyShortQuery(
          tableAlbums, columnDuration, "$columnId = ?", albumId.toString());
      int newDuration = -1;
      if (oldDuration.isNotEmpty) {
        newDuration = int.parse(oldDuration) + duration;
      }

      // New value for one column
      Map<String, int> values = {};
      if (newDuration != -1) {
        values[columnDuration] = newDuration;
      } else {
        values[columnDuration] = 0;
      }

      // Which row to update, based on the title
      db.update(tableAlbums, albumId, values);
    } else {
      Map<String, dynamic> albumValues = {};
      albumValues[columnAlbum] = album;
      albumValues[columnAlbumArtist] = songAlbumArtist;
      albumValues[columnTotalTrackCount] = trackNumber;
      albumValues[columnDuration] = duration;

      albumId = await db.insert(tableAlbums, albumValues);
      Map<String, int> albumArtistId = {};
      albumArtistId[songAlbumArtist] = albumId;
      albums[album] = albumArtistId;
    }
  }*/

  Map<String, dynamic> songToRow(int songId, Song song) {
    String formattedDate = DateFormat('dd-MMM-yyyy').format(song.modifiedDate);

    Map<String, dynamic> songValues = {};
    songValues[columnId] = songId;
    songValues[columnTitle] = song.title;
    songValues[columnAlbum] = song.album;
    songValues[columnArtist] = song.artist;
    songValues[columnAlbumArtist] = song.albumArtist;
    songValues[columnGenre] = song.genre;
    songValues[columnYear] = song.year;
    songValues[columnSource] = song.source;
    songValues[columnTrackNumber] = song.trackNumber;
    songValues[columnTotalTrackCount] = song.totalTrackCount;
    songValues[columnDuration] = song.duration;
    songValues[columnModifiedDate] = formattedDate;

    return songValues;
  }

  // Inserts a song into the database
  /*Future<int> insertSong(Song song) async {
    Map<String, dynamic> songValues = songToRow(song);

    return await db.insert(tableSongs, songValues);
  }*/

  // Inserts a song into the database
  Future<void> insertSongWithId(Song song, int songId) async {
    String formattedDate = DateFormat('dd-MMM-yyyy').format(song.modifiedDate);

    Map<String, dynamic> songValues = {};
    songValues[columnId] = songId;
    songValues[columnTitle] = song.title;
    songValues[columnAlbum] = song.album;
    songValues[columnArtist] = song.artist;
    songValues[columnAlbumArtist] = song.albumArtist;
    songValues[columnGenre] = song.genre;
    songValues[columnYear] = song.year;
    songValues[columnSource] = song.source;
    songValues[columnTrackNumber] = song.trackNumber;
    songValues[columnTotalTrackCount] = song.totalTrackCount;
    songValues[columnDuration] = song.duration;
    songValues[columnModifiedDate] = formattedDate;

    await db.insert(tableSongs, songValues);
  }

  Future<void> bulkInsert() async {
    if (bulkInsertSongs.isNotEmpty) {
      await db.bulkInsertNoResult(tableSongs, bulkInsertSongs);
      bulkInsertSongs.clear();
    }
    if (bulkInsertArtists.isNotEmpty) {
      await db.bulkInsertNoResult(tableArtists, bulkInsertArtists);
      bulkInsertArtists.clear();
    }
    if (bulkInsertSongArtists.isNotEmpty) {
      await db.bulkInsertNoResult(tableSongArtists, bulkInsertSongArtists);
      bulkInsertSongArtists.clear();
    }
    if (bulkInsertGenres.isNotEmpty) {
      await db.bulkInsertNoResult(tableGenres, bulkInsertGenres);
      bulkInsertGenres.clear();
    }
    if (bulkInsertSongGenres.isNotEmpty) {
      await db.bulkInsertNoResult(tableSongGenres, bulkInsertSongGenres);
      bulkInsertSongGenres.clear();
    }
  }
}

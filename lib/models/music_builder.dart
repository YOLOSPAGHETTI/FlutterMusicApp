import 'package:intl/intl.dart';
import 'package:music_app/constants.dart';
import 'package:music_app/models/database_helper.dart';
import 'package:music_app/models/music_parser.dart';
import 'package:music_app/models/song.dart';

class MusicBuilder {
  DatabaseHelper db = DatabaseHelper();
  List<String> artistDelimiters = <String>[];
  List<String> genreDelimiters = <String>[];
  List<String> songContainers = <String>[];
  List<String> artistContainers = <String>[];
  Map<String, List<String>> songIgnoreText = {};
  Map<String, List<String>> artistIgnoreText = {};

  Map<String, int> artists = {};
  Map<String, int> genres = {};
  Map<String, Map<String, int>> albums = {};

  double progress = 0;

  final Function(double) onProgressUpdate;

  MusicBuilder(this.onProgressUpdate);

  Future<void> rebuildDb() async {
    print("Attempting rebuild");
    await db.rebuildDb();
  }

  void populateConfigurationSettings(
      List<String> artistDelimiters,
      List<String> genreDelimiters,
      List<String> songContainers,
      List<String> artistContainers,
      Map<String, List<String>> songIgnoreText,
      Map<String, List<String>> artistIgnoreText) {
    this.artistDelimiters = artistDelimiters;
    this.genreDelimiters = genreDelimiters;
    this.songContainers = songContainers;
    this.artistContainers = artistContainers;
    this.songIgnoreText = songIgnoreText;
    this.artistIgnoreText = artistIgnoreText;

    for (String delimiter in artistDelimiters) {
      Map<String, String> data = {};
      data[columnField] = columnArtist;
      data[columnDelimiter] = delimiter;
      db.insert(tableSeparateFieldSettings, data);
    }

    for (String delimiter in genreDelimiters) {
      Map<String, String> data = {};
      data[columnField] = columnGenre;
      data[columnDelimiter] = delimiter;
      db.insert(tableSeparateFieldSettings, data);
    }

    for (String container in songContainers) {
      List<String> ignoreTextList = songIgnoreText[container]!;
      for (String ignoreText in ignoreTextList) {
        Map<String, String> data = {};
        data[columnField] = columnTitle;
        data[columnContainer] = container;
        data[columnIgnoreText] = ignoreText;
        db.insert(tableFieldContainerSettings, data);
      }
    }

    for (String container in artistContainers) {
      List<String> ignoreTextList = artistIgnoreText[container]!;
      for (String ignoreText in ignoreTextList) {
        Map<String, String> data = {};
        data[columnField] = columnArtist;
        data[columnContainer] = container;
        data[columnIgnoreText] = ignoreText;
        db.insert(tableFieldContainerSettings, data);
      }
    }
  }

  Future<void> populateDatabase(List<Song> songs) async {
    bool parseArtists = artistDelimiters.isNotEmpty ||
        songContainers.isNotEmpty ||
        artistContainers.isNotEmpty;
    int totalSongs = songs.length;
    int currentSong = 0;

    for (Song song in songs) {
      String title = song.title;
      String album = song.album;
      String artist = song.artist;
      String albumArtist = song.albumArtist;
      String genre = song.genre;
      String year = song.year;
      String source = song.source;

      int trackNumber = song.trackNumber;
      int duration = song.duration;
      int totalTrackCount = song.totalTrackCount;
      DateTime modifiedDate = song.modifiedDate;

      if (title.isNotEmpty) {
        bool newSource = await getNewSource(source);

        if (newSource) {
          int songId = await insertSong(
              source,
              artist,
              album,
              albumArtist,
              genre,
              title,
              modifiedDate,
              duration,
              year,
              trackNumber,
              totalTrackCount);

          MusicParser parser = MusicParser(
              artistText: artist, songText: title, genreText: genre);

          if (parseArtists) {
            List<String> artists = parser.getArtists(
                artistDelimiters,
                songContainers,
                songIgnoreText,
                artistContainers,
                artistIgnoreText);
            for (String parsedArtist in artists) {
              insertArtist(parsedArtist, songId);
            }
          } else {
            insertArtist(artist, songId);
          }

          if (genreDelimiters.isNotEmpty) {
            List<String> genres = parser.getGenres(genreDelimiters);
            for (String parsedGenre in genres) {
              insertGenre(parsedGenre, songId);
            }
          } else {
            insertGenre(genre, songId);
          }

          insertAlbum(album, albumArtist, trackNumber, duration);
        }
        //print("Populated song: " + title);
        //print("Populated artist: " + artist);
      }
      currentSong++;
      progress = currentSong / totalSongs;
      onProgressUpdate(progress);
    }
    print("Finished populating db");
  }

  Future<bool> getNewSource(String source) async {
    bool newSource = true;
    String song = await db.easyShortQuery(
        tableSongs, columnId, "$columnSource = ?", source);
    if (song.isNotEmpty) {
      newSource = false;
    }

    return newSource;
  }

  // Inserts an artist into the database
  void insertArtist(String artist, int songId) async {
    int artistId;
    if (!artists.containsKey(artist)) {
      //print("artist: " + artist);
      Map<String, String> artistValues = {};
      artistValues[columnArtist] = artist;
      artistId = await db.insert(tableArtists, artistValues);
      //print("artistId: " + artistId.toString());
      artists[artist] = artistId;
    } else {
      artistId = artists[artist]!;
    }
    Map<String, int> songArtistValues = {};
    songArtistValues[columnSongId] = songId;
    songArtistValues[columnArtistId] = artistId;

    db.insert(tableSongArtists, songArtistValues);
  }

  // Inserts an album into the database
  void insertAlbum(String album, String songAlbumArtist, int trackNumber,
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
  }

  // Inserts a song into the database
  Future<int> insertSong(
      String source,
      String artist,
      String album,
      String albumArtist,
      String genre,
      String title,
      DateTime modifiedDate,
      int duration,
      String year,
      int trackNumber,
      int totalTrackCount) async {
    String formattedDate = DateFormat('dd-MMM-yyyy').format(modifiedDate);

    Map<String, dynamic> songValues = {};
    songValues[columnTitle] = title;
    songValues[columnAlbum] = album;
    songValues[columnArtist] = artist;
    songValues[columnAlbumArtist] = albumArtist;
    songValues[columnGenre] = genre;
    songValues[columnYear] = year;
    songValues[columnSource] = source;
    songValues[columnTrackNumber] = trackNumber;
    songValues[columnTotalTrackCount] = totalTrackCount;
    songValues[columnDuration] = duration;
    songValues[columnModifiedDate] = formattedDate;

    return await db.insert(tableSongs, songValues);
  }

  // Inserts a genre into the database
  void insertGenre(String genre, int songId) async {
    int genreId;
    if (!genres.containsKey(genre)) {
      Map<String, String> genreValues = {};
      genreValues[columnGenre] = genre;

      genreId = await db.insert(tableGenres, genreValues);
      genres[genre] = genreId;
    } else {
      genreId = genres[genre]!;
    }
    Map<String, int> songGenreValues = {};
    songGenreValues[columnSongId] = songId;
    songGenreValues[columnGenreId] = genreId;

    db.insert(tableSongGenres, songGenreValues);
    //print("genre: $genre");
  }
}

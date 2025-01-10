import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:music_app/models/song.dart';

class FileHelper {
  int currentFile = 0;
  double progress = 0;

  final Function(double) onProgressUpdate;

  FileHelper(this.onProgressUpdate);

  Future<List<File>> getMusicFiles() async {
    final List<File> musicFiles = <File>[];
    final rootDir = Directory('/storage/emulated/0/');
    await _searchFiles(rootDir, musicFiles);
    progress = 0;
    print("Done searching files");
    return musicFiles;
  }

  Future<List<Song>> getSongsFromFiles(List<File> musicFiles) async {
    List<Song> songs = <Song>[];
    int totalFiles = musicFiles.length;
    currentFile = 0;
    progress = 0;
    for (File file in musicFiles) {
      songs.add(await fileToSong(file));
      currentFile++;
      progress = currentFile / totalFiles;
      onProgressUpdate(progress);
    }
    print("Done converting songs");
    return songs;
  }

  Future<Song> fileToSong(File file) async {
    Song song = Song(
        id: 0,
        title: "",
        artist: "",
        album: "",
        albumArtist: "",
        genre: "",
        year: "",
        trackNumber: -1,
        totalTrackCount: -1,
        duration: -1,
        modifiedDate: await file.lastModified(),
        albumArt: Uint8List(0),
        source: file.path,
        favorite: false);
    try {
      Tag? tag = await AudioTags.read(file.path);

      String undefinedTag = "<UNDEFINED>";

      String? title = tag?.title ?? undefinedTag;
      String? artist = tag?.trackArtist ?? undefinedTag;
      String? album = tag?.album ?? undefinedTag;
      String? albumArtist = tag?.albumArtist ?? undefinedTag;
      String? genre = tag?.genre ?? undefinedTag;
      String? year = tag?.year == null ? undefinedTag : tag?.year.toString();
      int? trackNumber = tag?.trackNumber ?? -1;
      int? totalTrackCount = tag?.trackTotal ?? -1;
      int? duration = tag?.duration;

      song = Song(
          id: 0,
          title: title,
          artist: artist,
          album: album,
          albumArtist: albumArtist,
          genre: genre,
          year: year!,
          trackNumber: trackNumber,
          totalTrackCount: totalTrackCount,
          duration: duration!,
          modifiedDate: await file.lastModified(),
          albumArt: Uint8List(0),
          source: file.path,
          favorite: false);
    } catch (e) {
      print(e.toString());
    }

    return song;
  }

  Future<void> _searchFiles(Directory dir, List<File> musicFiles) async {
    try {
      final entities = dir.listSync(recursive: false, followLinks: false);
      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          if (_isMusicFile(entity)) {
            //print(entity.path);
            musicFiles.add(entity);
          }
          currentFile++;
          progress = (currentFile / 100000).clamp(0, 1);
          onProgressUpdate(progress);
        } else if (entity is Directory) {
          await _searchFiles(entity, musicFiles); // Recursive search
        }
      }
    } catch (e) {
      print('Error searching files: $e');
    }
  }

  bool _isMusicFile(File file) {
    const List<String> validExtensions = [
      '.3gp',
      '.mp4',
      '.m4a',
      '.aac',
      '.ts',
      '.flac',
      '.xmf',
      '.mxmf',
      '.rtt1',
      '.rtx',
      '.ota',
      '.imy',
      '.mp3',
      '.mkv',
      '.wav',
      '.ogg'
    ];
    return validExtensions.any((ext) => file.path.endsWith(ext));
  }
}

import 'dart:typed_data';

class Song {
  int id;
  String title;
  String artist;
  String album;
  String albumArtist;
  String genre;
  String year;
  int trackNumber;
  int totalTrackCount;
  int duration;
  DateTime modifiedDate;
  final String source;

  Uint8List albumArt;
  bool favorite;

  Song(
      {required this.id,
      required this.title,
      required this.artist,
      required this.album,
      required this.albumArtist,
      required this.genre,
      required this.year,
      required this.trackNumber,
      required this.totalTrackCount,
      required this.duration,
      required this.modifiedDate,
      required this.albumArt,
      required this.source,
      required this.favorite});
}

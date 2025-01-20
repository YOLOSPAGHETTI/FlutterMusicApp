import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:path_provider/path_provider.dart';

Future<AudioHandler> initAudioService(MusicProvider musicProvider) async {
  return await AudioService.init(
    builder: () => AudioHandler(musicProvider),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AudioHandler extends BaseAudioHandler {
  late MusicProvider musicProvider;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ConcatenatingAudioSource _playlist =
      ConcatenatingAudioSource(useLazyPreparation: true, children: []);
  int playlistLimit = 100;

  AudioHandler(this.musicProvider) {
    _loadEmptyPlaylist();
    listenToDuration();
    notifyAudioHandlerAboutPlaybackEvents();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _audioPlayer.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  void notifyAudioHandlerAboutPlaybackEvents() {
    _audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final bool isPlaying = _audioPlayer.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        playing: isPlaying,
        updatePosition: _audioPlayer.position,
        processingState: _mapProcessingState(_audioPlayer.processingState),
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
      ));
    });
  }

  void listenToDuration() {
    _audioPlayer.durationStream.listen((newDuration) {
      musicProvider.totalDuration =
          newDuration == null ? Duration.zero : newDuration!;
      if (musicProvider.currentQueueIndex != -1) {
        setMediaItemToCurrentSong();
      }
    });

    _audioPlayer.positionStream.listen((newPosition) {
      musicProvider.currentDuration = newPosition;
    });

    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      playbackState.add(playbackState.value.copyWith(
        bufferedPosition: bufferedPosition,
      ));
    });

    _audioPlayer.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        processingState: _mapProcessingState(_audioPlayer.processingState),
      ));
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.buffering;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void setMediaItemToCurrentSong() async {
    Song song = musicProvider.getCurrentSong();
    setMediaItem(song);
  }

  void setMediaItem(Song song) async {
    //print("setMediaItem::songTitle: " + song.title);
    MediaItem media = await getMediaItemFromSong(song);

    mediaItem.add(media);
  }

  Future<MediaItem> getMediaItemFromSong(Song song) async {
    String songId = song.id.toString();
    String fileName = "$songId _albumArt.jpg";
    Uri fileUri = await saveUint8ListToTempFile(song.albumArt, fileName);

    return MediaItem(
      id: songId,
      title: song.title,
      album: song.album,
      artist: song.artist,
      artUri: fileUri, // URL or local file path
      duration: musicProvider.totalDuration,
    );
  }

  Future<Uri> saveUint8ListToTempFile(Uint8List data, String fileName) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(data);
    return Uri.file(file.path);
  }

  bool playerIsReady() {
    if (_audioPlayer.processingState == ProcessingState.idle ||
        _audioPlayer.processingState == ProcessingState.ready) {
      return true;
    }
    return false;
  }

  void updateSongAndPlay() async {
    int currentQueueIndex = musicProvider.currentQueueIndex;

    musicProvider.isPlaying = true;

    if (currentQueueIndex != -1) {
      setMediaItemToCurrentSong();
      await play();
    }
  }

  @override
  Future<void> play() async {
    musicProvider.isPlaying = true;
    await _audioPlayer.play();
  }

  @override
  Future<void> stop() async {
    musicProvider.isPlaying = false;
    await _audioPlayer.pause();
  }

  @override
  Future<void> pause() async {
    musicProvider.isPlaying = false;
    await _audioPlayer.pause();
  }

  void resume() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    skipToPrevious();
  }

  @override
  Future<void> skipToNext() async {
    musicProvider.playNextSong();
  }

  @override
  Future<void> skipToPrevious() async {
    musicProvider.playPreviousSong();
  }

  void seekToNext() async {
    int currentQueueIndex = musicProvider.currentQueueIndex;

    if (currentQueueIndex != -1) {
      setMediaItemToCurrentSong();
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      } else {
        addToPlaylistFromQueue();
      }
    }
  }

  void seekToPrevious() async {
    int currentQueueIndex = musicProvider.currentQueueIndex;

    if (currentQueueIndex != -1) {
      setMediaItemToCurrentSong();
      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      } else {
        addToPlaylistFromQueue();
      }
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        musicProvider.repeat = 0;
        break;
      case AudioServiceRepeatMode.one:
        musicProvider.repeat = 2;
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        musicProvider.repeat = 1;
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    musicProvider.toggleShuffle();
  }

  // Playlist queue
  void shufflePlaylist(List<int> queue, int currentQueueIndex) {
    int currentSongIndex =
        _audioPlayer.currentIndex == null ? 0 : _audioPlayer.currentIndex!;
    if (_playlist.length > currentSongIndex) {
      _playlist.removeRange(currentSongIndex + 1, _playlist.length);
    }
    addToPlaylist(queue.sublist(currentQueueIndex + 1));
  }

  void addToPlaylist(List<int> songIds) {
    for (int songId in songIds) {
      if (_playlist.length >= playlistLimit) {
        break;
      }
      Song song = musicProvider.getSongFromId(songId);
      print("addToPlaylist::songTitle: " + song.title);
      _playlist.add(AudioSource.uri(Uri.file(song.source)));
    }
  }

  void addToPlaylistAtIndex(List<int> songIds, int index) {
    for (int songId in songIds) {
      if (_playlist.length >= playlistLimit) {
        break;
      }
      Song song = musicProvider.getSongFromId(songId);
      _playlist.add(AudioSource.uri(Uri.file(song.source)));
    }
  }

  void addToPlaylistFromQueue() async {
    int currentQueueIndex = musicProvider.currentQueueIndex;
    List<int> queue = musicProvider.queue;

    await restartPlaylist();
    clearPlaylist();
    if (currentQueueIndex != -1) {
      int increment = (playlistLimit / 2).toInt();
      int startIndex =
          currentQueueIndex - increment < 0 ? 0 : currentQueueIndex - increment;
      int endIndex = currentQueueIndex + increment >= queue.length
          ? queue.length - 1
          : currentQueueIndex + increment;
      List<int> songIds = queue.sublist(startIndex, endIndex);
      addToPlaylist(songIds);
      int playerIndex =
          increment >= _playlist.length ? _playlist.length : increment;
      print("addToPlaylistFromQueue::playerIndex: $playerIndex");
      await _audioPlayer.seek(Duration.zero, index: playerIndex);
      setMediaItemToCurrentSong();
      if (musicProvider.isPlaying) {
        await play();
      } else {
        musicProvider.isPlaying = false;
      }
    }
  }

  Future<void> restartPlaylist() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero, index: 0);
  }

  void clearPlaylist() {
    if (_playlist.length > 0) {
      _playlist.clear();
    }
  }
}

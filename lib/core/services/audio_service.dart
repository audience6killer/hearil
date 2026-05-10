import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  // The underscore makes this variable private to this file
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Exposing Streams (Event-driven data over time)
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<void> get trackCompletitionStream => _player.playerStateStream
      .where((state) => state.processingState == ProcessingState.completed)
      .map((_) => null);
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android +13 usus Permission.audio, older versions use Permission.storage
      // We requeset both; the OS safely ignores one that doesn't apply
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
      ].request();

      return statuses[Permission.audio]!.isGranted ||
          statuses[Permission.storage]!.isGranted;
    }
    return true;
  }

  Future<List<SongModel>> fetchLocalSongs() async {
    return await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<AlbumModel>> fetchAlbums() async {
    return await _audioQuery.queryAlbums(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<ArtistModel>> fetchArtists() async {
    return await _audioQuery.queryArtists(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  // Loads an audio file form a remote URL or local path
  // Features in Dart are exactly like Promises in Javascript
  Future<void> loadPlaylist(List<SongModel> playlist, int startIndex) async {
    try {
      // Map your entire array of MP3s into tagged OS-level MediaItems
      final audioSources = playlist.map((song) {
        return AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: song.id.toString(),
            album: song.album ?? "Unknown Album",
            title: song.title,
            artist: song.artist ?? "Unknown Artist",
            artUri: Uri.parse("content://media/external/audio/media/${song.id}/albumart"),
          ),
        );
      }).toList();

      // Bundle them together into a native queue
      final concatenatingAudioSource = ConcatenatingAudioSource(children: audioSources);

      // Load the entire queue into the hardware buffer at once
      await _player.setAudioSource(
        concatenatingAudioSource,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );
    } catch (e) {
      print("Error loading playlist: $e");
    }
  }

  // 3. EXPOSE NATIVE SKIP COMMANDS
  Future<void> skipToNext() async => await _player.seekToNext();
  Future<void> skipToPrevious() async => await _player.seekToPrevious();
  Future<void> skipToQueueItem(int index) async => await _player.seek(Duration.zero, index: index);

  // Core playback controls
  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}

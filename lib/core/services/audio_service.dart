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

  Future<bool> requestPermissions() async {
    if(Platform.isAndroid) {
      // Android +13 usus Permission.audio, older versions use Permission.storage
      // We requeset both; the OS safely ignores one that doesn't apply
      Map<Permission, PermissionStatus> statuses = await[
        Permission.storage,
        Permission.audio,
      ].request();

      return statuses[Permission.audio]!.isGranted || statuses[Permission.storage]!.isGranted;
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

  // Loads an audio file form a remote URL or local path
  // Features in Dart are exactly like Promises in Javascript
  Future<Duration?> loadAudio(String url) async {
    try {
      final source = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: '0',
          album: 'Hearil Demo',
          title: 'Test track',
          artist: 'SoundHelix',
        ),
      );
      return await _player.setAudioSource(source);
    } catch(e) {
      print("Error loading audio: $e");
      return null;
    }
  }

  // Core playback controls
  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.dispose();
  }

}


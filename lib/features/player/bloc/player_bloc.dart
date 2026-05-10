import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/services/audio_service.dart';
import 'player_event.dart';
import 'player_states.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  // Dependency injection: We pass the service in so the BLoC doesn't instantiate it
  // directly
  final AudioService _audioService;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  StreamSubscription? _trackCompletitionSubscription;
  StreamSubscription? _currentIndexSubscription; // NEW

  PlayerBloc(this._audioService) : super(PlayerInitial()) {
    // Register event handlers
    on<LoadAudioEvent>(_onLoadAudio);
    on<PlayAudioEvent>(_onPlayAudio);
    on<PauseAudioEvent>(_onPauseAudio);
    on<AudioStateChangedEvent>(_onAudioStateChanged);
    on<AudioPositionChangedEvent>(_onPositionChanged);
    on<AudioDurationChangedEvent>(_onDurationChanged);
    on<SeekAudioEvent>(_onSeekAudio);
    on<InitializePlayerEvent>(_onInitialize);
    on<TrackIndexChangedEvent>(_onTrackIndexChanged);

    on<SkipNextEvent>(_onSkipNext);
    on<SkipPreviousEvent>(_onSkipPrevious);

    // This listens continously to the native audio driver's state
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      // state.playing is a boolean provided by just_audio
      add(AudioStateChangedEvent(state.playing));
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      add(AudioPositionChangedEvent(position));
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (duration != null) {
        add(AudioDurationChangedEvent(duration));
      }
    });

    _trackCompletitionSubscription = _audioService.trackCompletitionStream
        .listen((_) {
          add(SkipNextEvent());
        });

    // 1. LISTEN TO OS NATIVE TRACK CHANGES
    _currentIndexSubscription = _audioService.currentIndexStream.listen((
      index,
    ) {
      if (index != null) add(TrackIndexChangedEvent(index));
    });
  }

  Future<void> _onInitialize(InitializePlayerEvent event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading());
    try {
      final hasPermission = await _audioService.requestPermissions();
      if (!hasPermission) return;

      // 1. Fetch all datasets concurrently using Future.wait for maximum speed
      final results = await Future.wait([
        _audioService.fetchLocalSongs(),
        _audioService.fetchAlbums(),
        _audioService.fetchArtists(),
      ]);

      final songs = results[0] as List<SongModel>;
      final albums = results[1] as List<AlbumModel>;
      final artists = results[2] as List<ArtistModel>;

      if (songs.isEmpty) {
        emit(const PlayerError(message: "No audio files found."));
        return;
      }

      // 2. Silently load the playlist into the hardware engine
      await _audioService.loadPlaylist(songs, 0);
      final firstTrack = songs[0];

      // 3. Emit the fully cached UI state
      emit(PlayerReady(
        isPlaying: false, // Prevents auto-playing on boot
        title: firstTrack.title,
        artist: firstTrack.artist ?? "Unknown Artist",
        songId: firstTrack.id,
        playlist: songs,
        albums: albums,    // NEW
        artists: artists,  // NEW
      ));
    } catch (e) {
      emit(PlayerError(message: "Init failed: $e"));
    }
  }

  Future<void> _onLoadAudio(
    LoadAudioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is PlayerReady) {
      final currentState = state as PlayerReady;
      final index = currentState.playlist.indexWhere(
        (song) => song.id == event.song.id,
      );

      if (index != -1) {
        await _audioService.skipToQueueItem(index);
        _audioService.play();
      }
    }
  }

  // 1. Remove the direct emits. Let the hardware interrupt handle UI updates.
  Future<void> _onPlayAudio(
    PlayAudioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _audioService.play();
  }

  Future<void> _onPauseAudio(
    PauseAudioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _audioService.pause();
    // Removed the await here as well so it doesn't block
  }

  Future<void> _onSeekAudio(
    SeekAudioEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.seek(event.position);
  }

  Future<void> _onSkipNext(
    SkipNextEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.skipToNext();
  }

  Future<void> _onSkipPrevious(
    SkipPreviousEvent event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.skipToPrevious();
  }

  // 2. Use copyWith to act as a bitmask, preserving position and duration.
  void _onAudioStateChanged(
    AudioStateChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerReady) {
      emit((state as PlayerReady).copyWith(isPlaying: event.isPlaying));
    }
  }

  void _onPositionChanged(
    AudioPositionChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerReady) {
      emit((state as PlayerReady).copyWith(position: event.position));
    }
  }

  void _onDurationChanged(
    AudioDurationChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerReady) {
      emit((state as PlayerReady).copyWith(duration: event.duration));
    }
  }

  void _onTrackIndexChanged(
    TrackIndexChangedEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerReady) {
      final currentState = state as PlayerReady;
      if (currentState.playlist.isEmpty) return;

      // Failsafe in case index is out of bounds
      if (event.index < 0 || event.index >= currentState.playlist.length)
        return;

      final newSong = currentState.playlist[event.index];

      // Update the UI with the new track info.
      // (The durationStream will automatically fire and update the duration separately!)
      emit(
        currentState.copyWith(
          title: newSong.title,
          artist: newSong.artist ?? "Unknown Artist",
          songId: newSong.id,
          position: Duration.zero,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _trackCompletitionSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    return super.close();
  }
}

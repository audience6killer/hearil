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
      if(duration != null) {
        add(AudioDurationChangedEvent(duration));
      } 
    });
  }

  Future<void> _onInitialize(InitializePlayerEvent event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading());

    try {
     // Request OS permissions
     final hasPermission = await _audioService.requestPermissions();
     if(!hasPermission) {
      emit(const PlayerError(message: "Storage permission denied by user"));
      return;
     }

     final songs = await _audioService.fetchLocalSongs();
     if(songs.isEmpty) {
      emit(const PlayerError(message: "No audio files found on device."));
      return;
     }

     final firstTrack = songs.first;
     if(firstTrack.uri != null) {
      final duration = await _audioService.loadAudio(firstTrack.uri!);

      emit(PlayerReady(
        isPlaying: false,
        duration: duration ?? Duration.zero,
        title: firstTrack.title,
        artist: firstTrack.artist ?? "Unknown artist",
        songId: firstTrack.id,
        playlist: songs,
      ));
     }
    } catch (e) {
     emit(PlayerError(message: "Failded to initialize: $e")); 
    }
  }

  Future<void> _onLoadAudio(LoadAudioEvent event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading()); // Tell the UI to show a spinner
    try {
     final duration = await _audioService.loadAudio(event.url);

     emit(PlayerReady(
      isPlaying: false,
      duration: duration ?? Duration.zero,
      ));
    } catch (e) {
     emit(PlayerError(message: e.toString()));
    }
  }

  // 1. Remove the direct emits. Let the hardware interrupt handle UI updates.
  Future<void> _onPlayAudio(PlayAudioEvent event, Emitter<PlayerState> emit) async {
    _audioService.play();
  }

  Future<void> _onPauseAudio(PauseAudioEvent event, Emitter<PlayerState> emit) async {
    _audioService.pause();
    // Removed the await here as well so it doesn't block
  }

  Future<void>_onSeekAudio(SeekAudioEvent event, Emitter<PlayerState> emit) async {
    await _audioService.seek(event.position);
  }

  Future<void> _onSkipNext(SkipNextEvent event, Emitter<PlayerState> emit) async {
    if(state is PlayerReady) {
      final currentState = state as PlayerReady;
      if(currentState.playlist.isEmpty) return;

      final currentIndex = currentState.playlist.indexWhere((song) => song.id == currentState.songId);
      if(currentIndex == -1) return;

      // Calculate the next index (using modulo to loop back to 0 if at the end)
      final nextIndex = (currentIndex + 1) % currentState.playlist.length;
      final nextSong = currentState.playlist[nextIndex];

      await _loadAndPlayNewSong(nextSong, currentState, emit);
    }
  }

  Future<void> _onSkipPrevious(SkipPreviousEvent event, Emitter<PlayerState> emit) async {
    if(state is PlayerReady) {
      final currentState = state as PlayerReady;
      if(currentState.playlist.isEmpty) return;

      final currentIndex = currentState.playlist.indexWhere((song) => song.id == currentState.songId);
      if(currentIndex == -1) return;

      // Calculate the next index (using modulo to loop back to 0 if at the end)
      final prevIndex = currentIndex == 0 ? currentState.playlist.length - 1 : currentIndex - 1;
      final prevSong = currentState.playlist[prevIndex];

      await _loadAndPlayNewSong(prevSong, currentState, emit);
    }
  }

  Future<void> _loadAndPlayNewSong(SongModel newSong, PlayerReady currentState, Emitter emit) async
  {
    if(newSong.uri != null) {
      emit(currentState.copyWith(
        title: newSong.title,
        artist: newSong.artist ?? "Unknown Artist",
        songId: newSong.id,
        position: Duration.zero,
      ));

      final duration = await _audioService.loadAudio(newSong.uri!);

      // if the user was already playing music, autoplay the new track
      if(currentState.isPlaying) {
        _audioService.play();
      }

      emit((state as PlayerReady).copyWith(
        duration: duration ?? Duration.zero,
      ));
    }
  }

  // 2. Use copyWith to act as a bitmask, preserving position and duration.
  void _onAudioStateChanged(AudioStateChangedEvent event, Emitter<PlayerState> emit) {
    if(state is PlayerReady) {
      emit((state as PlayerReady).copyWith(isPlaying: event.isPlaying));
    }
  }

  void _onPositionChanged(AudioPositionChangedEvent event, Emitter<PlayerState> emit) {
    if(state is PlayerReady) {
      emit((state as PlayerReady).copyWith(position: event.position));
    }
  }

  void _onDurationChanged(AudioDurationChangedEvent event, Emitter<PlayerState> emit) {
    if(state is PlayerReady) {
      emit((state as PlayerReady).copyWith(duration: event.duration));
    }
  }

   @override
   Future<void> close() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    return super.close();
   }
}

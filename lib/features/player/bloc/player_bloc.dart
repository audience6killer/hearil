import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

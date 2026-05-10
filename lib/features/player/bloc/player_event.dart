import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

// 'sealed' ensures that it we write a switch statement fot the events later
// the Dart compiler will force us to handle every single event
// type exhaustively
sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

class TrackIndexChangedEvent extends PlayerEvent {
  final int index;
  const TrackIndexChangedEvent(this.index);

  @override
  List<Object> get props => [index];
}

class LoadAudioEvent extends PlayerEvent {
  final SongModel song;

  const LoadAudioEvent(this.song);

  @override
  List<Object> get props => [song];
}

class PlayAudioEvent extends PlayerEvent {

}

class PauseAudioEvent extends PlayerEvent {

}

class AudioStateChangedEvent extends PlayerEvent {
  final bool isPlaying;

  const AudioStateChangedEvent(this.isPlaying);

  @override
  List<Object> get props => [isPlaying];
}

class AudioDurationChangedEvent extends PlayerEvent {
  final Duration duration;
  const AudioDurationChangedEvent(this.duration);
  @override
  List<Object> get props => [duration];
}

class AudioPositionChangedEvent extends PlayerEvent {
  final Duration position;
  const AudioPositionChangedEvent(this.position);
  @override
  List<Object> get props => [position];
}

class SeekAudioEvent extends PlayerEvent {
  final Duration position;

  const SeekAudioEvent(this.position);

  @override
  List<Object> get props => [position];
}

class SkipNextEvent extends PlayerEvent {}

class SkipPreviousEvent extends PlayerEvent {}

class InitializePlayerEvent extends PlayerEvent {}


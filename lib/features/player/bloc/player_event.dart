import 'package:equatable/equatable.dart';

// 'sealed' ensures that it we write a switch statement fot the events later
// the Dart compiler will force us to handle every single event
// type exhaustively
sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}


class LoadAudioEvent extends PlayerEvent {
  final String url;

  const LoadAudioEvent(this.url);

  @override
  List<Object> get props => [url];
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

import 'package:equatable/equatable.dart';

sealed class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerReady extends PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const PlayerReady({
    required this.isPlaying, 
    this.position = Duration.zero,
    this.duration = Duration.zero});

  PlayerReady copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerReady(isPlaying: isPlaying ?? this.isPlaying,
    position: position ?? this.position,
    duration: duration ?? this.duration);
  }

   @override
   List<Object> get props => [isPlaying, position, duration];
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError({required this.message});

   @override
   List<Object> get props => [message];
}

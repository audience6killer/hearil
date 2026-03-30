import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

sealed class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerReady extends PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  
  // New Metadata Fields
  final String title;
  final String artist;
  final int? songId; 

  final List<SongModel> playlist;

  const PlayerReady({
    required this.isPlaying, 
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.title = 'Unknown Track',
    this.artist = 'Unknown Artist',
    this.songId,
    this.playlist = const [],
  });

  PlayerReady copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? title,
    String? artist,
    int? songId,
    List<SongModel>? playlist,
  }) {
    return PlayerReady(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      songId: songId ?? this.songId,
      playlist: playlist ?? this.playlist,
    );
  }

   // CRITICAL: Don't forget to add the new fields to the Equatable props!
   @override
   List<Object?> get props => [isPlaying, position, duration, title, artist, songId, playlist];
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError({required this.message});

   @override
   List<Object?> get props => [message];
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_states.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart'; // ADDED: For QueryArtworkWidget

import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_states.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      // 1. HOISTED: BlocBuilder now wraps the entire Stack, including the background
      body: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (previous, current) {
          if(previous is PlayerReady && current is PlayerReady) { 
            return previous.songId != current.songId ||
              previous.isPlaying != current.isPlaying;
          }

          return true;
        },
        builder: (context, state) {
          if (state is PlayerInitial || state is PlayerLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (state is PlayerError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (state is PlayerReady) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 2. DYNAMIC BACKGROUND: Extracts the album art for the blur layer
                _buildBackgroundArt(state),

                // Blur Filter Layer
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),

                // Foreground UI Layer
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(height: 20),

                      // 3. DYNAMIC FOREGROUND ART
                      _buildAlbumArt(state),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            // 4. DYNAMIC TEXT
                            _buildTrackInfo(state),
                            const SizedBox(height: 25),
                            _buildProgressBar(context),
                            const SizedBox(height: 30),
                            _buildPlaybackControls(context, state),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // --- Dynamic UI Components ---

  Widget _buildBackgroundArt(PlayerReady state) {
    // 1. Wrap the output in an AnimatedSwitcher
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600), // Adjust cross-fade speed here
      child: state.songId == null
          ? Container(key: const ValueKey('empty'), color: Colors.grey.shade900)
          : QueryArtworkWidget(
              key: ValueKey(state.songId), 
              id: state.songId!,
              type: ArtworkType.AUDIO,
              // ADD THESE TWO LINES
              size: 1000, 
              artworkQuality: FilterQuality.high,
              // -------------------
              artworkWidth: double.infinity,
              artworkHeight: double.infinity,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(color: Colors.grey.shade900), 
            ),
    );
  }

  Widget _buildAlbumArt(PlayerReady state) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        // 3. Wrap the inner child in the AnimatedSwitcher
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: state.songId != null
              ? QueryArtworkWidget(
                  key: ValueKey(state.songId),
                  id: state.songId!,
                  type: ArtworkType.AUDIO,
                  // ADD THESE TWO LINES
                  size: 1000, 
                  artworkQuality: FilterQuality.high,
                  // -------------------
                  artworkWidth: 300,
                  artworkHeight: 300,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: const Center(
                    child: Icon(Icons.music_note, size: 120, color: Colors.white54),
                  ),
                )
              : const Center(
                  key: ValueKey('empty_icon'),
                  child: Icon(Icons.music_note, size: 120, color: Colors.white54),
                ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(PlayerReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            state.title, // Injected actual track title
            maxLines: 1, // Prevent long names from breaking the UI
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            state.artist, // Injected actual artist name
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      ],
    );
  }

// Notice we don't pass 'state' as an argument anymore, the builder provides it
  Widget _buildProgressBar(BuildContext context) { 
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          // WRAP THE SLIDER AND TEXT IN A DEDICATED BLOC BUILDER
          child: BlocBuilder<PlayerBloc, PlayerState>(
            // This builder has no buildWhen mask, so it reacts to every single 200ms tick
            builder: (context, state) {
              if (state is! PlayerReady) return const SizedBox.shrink();
              
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.1),
                    ),
                    child: Slider(
                      min: 0.0,
                      max: state.duration.inSeconds.toDouble() > 0
                          ? state.duration.inSeconds.toDouble()
                          : 1.0,
                      value: state.position.inSeconds.toDouble().clamp(
                            0.0,
                            state.duration.inSeconds.toDouble() > 0
                                ? state.duration.inSeconds.toDouble()
                                : 1.0,
                          ),
                      onChanged: (value) {
                        final newPosition = Duration(seconds: value.toInt());
                        context.read<PlayerBloc>().add(SeekAudioEvent(newPosition));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(state.position),
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                        Text(
                          _formatDuration(state.duration),
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context, PlayerReady state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FrostedIconButton(
          iconSize: 40,
          icon: Icons.skip_previous_rounded,
          onPressed: () {
            context.read<PlayerBloc>().add(SkipPreviousEvent());
          }, // To be implemented later
        ),
        FrostedIconButton(
          iconSize: 80,
          icon: state.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          onPressed: () {
            if (state.isPlaying) {
              context.read<PlayerBloc>().add(PauseAudioEvent());
            } else {
              context.read<PlayerBloc>().add(PlayAudioEvent());
            }
          },
        ),
        FrostedIconButton(
          iconSize: 40,
          icon: Icons.skip_next_rounded,
          onPressed: () {
            context.read<PlayerBloc>().add(SkipNextEvent());
          }, // to be implemented later
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitsMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitsSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitsMinutes:$twoDigitsSeconds";
}

class FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  const FrostedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    // ClipOval forces the blur effect strictly inside a circular boundary
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.all(iconSize * 0.4),
                child: Icon(icon, color: Colors.white, size: iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

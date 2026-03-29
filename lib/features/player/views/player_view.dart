import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../bloc/player_states.dart';


class PlayerView extends StatelessWidget{
  const PlayerView({super.key});

  @override
  Widget build(BuildContext) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hearil'),
        centerTitle: true,
      ),
      body: Center(
        // BlocBuilder is the reactive heart of the UI
        child: BlocBuilder<PlayerBloc, PlayerState>(builder: (context, state) {
          // Act as a state machine for the UI
          if(state is PlayerInitial || state is PlayerLoading) {
            return const CircularProgressIndicator();
          } else if(state is PlayerError) {
            return Text('Error: ${state.message}');
          } else if(state is PlayerReady) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 120, color: Colors.grey),
                const SizedBox(height: 40,),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Slider(
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.grey.shade800,
                    // Prevent division by zero and cap the slider
                    min: 0.0,
                    max: state.duration.inSeconds.toDouble() > 0
                      ? state.duration.inSeconds.toDouble()
                      : 1.0, 
                    value: state.position.inSeconds.toDouble().clamp(
                      0.0,
                      state.duration.inSeconds.toDouble() > 0
                      ? state.duration.inSeconds.toDouble()
                      : 1.0),
                    onChanged: (value){
                      final newPosition = Duration(seconds: value.toInt());

                      context.read<PlayerBloc>().add(SeekAudioEvent(newPosition));
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(state.position)),
                      Text(_formatDuration(state.duration)),
                    ],
                  ),
                ),

                // The play pause button
                IconButton(
                  iconSize: 80,
                  color: Colors.blueAccent,
                  icon: Icon(
                    state.isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline
                  ),
                  onPressed: () {
                    // Dispathc events back to the Bloc based on current state
                    if(state.isPlaying) {
                      context.read<PlayerBloc>().add(PauseAudioEvent());
                    } else {
                      context.read<PlayerBloc>().add(PlayAudioEvent());
                    }
                  },
                )
              ],
            );
          }
          return const SizedBox.shrink();
        })
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitsMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitsSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitsMinutes:$twoDigitsSeconds";
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'features/player/bloc/player_bloc.dart';
import 'features/player/bloc/player_event.dart';
import 'features/player/views/player_view.dart';
import 'features/player/views/library_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.hearil.app.channel.audio',
    androidNotificationChannelName: "Audio playback",
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Initialize the core service once
  final audioService = AudioService();

  runApp(HearilApp(audioService: audioService));
}

class HearilApp extends StatelessWidget {
  final AudioService audioService;

  // This is the constructor
  const HearilApp({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(audioService)..add(InitializePlayerEvent()),
      child: MaterialApp(
        title: 'Music Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        // 3. The home is now just the raw LibraryView. 
        // It will automatically inherit the Bloc from above!
        home: const LibraryView(), 
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'features/player/bloc/player_bloc.dart';
import 'features/player/bloc/player_event.dart';
import 'features/player/views/player_view.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.hearil.app.channel.audio',
    androidNotificationChannelName: "Audio playback",
    androidNotificationOngoing: true,
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
    return MaterialApp(
      title: 'Hearil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // inject the BLoC down the widget tree
      home: BlocProvider(create: (context) {
        final bloc = PlayerBloc(audioService);

        bloc.add(const LoadAudioEvent(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
        ));
        return bloc;
      },
      child: const PlayerView(),
      )
    );
  }
}
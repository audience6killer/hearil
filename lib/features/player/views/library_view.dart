import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hearil_music_player/core/utils/slide_up_route.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../player/bloc/player_bloc.dart';
import '../../player/bloc/player_event.dart';
import '../../player/bloc/player_states.dart';
import '../../player/views/player_view.dart'; // Ensure this points to your Player screen

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Library',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
        // Replace your scaffold body with this Column:
        body: Column(
          children: [
            // 1. The main library tabs
            Expanded(
              child: BlocBuilder<PlayerBloc, PlayerState>(
                buildWhen: (previous, current) {
                  if (previous is PlayerReady && current is PlayerReady) {
                    // Only rebuild the lists if the actual database arrays change
                    return previous.playlist.length != current.playlist.length;
                  }
                  return true; // Always rebuild when moving from Loading -> Ready
                },
                builder: (context, state) {
                  if (state is PlayerInitial || state is PlayerLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (state is PlayerError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  } else if (state is PlayerReady) {
                    return TabBarView(
                      children: [
                        _buildSongsList(context, state.playlist),
                        _buildAlbumsList(state.albums),
                        _buildArtistsList(state.artists),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 2. The Floating Mini-Player
            _buildMiniPlayer(context),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: ALL SONGS ---
  Widget _buildSongsList(BuildContext context, List<SongModel> songs) {
    return ListView.builder(
      itemCount: songs.length,
      // OPTIMIZATION 1: O(1) Scroll Math. Forces every item to be exactly 70px high.
      itemExtent: 70.0,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkHeight: 50,
              artworkWidth: 50,
              artworkBorder: BorderRadius.circular(2),

              // OPTIMIZATION 2: Throttle the OS memory request
              size: 200, // Request a tiny thumbnail buffer
              artworkQuality: FilterQuality.low, // Use cheap Skia interpolation
              // format: ArtworkFormat.JPEG, // JPEG decodes much faster than PNG
              nullArtworkWidget: Container(
                width: 50,
                height: 50,
                color: Colors.white.withOpacity(0.1),
                child: const Icon(Icons.music_note, color: Colors.white54),
              ),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            song.artist ?? 'Unknown Artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54),
          ),
          onTap: () {
            context.read<PlayerBloc>().add(LoadAudioEvent(song));
          },
        );
      },
    );
  }

  // --- TAB 2: ALBUMS ---
  Widget _buildAlbumsList(List<AlbumModel> albums) {
    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          leading: const Icon(Icons.album, color: Colors.white54, size: 40),
          title: Text(album.album, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            "${album.numOfSongs} Songs",
            style: const TextStyle(color: Colors.white54),
          ),
          // ToDo: Implement navigation to an "Album Details" view to filter songs
        );
      },
    );
  }

  // --- TAB 3: ARTISTS ---
  Widget _buildArtistsList(List<ArtistModel> artists) {
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: const Icon(Icons.person, color: Colors.white54, size: 40),
          title: Text(
            artist.artist,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "${artist.numberOfTracks} Tracks",
            style: const TextStyle(color: Colors.white54),
          ),
          // ToDo: Implement navigation to an "Artist Details" view to filter songs
        );
      },
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      // Only rebuild the mini-player if the song physically changes, or if play/pause is toggled
      buildWhen: (previous, current) {
        if (previous is PlayerReady && current is PlayerReady) {
          return previous.songId != current.songId ||
              previous.isPlaying != current.isPlaying;
        }
        return true;
      },
      builder: (context, state) {
        // Hide the mini player if nothing is playing
        if (state is! PlayerReady || state.songId == null)
          return const SizedBox.shrink();

        return GestureDetector(
          // Slide to the full Player View when tapped
          onTap: () {
            Navigator.push(context, SlideUpRoute(page: const PlayerView()));
          },
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 1. Tiny Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: QueryArtworkWidget(
                    key: ValueKey(state.songId),
                    id: state.songId!,
                    type: ArtworkType.AUDIO,
                    size: 100, // Optimized for memory
                    artworkQuality: FilterQuality.low,
                    artworkWidth: 46,
                    artworkHeight: 46,
                    nullArtworkWidget: Container(
                      width: 46,
                      height: 46,
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Track Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        state.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Mini Play/Pause Button
                IconButton(
                  icon: Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    if (state.isPlaying) {
                      context.read<PlayerBloc>().add(PauseAudioEvent());
                    } else {
                      context.read<PlayerBloc>().add(PlayAudioEvent());
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

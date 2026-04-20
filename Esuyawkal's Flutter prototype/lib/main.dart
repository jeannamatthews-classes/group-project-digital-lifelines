import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/models/spotify_models.dart';
import 'package:flutter_application_1/services/spotify_file_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Lifelines',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Digital Lifelines'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  TabController? _tabController;
  List<SpotifyImport> imports = [];

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    _tabController?.dispose();
    if (imports.isNotEmpty) {
      _tabController =
          TabController(length: imports.length, vsync: this);
    } else {
      _tabController = null;
    }
  }

  void _updateTabController() {
    _initializeTabController();
  }

  Future<void> _importJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final import = await SpotifyFileService.parseJsonFile(file);

      if (import != null) {
        setState(() {
          imports.add(import);
          _updateTabController();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported: ${import.displayName}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to parse JSON file')),
          );
        }
      }
    }
  }

  void _removeImport(int index) {
    setState(() {
      imports.removeAt(index);
      _updateTabController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: imports.asMap().entries.map((entry) {
                  return Tab(
                    text: entry.value.tabLabel,
                    icon: entry.value.type == ImportType.streamingHistory
                        ? const Icon(Icons.music_note)
                        : const Icon(Icons.playlist_play),
                  );
                }).toList(),
              )
            : null,
      ),
      body: imports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No imports yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Import a Spotify JSON file to get started'),
                ],
              ),
            )
          : _tabController != null
              ? TabBarView(
                  controller: _tabController,
                  children: imports.map((import) {
                    if (import.type == ImportType.streamingHistory) {
                      return _buildStreamingHistoryView(import);
                    } else {
                      return _buildPlaylistView(import);
                    }
                  }).toList(),
                )
              : const Center(child: Text('Error initializing tabs')),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (imports.isNotEmpty)
            FloatingActionButton(
              onPressed: () {
                if (_tabController != null) {
                  _removeImport(_tabController!.index);
                }
              },
              tooltip: 'Remove Current Import',
              child: const Icon(Icons.delete),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _importJsonFile,
            tooltip: 'Import JSON',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingHistoryView(SpotifyImport import) {
    final history = import.data as SpotifyStreamingHistory;
    final topArtists = history.getTopArtists();
    final totalPlaytime = history.getTotalPlaytime();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Stats'),
              const Tab(text: 'Tracks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Stats Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Total Tracks',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              history.entries.length.toString(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Total Playtime',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${(totalPlaytime ~/ 3600000)} hours',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Top Artists',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ...topArtists.entries.map((entry) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(topArtists.keys.toList().indexOf(entry.key) + 1 ~/ 10 == 0 ? (topArtists.keys.toList().indexOf(entry.key) + 1).toString() : '${(topArtists.keys.toList().indexOf(entry.key) + 1) % 10}'),
                        ),
                        title: Text(entry.key),
                        trailing: Text('${entry.value} plays'),
                      );
                    }),
                  ],
                ),
                // Tracks Tab
                ListView.builder(
                  itemCount: history.entries.length,
                  itemBuilder: (context, index) {
                    final entry = history.entries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(entry.trackName ?? 'Unknown'),
                        subtitle: Text(entry.artistName ?? 'Unknown Artist'),
                        trailing: Text(entry.durationDisplay),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistView(SpotifyImport import) {
    final playlists = import.data as SpotifyPlaylist;

    return ListView.builder(
      itemCount: playlists.playlists.length,
      itemBuilder: (context, playlistIndex) {
        final playlist = playlists.playlists[playlistIndex];
        return ExpansionTile(
          leading: const Icon(Icons.playlist_play),
          title: Text(playlist.name),
          subtitle: Text('${playlist.items.length} tracks'),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playlist.items.length,
              itemBuilder: (context, trackIndex) {
                final track = playlist.items[trackIndex].track;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 4,
                  ),
                  leading: Text('${trackIndex + 1}'),
                  title: Text(track.trackName),
                  subtitle: Text(track.artistName),
                  trailing: Text(track.albumName),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
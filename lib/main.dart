import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';
import 'songs_data.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'Christian Hymns and Choruses',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: ScaleTransition(
                scale: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/App Icon.png', width: 150, height: 150),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text('v1.0.0+1', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    SongListScreen(),
    SearchScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            if (isTablet)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                  NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
                  NavigationRailDestination(icon: Icon(Icons.favorite), label: Text('Favorites')),
                  NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                ],
              ),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
        bottomNavigationBar: isTablet
            ? null
            : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                  BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                ],
              ),
      ),
    );
  }
}

class SongListScreen extends StatelessWidget {
  const SongListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final songs = appState.filteredSongs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hymns and Choruses'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<Language>(
            icon: const Icon(Icons.language),
            initialValue: appState.selectedLanguage,
            onSelected: (Language lang) {
              appState.setSelectedLanguage(lang);
            },
            itemBuilder: (BuildContext context) => Language.values.map((lang) {
              return PopupMenuItem<Language>(
                value: lang,
                child: Text(lang.name.toUpperCase()),
              );
            }).toList(),
          ),
        ],
      ),
      body: songs.isEmpty
          ? const Center(child: Text('No songs found for this language.'))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongTile(song: song);
              },
            ),
    );
  }
}

class SongTile extends StatelessWidget {
  final Song song;
  const SongTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${song.number}')),
      title: Text(song.title),
      subtitle: Text('${song.author} • ${song.language.name.toUpperCase()}'),
      trailing: Consumer<AppState>(
        builder: (context, appState, child) {
          return IconButton(
            icon: Icon(
              appState.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
              color: appState.isFavorite(song.id) ? Colors.red : null,
            ),
            onPressed: () => appState.toggleFavorite(song.id),
          );
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)),
        );
      },
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lowerQuery = _query.toLowerCase();

    // 1. Filter by language
    final List<Song> languageSongs = allSongs.where((song) => song.language == appState.selectedLanguage).toList();

    // 2. Filter by search query
    List<Song> filteredSongs;
    if (_query.isEmpty) {
      filteredSongs = languageSongs;
    } else {
      filteredSongs = languageSongs.where((song) {
        // Numerical search by language-specific number
        if (song.number.toString() == _query) return true;
        
        // Title search (Must START with the query as requested)
        if (song.title.toLowerCase().startsWith(lowerQuery)) return true;
        
        // First line and Keywords search
        // We only search lyrics if the query is more than one character 
        // to keep single-letter searches strictly alphabetical by title.
        if (_query.length > 1) {
          for (var part in song.parts) {
            if (part.text.toLowerCase().contains(lowerQuery)) return true;
          }
        }
        
        return false;
      }).toList();
    }

    // 3. Sort alphabetically by title
    filteredSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by number, title, or lyrics...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: filteredSongs.isEmpty
          ? const Center(child: Text('No matching songs found in this language.'))
          : ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                return SongTile(song: filteredSongs[index]);
              },
            ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites & Playlists'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Favorites'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const FavoriteSongsList(),
            const PlaylistsList(),
          ],
        ),
      ),
    );
  }
}

class FavoriteSongsList extends StatelessWidget {
  const FavoriteSongsList({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final favorites = appState.favoriteSongs;

    if (favorites.isEmpty) {
      return const Center(child: Text('No favorites yet.'));
    }

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) => SongTile(song: favorites[index]),
    );
  }
}

class PlaylistsList extends StatelessWidget {
  const PlaylistsList({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final playlists = appState.playlists;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context, appState),
            icon: const Icon(Icons.add),
            label: const Text('Create New Playlist'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final name = playlists.keys.elementAt(index);
              final songIds = playlists[name]!;
              return ListTile(
                title: Text(name),
                subtitle: Text('${songIds.length} songs'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistDetailScreen(name: name),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => appState.deletePlaylist(name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                appState.createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final String name;
  const PlaylistDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final songIds = appState.playlists[name] ?? [];
    final songs = allSongs.where((s) => songIds.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: songs.isEmpty
          ? const Center(child: Text('No songs in this playlist.'))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${song.number}')),
                  title: Text(song.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => appState.removeFromPlaylist(name, song.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(appState.themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: appState.themeMode,
              onChanged: (mode) {
                if (mode != null) appState.setThemeMode(mode);
              },
              items: ThemeMode.values.map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode.name.toUpperCase()));
              }).toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lyrics Font Size', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: appState.fontSize,
                  min: 12,
                  max: 36,
                  divisions: 12,
                  label: appState.fontSize.round().toString(),
                  onChanged: (value) => appState.setFontSize(value),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(appState.selectedLanguage.name.toUpperCase()),
            trailing: DropdownButton<Language>(
              value: appState.selectedLanguage,
              onChanged: (lang) {
                if (lang != null) appState.setSelectedLanguage(lang);
              },
              items: Language.values.map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang.name.toUpperCase()));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SongDetailScreen extends StatelessWidget {
  final Song song;
  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () => _showAddToPlaylistDialog(context, appState, song.id),
          ),
          IconButton(
            icon: Icon(
              appState.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
              color: appState.isFavorite(song.id) ? Colors.red : null,
            ),
            onPressed: () => appState.toggleFavorite(song.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'By ${song.author}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            ...song.parts.map((part) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (part is Verse)
                      Text(
                        'Verse ${part.number}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    if (part is Chorus)
                      const Text(
                        'Chorus',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      part.text,
                      style: TextStyle(fontSize: appState.fontSize, height: 1.4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, AppState appState, int songId) {
    if (appState.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playlists found. Create one in the Favorites tab.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appState.playlists.length,
            itemBuilder: (context, index) {
              final name = appState.playlists.keys.elementAt(index);
              return ListTile(
                title: Text(name),
                onTap: () {
                  appState.addToPlaylist(name, songId);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

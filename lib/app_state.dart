import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'songs_data.dart';

class AppState extends ChangeNotifier {
  static const String _favoritesKey = 'favorites';
  static const String _fontSizeKey = 'fontSize';
  static const String _themeModeKey = 'themeMode';
  static const String _playlistsKey = 'playlists';
  static const String _languageKey = 'selectedLanguage';

  Set<int> _favoriteIds = {};
  double _fontSize = 18.0;
  ThemeMode _themeMode = ThemeMode.system;
  Map<String, List<int>> _playlists = {};
  Language _selectedLanguage = Language.english;

  AppState() {
    _loadData();
  }

  Set<int> get favoriteIds => _favoriteIds;
  double get fontSize => _fontSize;
  ThemeMode get themeMode => _themeMode;
  Map<String, List<int>> get playlists => _playlists;
  Language get selectedLanguage => _selectedLanguage;

  List<Song> get favoriteSongs =>
      allSongs.where((s) => _favoriteIds.contains(s.id)).toList();

  List<Song> get filteredSongs =>
      allSongs.where((s) => s.language == _selectedLanguage).toList();

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _favoriteIds = (prefs.getStringList(_favoritesKey) ?? [])
        .map(int.parse)
        .toSet();
    
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 18.0;
    
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    final playlistsJson = prefs.getString(_playlistsKey);
    if (playlistsJson != null) {
      final Map<String, dynamic> decoded = json.decode(playlistsJson);
      _playlists = decoded.map((key, value) => MapEntry(key, List<int>.from(value)));
    }

    final languageIndex = prefs.getInt(_languageKey);
    if (languageIndex != null) {
      _selectedLanguage = Language.values[languageIndex];
    }
    
    notifyListeners();
  }

  void setSelectedLanguage(Language language) {
    _selectedLanguage = language;
    _saveLanguage();
    notifyListeners();
  }

  void toggleFavorite(int songId) {
    if (_favoriteIds.contains(songId)) {
      _favoriteIds.remove(songId);
    } else {
      _favoriteIds.add(songId);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(int songId) => _favoriteIds.contains(songId);

  void setFontSize(double size) {
    _fontSize = size;
    _saveFontSize();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }

  void createPlaylist(String name) {
    if (!_playlists.containsKey(name)) {
      _playlists[name] = [];
      _savePlaylists();
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    _playlists.remove(name);
    _savePlaylists();
    notifyListeners();
  }

  void addToPlaylist(String playlistName, int songId) {
    if (_playlists.containsKey(playlistName) && !_playlists[playlistName]!.contains(songId)) {
      _playlists[playlistName]!.add(songId);
      _savePlaylists();
      notifyListeners();
    }
  }

  void removeFromPlaylist(String playlistName, int songId) {
    if (_playlists.containsKey(playlistName)) {
      _playlists[playlistName]!.remove(songId);
      _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.map((id) => id.toString()).toList());
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playlistsKey, json.encode(_playlists));
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, _selectedLanguage.index);
  }
}

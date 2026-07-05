import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:new_christian_hymnsandchoruses_july/app_state.dart';
import 'package:new_christian_hymnsandchoruses_july/main.dart';
import 'package:new_christian_hymnsandchoruses_july/models.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState', () {
    test('toggleFavorite adds and removes a song id', () async {
      final appState = AppState();
      await Future<void>.delayed(Duration.zero);

      expect(appState.isFavorite(1), isFalse);

      appState.toggleFavorite(1);
      expect(appState.isFavorite(1), isTrue);

      appState.toggleFavorite(1);
      expect(appState.isFavorite(1), isFalse);
    });

    test('playlists can be created, populated, and deleted', () async {
      final appState = AppState();
      await Future<void>.delayed(Duration.zero);

      appState.createPlaylist('Sunday Service');
      expect(appState.playlists.containsKey('Sunday Service'), isTrue);

      appState.addToPlaylist('Sunday Service', 3);
      expect(appState.playlists['Sunday Service'], contains(3));

      appState.removeFromPlaylist('Sunday Service', 3);
      expect(appState.playlists['Sunday Service'], isNot(contains(3)));

      appState.deletePlaylist('Sunday Service');
      expect(appState.playlists.containsKey('Sunday Service'), isFalse);
    });

    test('filteredSongs only returns songs for the selected language', () async {
      final appState = AppState();
      await Future<void>.delayed(Duration.zero);

      appState.setSelectedLanguage(Language.tamil);
      expect(appState.filteredSongs, isNotEmpty);
      expect(
        appState.filteredSongs.every((s) => s.language == Language.tamil),
        isTrue,
      );
    });
  });

  group('SearchScreen', () {
    Widget buildTestable(AppState appState) {
      return ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(home: SearchScreen()),
      );
    }

    testWidgets('filters songs by exact song number', (tester) async {
      final appState = AppState();
      await tester.pumpWidget(buildTestable(appState));
      await tester.pumpAndSettle();

      // Single-character queries match by exact number only (lyrics search
      // is skipped below length 2), so this pins down one song unambiguously.
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '2');
      await tester.pumpAndSettle();

      expect(find.text('To God be The Glory'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows an empty state when nothing matches', (tester) async {
      final appState = AppState();
      await tester.pumpWidget(buildTestable(appState));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'zzzznotasong');
      await tester.pumpAndSettle();

      expect(
        find.text('No matching songs found in this language.'),
        findsOneWidget,
      );
    });
  });
}

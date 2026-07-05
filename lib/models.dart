enum Language {
  english,
  telugu,
  hindi,
  tamil,
  malayalam,
}

sealed class SongPart {
  final String text;
  SongPart(this.text);
}

class Verse extends SongPart {
  final int number;
  Verse(this.number, super.text);
}

class Chorus extends SongPart {
  Chorus(super.text);
}

class Song {
  final int id; // Global unique ID for internal usage
  final int number; // Language-specific number shown to user
  final String title;
  final String author;
  final List<SongPart> parts;
  final Language language;

  Song({
    required this.id,
    required this.number,
    required this.title,
    required this.author,
    required this.parts,
    this.language = Language.english,
  });
}

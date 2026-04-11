// lib/ibada/models/ibada_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Hymn Book ────────────────────────────────────────────────

enum HymnBook {
  nyimboZaInjili,
  tenziZaRohoni,
  katoliki;

  String get label {
    switch (this) {
      case nyimboZaInjili: return 'Nyimbo za Injili';
      case tenziZaRohoni: return 'Tenzi za Rohoni';
      case katoliki: return 'Tumwabudu Mungu Wetu';
    }
  }
}

// ─── Hymn ─────────────────────────────────────────────────────

class Hymn {
  final int id;
  final int number;
  final String title;
  final String? book;
  final List<String> verses;
  final String? chorus;
  final String? chords;
  final String? audioUrl;
  final String? scriptureRef;
  final bool isFavorite;

  Hymn({
    required this.id,
    required this.number,
    required this.title,
    this.book,
    required this.verses,
    this.chorus,
    this.chords,
    this.audioUrl,
    this.scriptureRef,
    this.isFavorite = false,
  });

  factory Hymn.fromJson(Map<String, dynamic> json) {
    return Hymn(
      id: _parseInt(json['id']),
      number: _parseInt(json['number']),
      title: json['title']?.toString() ?? '',
      book: json['book']?.toString(),
      verses: (json['verses'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      chorus: json['chorus']?.toString(),
      chords: json['chords']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      scriptureRef: json['scripture_ref']?.toString(),
      isFavorite: _parseBool(json['is_favorite']),
    );
  }
}

// ─── Worship Song ─────────────────────────────────────────────

class WorshipSong {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final String? audioUrl;
  final String? coverUrl;
  final int durationSeconds;
  final String? lyrics;

  WorshipSong({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.audioUrl,
    this.coverUrl,
    required this.durationSeconds,
    this.lyrics,
  });

  factory WorshipSong.fromJson(Map<String, dynamic> json) {
    return WorshipSong(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      album: json['album']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      durationSeconds: _parseInt(json['duration_seconds']),
      lyrics: json['lyrics']?.toString(),
    );
  }

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Playlist ─────────────────────────────────────────────────

class WorshipPlaylist {
  final int id;
  final String name;
  final int songCount;
  final String? coverUrl;

  WorshipPlaylist({
    required this.id,
    required this.name,
    required this.songCount,
    this.coverUrl,
  });

  factory WorshipPlaylist.fromJson(Map<String, dynamic> json) {
    return WorshipPlaylist(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      songCount: _parseInt(json['song_count']),
      coverUrl: json['cover_url']?.toString(),
    );
  }
}

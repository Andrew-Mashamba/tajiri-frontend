// lib/ibada/pages/ibada_home_page.dart
import 'package:flutter/material.dart';
import '../models/ibada_models.dart';
import '../services/ibada_service.dart';
import '../widgets/hymn_tile.dart';
import 'hymn_viewer_page.dart';
import 'hymn_browser_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class IbadaHomePage extends StatefulWidget {
  final int userId;
  const IbadaHomePage({super.key, required this.userId});
  @override
  State<IbadaHomePage> createState() => _IbadaHomePageState();
}

class _IbadaHomePageState extends State<IbadaHomePage> {
  List<Hymn> _recentHymns = [];
  List<WorshipSong> _songs = [];
  List<WorshipPlaylist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      IbadaService.getHymns(),
      IbadaService.getSongs(),
      IbadaService.getPlaylists(),
    ]);
    if (mounted) {
      final hymnR = results[0] as PaginatedResult<Hymn>;
      final songR = results[1] as PaginatedResult<WorshipSong>;
      final plR = results[2] as PaginatedResult<WorshipPlaylist>;
      setState(() {
        _isLoading = false;
        if (hymnR.success) _recentHymns = hymnR.items;
        if (songR.success) _songs = songR.items;
        if (plR.success) _playlists = plR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _load,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 24, color: _kPrimary),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HymnBrowserPage())),
                  ),
                ),
                  // Hymn books
                  const Text('Vitabu vya Nyimbo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  const Text('Hymn Books',
                      style: TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: HymnBook.values.map((b) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: b != HymnBook.katoliki ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => HymnBrowserPage(initialBook: b.name))),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
                                  const SizedBox(height: 8),
                                  Text(b.label,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                      maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Recent hymns
                  if (_recentHymns.isNotEmpty) ...[
                    const Text('Nyimbo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text('Hymns',
                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    ..._recentHymns.take(5).map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HymnTile(
                            hymn: h,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => HymnViewerPage(hymn: h))),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Gospel songs
                  if (_songs.isNotEmpty) ...[
                    const Text('Nyimbo za Injili',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text('Gospel Music',
                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    ..._songs.take(5).map((s) => _SongRow(song: s)),
                    const SizedBox(height: 16),
                  ],

                  // Playlists
                  if (_playlists.isNotEmpty) ...[
                    const Text('Orodha za Nyimbo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text('Playlists',
                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _playlists.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final pl = _playlists[i];
                          return Container(
                            width: 130,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.queue_music_rounded, size: 28, color: _kPrimary),
                                const Spacer(),
                                Text(pl.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${pl.songCount} nyimbo / songs',
                                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
  }
}

class _SongRow extends StatelessWidget {
  final WorshipSong song;
  const _SongRow({required this.song});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.music_note_rounded, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(song.artist,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(song.durationFormatted,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_rounded, size: 28, color: _kPrimary),
          ],
        ),
      ),
    );
  }
}

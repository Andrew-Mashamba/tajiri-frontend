// lib/ibada/pages/hymn_viewer_page.dart
import 'package:flutter/material.dart';
import '../models/ibada_models.dart';
import '../services/ibada_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class HymnViewerPage extends StatefulWidget {
  final Hymn hymn;
  const HymnViewerPage({super.key, required this.hymn});
  @override
  State<HymnViewerPage> createState() => _HymnViewerPageState();
}

class _HymnViewerPageState extends State<HymnViewerPage> {
  bool _showChords = false;
  double _fontSize = 16.0;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.hymn.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hymn;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${h.number} ${h.title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (h.book != null)
              Text(h.book!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22, color: _isFavorite ? Colors.red : _kPrimary),
            onPressed: () async {
              await IbadaService.toggleFavorite(h.id);
              if (mounted) setState(() => _isFavorite = !_isFavorite);
            },
          ),
          if (h.chords != null)
            IconButton(
              icon: Icon(Icons.music_note_rounded, size: 22,
                  color: _showChords ? _kPrimary : _kSecondary),
              onPressed: () => setState(() => _showChords = !_showChords),
            ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Ukubwa / Font Size', style: TextStyle(fontSize: 15)),
                  content: StatefulBuilder(
                    builder: (_, setS) => Slider(
                      value: _fontSize, min: 12, max: 28, divisions: 8,
                      activeColor: _kPrimary,
                      onChanged: (v) { setS(() => _fontSize = v); setState(() {}); },
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx),
                        child: const Text('Sawa', style: TextStyle(color: _kPrimary))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Scripture ref
          if (h.scriptureRef != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(h.scriptureRef!,
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: _kSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Verses
          for (int i = 0; i < h.verses.length; i++) ...[
            Text('${i + 1}.',
                style: TextStyle(fontSize: _fontSize * 0.8, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 4),
            Text(h.verses[i],
                style: TextStyle(fontSize: _fontSize, color: _kPrimary, height: 1.6)),
            const SizedBox(height: 12),
            // Chorus after each verse
            if (h.chorus != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: _kPrimary, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kiitikio / Chorus:',
                        style: TextStyle(fontSize: _fontSize * 0.8, fontWeight: FontWeight.w600, color: _kSecondary)),
                    const SizedBox(height: 4),
                    Text(h.chorus!,
                        style: TextStyle(fontSize: _fontSize, color: _kPrimary, fontStyle: FontStyle.italic, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],

          // Chords
          if (_showChords && h.chords != null) ...[
            const SizedBox(height: 16),
            const Text('Mizani / Chords',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(h.chords!,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: _kPrimary, height: 1.5)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

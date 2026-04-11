// lib/biblia/pages/bible_reader_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/biblia_models.dart';
import '../services/biblia_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BibleReaderPage extends StatefulWidget {
  final BibleBook book;
  final int initialChapter;
  const BibleReaderPage({super.key, required this.book, this.initialChapter = 1});
  @override
  State<BibleReaderPage> createState() => _BibleReaderPageState();
}

class _BibleReaderPageState extends State<BibleReaderPage> {
  late int _chapter;
  List<BibleVerse> _verses = [];
  bool _isLoading = true;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _chapter = widget.initialChapter;
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() => _isLoading = true);
    final r = await BibliaService.getChapter(
      bookId: widget.book.id,
      chapter: _chapter,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _verses = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.book.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('${widget.book.nameEn} - Sura $_chapter',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, size: 22),
            onPressed: _showFontDialog,
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.list_rounded, size: 24),
            onSelected: (ch) {
              _chapter = ch;
              _loadChapter();
            },
            itemBuilder: (_) => List.generate(
              widget.book.chapters,
              (i) => PopupMenuItem(value: i + 1, child: Text('Sura ${i + 1}')),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _verses.length,
                    itemBuilder: (_, i) {
                      final v = _verses[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onLongPress: () => _showVerseActions(v),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${v.verse} ',
                                  style: TextStyle(
                                    fontSize: _fontSize * 0.7,
                                    fontWeight: FontWeight.w700,
                                    color: _kSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text: v.text,
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    color: _kPrimary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Navigation bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _chapter > 1
                          ? GestureDetector(
                              onTap: () {
                                _chapter--;
                                _loadChapter();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chevron_left_rounded, size: 20, color: _kPrimary),
                                    SizedBox(width: 4),
                                    Text('Nyuma / Prev', style: TextStyle(color: _kPrimary, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(width: 80),
                      Text('Sura / Chapter $_chapter / ${widget.book.chapters}',
                          style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      _chapter < widget.book.chapters
                          ? GestureDetector(
                              onTap: () {
                                _chapter++;
                                _loadChapter();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _kPrimary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Mbele / Next', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(width: 80),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showFontDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ukubwa wa herufi / Font Size',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: StatefulBuilder(
          builder: (_, setS) => Slider(
            value: _fontSize,
            min: 12,
            max: 28,
            divisions: 8,
            activeColor: _kPrimary,
            label: _fontSize.round().toString(),
            onChanged: (v) {
              setS(() => _fontSize = v);
              setState(() {});
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Sawa / OK', style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  void _showVerseActions(BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.book.name} $_chapter:${verse.verse}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 4),
              Text(verse.text,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              _ActionRow(
                icon: Icons.bookmark_add_rounded,
                label: 'Hifadhi / Bookmark',
                onTap: () async {
                  Navigator.pop(ctx);
                  await BibliaService.addBookmark({
                    'book_id': verse.bookId,
                    'chapter': _chapter,
                    'verse': verse.verse,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imehifadhiwa / Bookmarked')),
                    );
                  }
                },
              ),
              _ActionRow(
                icon: Icons.share_rounded,
                label: 'Shiriki / Share',
                onTap: () {
                  Navigator.pop(ctx);
                  final text = '${widget.book.name} $_chapter:${verse.verse}\n${verse.text}';
                  SharePlus.instance.share(ShareParams(text: text));
                },
              ),
              _ActionRow(
                icon: Icons.copy_rounded,
                label: 'Nakili / Copy',
                onTap: () {
                  Navigator.pop(ctx);
                  final text = '${widget.book.name} $_chapter:${verse.verse} - ${verse.text}';
                  Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imenakiliwa / Copied')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _kPrimary),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 15, color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}

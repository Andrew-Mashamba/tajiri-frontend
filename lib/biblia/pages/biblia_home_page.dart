// lib/biblia/pages/biblia_home_page.dart
import 'package:flutter/material.dart';
import '../models/biblia_models.dart';
import '../services/biblia_service.dart';
import '../widgets/verse_card.dart';
import 'bible_reader_page.dart';
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BibliaHomePage extends StatefulWidget {
  final int userId;
  const BibliaHomePage({super.key, required this.userId});
  @override
  State<BibliaHomePage> createState() => _BibliaHomePageState();
}

class _BibliaHomePageState extends State<BibliaHomePage> {
  VerseOfDay? _verseOfDay;
  List<BibleBook> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      BibliaService.getVerseOfDay(),
      BibliaService.getBooks(),
    ]);
    if (mounted) {
      final vodR = results[0] as SingleResult<VerseOfDay>;
      final booksR = results[1] as PaginatedResult<BibleBook>;
      setState(() {
        _isLoading = false;
        if (vodR.success) _verseOfDay = vodR.data;
        if (booksR.success) _books = booksR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    return RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Verse of the day
                  if (_verseOfDay != null) ...[
                    const Text('Aya ya Leo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text("Verse of the Day",
                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    VerseCard(
                      text: _verseOfDay!.text,
                      reference: _verseOfDay!.reference,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Books - OT
                  const Text('Agano la Kale',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  const Text('Old Testament',
                      style: TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 10),
                  _buildBookGrid(_books.where((b) => b.testament == 'OT').toList()),
                  const SizedBox(height: 20),

                  // Books - NT
                  const Text('Agano Jipya',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  const Text('New Testament',
                      style: TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 10),
                  _buildBookGrid(_books.where((b) => b.testament == 'NT').toList()),
                  const SizedBox(height: 24),
                ],
              ),
    );
  }

  Widget _buildBookGrid(List<BibleBook> books) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: books.map((book) {
        return GestureDetector(
          onTap: () => _openBook(book),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              book.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openBook(BibleBook book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BibleReaderPage(book: book)),
    );
  }
}

// lib/library/pages/library_home_page.dart
import 'package:flutter/material.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';
import 'book_detail_page.dart';
import 'bookshelf_page.dart';
import '../widgets/book_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class LibraryHomePage extends StatefulWidget {
  final int userId;
  const LibraryHomePage({super.key, required this.userId});
  @override
  State<LibraryHomePage> createState() => _LibraryHomePageState();
}

class _LibraryHomePageState extends State<LibraryHomePage> {
  final LibraryService _service = LibraryService();
  List<LibraryBook> _books = [];
  bool _isLoading = true;
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadBooks({String? query}) async {
    setState(() => _isLoading = true);
    final result = await _service.searchBooks(query: query);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _books = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBooks,
          color: _kPrimary,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.local_library_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text('Maktaba', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text('Library — e-books, textbooks & research papers', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            // Search
            TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Tafuta kitabu, mwandishi...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              onSubmitted: (v) => _loadBooks(query: v.trim()),
            ),
            const SizedBox(height: 12),
            // Quick links
            Row(children: [
              _quickLink(Icons.bookmark_rounded, 'Rafu Yangu', () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookshelfPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              _quickLink(Icons.category_rounded, 'Makundi', () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chagua kundi hapo chini / Select a category below')));
              }),
            ]),
            const SizedBox(height: 16),
            // Categories
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: BookCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(label: Text(c.displayName, style: const TextStyle(fontSize: 12)), onPressed: () => _loadBooks(query: c.name)),
              )).toList()),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_books.isEmpty)
              Container(padding: const EdgeInsets.all(48), alignment: Alignment.center, child: const Column(children: [
                Icon(Icons.menu_book_rounded, size: 48, color: _kSecondary),
                SizedBox(height: 8),
                Text('Hakuna vitabu / No books found', style: TextStyle(color: _kSecondary)),
              ]))
            else
              ..._books.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookCard(book: b, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: b, userId: widget.userId)))),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _quickLink(IconData icon, String label, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Icon(icon, size: 20, color: _kPrimary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
        ]),
      ),
    ));
  }
}

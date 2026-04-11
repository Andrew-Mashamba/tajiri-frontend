// lib/library/pages/bookshelf_page.dart
import 'package:flutter/material.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';
import '../widgets/book_card.dart';
import 'book_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BookshelfPage extends StatefulWidget {
  final int userId;
  const BookshelfPage({super.key, required this.userId});
  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  List<LibraryBook> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await LibraryService().getMyBookshelf();
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
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Rafu Yangu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _books.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shelves, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Rafu tupu', style: TextStyle(color: _kSecondary)),
                  Text('Your bookshelf is empty', style: TextStyle(color: _kSecondary, fontSize: 12)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _books.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BookCard(book: _books[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: _books[i], userId: widget.userId)))),
                  ),
                ),
    );
  }
}

// lib/library/pages/book_detail_page.dart
import 'package:flutter/material.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BookDetailPage extends StatelessWidget {
  final LibraryBook book;
  final int userId;
  const BookDetailPage({super.key, required this.book, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        actions: [
          IconButton(icon: Icon(book.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded), onPressed: () async {
            final result = await LibraryService().bookmarkBook(book.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result.success ? 'Imehifadhiwa / Bookmarked' : 'Imeshindwa / Failed'),
              ));
            }
          }),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Cover
          Center(child: Container(
            width: 160, height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12),
              image: book.coverUrl != null ? DecorationImage(image: NetworkImage(book.coverUrl!), fit: BoxFit.cover) : null,
            ),
            child: book.coverUrl == null ? const Center(child: Icon(Icons.menu_book_rounded, size: 48, color: _kSecondary)) : null,
          )),
          const SizedBox(height: 16),
          Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(book.author, style: const TextStyle(fontSize: 14, color: _kSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // Stats
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat(Icons.star_rounded, book.rating.toStringAsFixed(1)),
            _stat(Icons.people_rounded, '${book.readCount}'),
            _stat(Icons.auto_stories_rounded, '${book.pageCount}p'),
          ]),
          const SizedBox(height: 16),
          if (book.description != null) ...[
            Text(book.description!, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (book.hasEbook) FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inafungua kitabu...'))),
            icon: const Icon(Icons.chrome_reader_mode_rounded),
            label: const Text('Soma / Read'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await LibraryService().borrowBook(book.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.success ? 'Umeazima kitabu / Book borrowed' : 'Imeshindwa kuazima / Borrow failed'),
                ));
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Azima / Borrow'),
            style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          ),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Column(children: [
      Icon(icon, size: 20, color: _kPrimary),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
    ]);
  }
}

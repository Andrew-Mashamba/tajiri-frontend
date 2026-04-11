// lib/library/widgets/book_card.dart
import 'package:flutter/material.dart';
import '../models/library_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BookCard extends StatelessWidget {
  final LibraryBook book;
  final VoidCallback? onTap;
  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
            width: 52, height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8),
              image: book.coverUrl != null ? DecorationImage(image: NetworkImage(book.coverUrl!), fit: BoxFit.cover) : null,
            ),
            child: book.coverUrl == null ? const Center(child: Icon(Icons.menu_book_rounded, size: 24, color: _kSecondary)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(book.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(book.author, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
              const SizedBox(width: 2),
              Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: _kSecondary)),
              const SizedBox(width: 10),
              Text(book.category.displayName, style: const TextStyle(fontSize: 11, color: _kSecondary)),
              if (book.hasEbook) ...[const SizedBox(width: 8), const Icon(Icons.download_done_rounded, size: 14, color: _kPrimary)],
            ]),
          ])),
        ]),
      ),
    );
  }
}

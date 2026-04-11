// lib/hadith/pages/collection_detail_page.dart
import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CollectionDetailPage extends StatefulWidget {
  final HadithCollection collection;
  const CollectionDetailPage({super.key, required this.collection});

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final _service = HadithService();
  List<HadithBook> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getBooks(collectionId: widget.collection.id);
    if (mounted) {
      setState(() {
        _books = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.collection;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          col.nameSwahili.isNotEmpty ? col.nameSwahili : col.name,
          style: const TextStyle(color: _kPrimary, fontSize: 18,
              fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : Column(
                children: [
                  // ─── Collection Header ──────────────────
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(col.author,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${col.hadithCount} hadith',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text('${col.bookCount} vitabu',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(col.nameArabic,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22),
                            textDirection: TextDirection.rtl),
                      ],
                    ),
                  ),

                  // ─── Books List ─────────────────────────
                  Expanded(
                    child: _books.isEmpty
                        ? const Center(child: Text('Hakuna vitabu',
                            style: TextStyle(
                                color: _kSecondary, fontSize: 14)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _books.length,
                            itemBuilder: (context, i) {
                              final book = _books[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade200)),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8)),
                                    alignment: Alignment.center,
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            color: _kPrimary, fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  title: Text(book.name,
                                      style: const TextStyle(
                                          color: _kPrimary, fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      '${book.hadithCount} hadith',
                                      style: const TextStyle(
                                          color: _kSecondary, fontSize: 12)),
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: _kSecondary, size: 20),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Opening ${book.name}...'),
                                        backgroundColor: _kPrimary,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

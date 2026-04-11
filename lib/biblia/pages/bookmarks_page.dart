// lib/biblia/pages/bookmarks_page.dart
import 'package:flutter/material.dart';
import '../models/biblia_models.dart';
import '../services/biblia_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});
  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<BibleBookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await BibliaService.getBookmarks();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _bookmarks = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Bookmarks', style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Bado huna alama',
                          style: TextStyle(color: _kSecondary, fontSize: 14)),
                      const Text('No bookmarks yet',
                          style: TextStyle(color: _kSecondary, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookmarks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final bm = _bookmarks[i];
                      return Dismissible(
                        key: ValueKey(bm.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.red),
                        ),
                        onDismissed: (_) async {
                          await BibliaService.removeBookmark(bm.id);
                          if (mounted) _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bookmark_rounded, size: 18, color: _kPrimary),
                                  const SizedBox(width: 8),
                                  Text('${bm.bookName} ${bm.chapter}:${bm.verse}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary)),
                                  const Spacer(),
                                  if (bm.label != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(bm.label!,
                                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(bm.verseText,
                                  style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// lib/biblia/pages/bible_search_page.dart
import 'package:flutter/material.dart';
import '../models/biblia_models.dart';
import '../services/biblia_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BibleSearchPage extends StatefulWidget {
  const BibleSearchPage({super.key});
  @override
  State<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends State<BibleSearchPage> {
  final _searchCtrl = TextEditingController();
  List<BibleSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _testament;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    final r = await BibliaService.search(query: q, testament: _testament);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _results = r.items;
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
            Text('Tafuta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Search Bible', style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Tafuta neno au aya...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: _kPrimary, size: 20),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Chip(
                    label: 'Zote / All',
                    selected: _testament == null,
                    onTap: () {
                      setState(() => _testament = null);
                      if (_hasSearched) _search();
                    }),
                const SizedBox(width: 8),
                _Chip(
                    label: 'AK / OT',
                    selected: _testament == 'OT',
                    onTap: () {
                      setState(() => _testament = 'OT');
                      if (_hasSearched) _search();
                    }),
                const SizedBox(width: 8),
                _Chip(
                    label: 'AJ / NT',
                    selected: _testament == 'NT',
                    onTap: () {
                      setState(() => _testament = 'NT');
                      if (_hasSearched) _search();
                    }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Tafuta neno katika Biblia\nSearch the Bible',
                                style: TextStyle(color: _kSecondary, fontSize: 14),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Text('Hakuna matokeo / No results',
                                style: TextStyle(color: _kSecondary, fontSize: 14)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final sr = _results[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sr.reference,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary)),
                                    const SizedBox(height: 4),
                                    Text(sr.text,
                                        style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.4),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : _kSecondary,
            )),
      ),
    );
  }
}

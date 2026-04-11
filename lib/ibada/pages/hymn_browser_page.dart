// lib/ibada/pages/hymn_browser_page.dart
import 'package:flutter/material.dart';
import '../models/ibada_models.dart';
import '../services/ibada_service.dart';
import '../widgets/hymn_tile.dart';
import 'hymn_viewer_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class HymnBrowserPage extends StatefulWidget {
  final String? initialBook;
  const HymnBrowserPage({super.key, this.initialBook});
  @override
  State<HymnBrowserPage> createState() => _HymnBrowserPageState();
}

class _HymnBrowserPageState extends State<HymnBrowserPage> {
  final _searchCtrl = TextEditingController();
  List<Hymn> _hymns = [];
  bool _isLoading = true;
  String? _selectedBook;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBook;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final q = _searchCtrl.text.trim();
    final r = await IbadaService.getHymns(
      book: _selectedBook,
      search: q.isEmpty ? null : q,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _hymns = r.items;
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
            Text('Tafuta Wimbo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Browse Hymns',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
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
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Namba au jina...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
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
              ),
            ),
          ),
          // Book filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _BookChip(label: 'Zote / All', selected: _selectedBook == null,
                    onTap: () { _selectedBook = null; _load(); }),
                ...HymnBook.values.map((b) => _BookChip(
                      label: b.label,
                      selected: _selectedBook == b.name,
                      onTap: () { _selectedBook = b.name; _load(); },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _hymns.isEmpty
                    ? const Center(child: Text('Hakuna nyimbo / No hymns',
                        style: TextStyle(color: _kSecondary, fontSize: 14)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _hymns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => HymnTile(
                          hymn: _hymns[i],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => HymnViewerPage(hymn: _hymns[i]))),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BookChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _kSecondary,
              )),
        ),
      ),
    );
  }
}

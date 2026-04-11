// lib/spare_parts/pages/parts_search_page.dart
import 'package:flutter/material.dart';
import '../models/spare_parts_models.dart';
import '../services/spare_parts_service.dart';
import '../widgets/part_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PartsSearchPage extends StatefulWidget {
  final int userId;
  final String? initialCategory;
  const PartsSearchPage({super.key, required this.userId, this.initialCategory});
  @override
  State<PartsSearchPage> createState() => _PartsSearchPageState();
}

class _PartsSearchPageState extends State<PartsSearchPage> {
  final SparePartsService _service = SparePartsService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<SparePart> _parts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _search();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _page < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    setState(() { _isLoading = true; _page = 1; });
    final result = await _service.searchParts(
      query: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      category: _category,
      page: 1,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _parts = result.items;
          _lastPage = result.lastPage;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _page++;
    final result = await _service.searchParts(
      query: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      category: _category,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) _parts.addAll(result.items);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Search Parts', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Brake pads, oil filter...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20, color: _kPrimary),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _parts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.build_rounded, size: 48, color: _kSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _searchCtrl.text.isEmpty ? 'Search for spare parts' : 'No parts found',
                              style: const TextStyle(color: _kSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _parts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= _parts.length) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
                          }
                          return PartCard(part_: _parts[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

const Color _kBg = Color(0xFFFAFAFA);

/// Entry point for marketplace search (`IMPLEMENTATION_PLAN` Phase 6).
class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key, required this.currentUserId});

  final int currentUserId;

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  final TextEditingController _q = TextEditingController();
  final ShopRepository _repo = ShopRepository.instance;
  final List<String> _recentSearches = [];
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final r = await _repo.getCategories(includeChildren: false);
    if (!mounted) return;
    if (r.success) setState(() => _categories = r.categories);
  }

  void _submit([String? override]) {
    final query = (override ?? _q.text).trim();
    if (query.isEmpty) return;
    if (!_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
    }
    Navigator.pushNamed(
      context,
      '/shop/search-results',
      arguments: {'query': query, 'currentUserId': widget.currentUserId},
    );
  }

  void _removeRecent(String query) {
    setState(() => _recentSearches.remove(query));
  }

  void _clearAllRecent() {
    setState(() => _recentSearches.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Search Shop'),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search field
            TextField(
              controller: _q,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _q,
                  builder: (_, val, child) => val.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _q.clear(),
                        ),
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
                  borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Search'),
              ),
            ),

            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAllRecent,
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _recentSearches.map((q) {
                  return InputChip(
                    label: Text(
                      q,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _submit(q),
                    onDeleted: () => _removeRecent(q),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Popular categories
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Popular Categories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/shop/category',
                          arguments: {'categoryId': cat.id},
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

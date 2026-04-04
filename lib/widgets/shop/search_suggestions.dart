// lib/widgets/shop/search_suggestions.dart
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/shop_database.dart';
import '../../models/shop_models.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);

class SearchSuggestions extends StatefulWidget {
  final String query;
  final void Function(String query) onSelect;
  final VoidCallback? onClearHistory;

  const SearchSuggestions({
    super.key,
    required this.query,
    required this.onSelect,
    this.onClearHistory,
  });

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  final ShopDatabase _db = ShopDatabase.instance;
  List<String> _history = [];
  List<Product> _localResults = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SearchSuggestions old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _load();
  }

  Future<void> _load() async {
    if (widget.query.isEmpty) {
      final history = await _db.getSearchHistory(limit: 10);
      if (mounted) {
        setState(() {
          _history = history;
          _localResults = [];
        });
      }
    } else {
      final results = await _db.searchProducts(widget.query, limit: 5);
      if (mounted) {
        setState(() {
          _localResults = results;
          _history = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty && _history.isEmpty) return const SizedBox.shrink();
    if (widget.query.isNotEmpty && _localResults.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            if (widget.query.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    const Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSecondaryText,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onClearHistory != null)
                      GestureDetector(
                        onTap: widget.onClearHistory,
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12, color: _kTertiaryText),
                        ),
                      ),
                  ],
                ),
              ),
              ..._history.map((q) => ListTile(
                    dense: true,
                    leading: const HeroIcon(
                      HeroIcons.clock,
                      size: 18,
                      color: _kTertiaryText,
                    ),
                    title: Text(
                      q,
                      style: const TextStyle(fontSize: 14, color: _kPrimaryText),
                    ),
                    onTap: () => widget.onSelect(q),
                  )),
            ] else ...[
              ..._localResults.map((p) => ListTile(
                    dense: true,
                    leading: const HeroIcon(
                      HeroIcons.magnifyingGlass,
                      size: 18,
                      color: _kTertiaryText,
                    ),
                    title: Text(
                      p.title,
                      style: const TextStyle(fontSize: 14, color: _kPrimaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${p.currency} ${p.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                    ),
                    onTap: () => widget.onSelect(p.title),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// lib/katiba/pages/search_results_page.dart
import 'package:flutter/material.dart';
import '../models/katiba_models.dart';
import '../services/katiba_service.dart';
import '../widgets/article_card.dart';
import 'article_reader_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Article> _results = [];
  bool _loading = true;
  final _service = KatibaService();

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final result = await _service.searchArticles(widget.query);
    if (mounted) {
      setState(() {
        _results = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text('"${widget.query}"',
            style: const TextStyle(color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _results.isEmpty
              ? Center(child: Text('Hakuna matokeo ya "${widget.query}"',
                  style: const TextStyle(color: _kSecondary, fontSize: 14)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ArticleCard(
                      article: _results[i],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ArticleReaderPage(article: _results[i]))),
                    ),
                  ),
                ),
    );
  }
}

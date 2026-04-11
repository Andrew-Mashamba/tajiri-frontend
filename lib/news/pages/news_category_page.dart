// lib/news/pages/news_category_page.dart
import 'package:flutter/material.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import 'article_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NewsCategoryPage extends StatefulWidget {
  final NewsCategory category;
  final int userId;
  const NewsCategoryPage({super.key, required this.category, required this.userId});
  @override
  State<NewsCategoryPage> createState() => _NewsCategoryPageState();
}

class _NewsCategoryPageState extends State<NewsCategoryPage> {
  final NewsService _service = NewsService();
  List<NewsArticle> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getArticles(category: widget.category);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _articles = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('${widget.category.displayName} / ${widget.category.subtitle}'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.category.icon, size: 48, color: _kSecondary),
                      const SizedBox(height: 8),
                      const Text('Hakuna habari kwa sasa', style: TextStyle(color: _kSecondary, fontSize: 14)),
                      const Text('No articles in this category', style: TextStyle(color: _kSecondary, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final article = _articles[i];
                      return NewsCard(
                        article: article,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArticlePage(articleId: article.id, userId: widget.userId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

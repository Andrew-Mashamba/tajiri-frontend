// lib/news/pages/news_home_page.dart
import 'package:flutter/material.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import 'article_page.dart';
import 'news_category_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NewsHomePage extends StatefulWidget {
  final int userId;
  const NewsHomePage({super.key, required this.userId});
  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final NewsService _service = NewsService();

  List<NewsArticle> _topStories = [];
  List<NewsArticle> _latest = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getTopStories(),
      _service.getArticles(perPage: 20),
    ]);
    if (mounted) {
      final topResult = results[0];
      final latestResult = results[1];
      setState(() {
        _isLoading = false;
        if (topResult.success) _topStories = topResult.items;
        if (latestResult.success) _latest = latestResult.items;
      });
    }
  }

  void _openArticle(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticlePage(articleId: article.id, userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Tajiri Habari', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Habari za Tanzania na dunia — Politics, Business, Sports, Entertainment.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categories
          const Text('Makundi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Categories', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: NewsCategory.values.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsCategoryPage(category: cat, userId: widget.userId),
                      ),
                    ),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon, size: 24, color: _kPrimary),
                          const SizedBox(height: 4),
                          Text(
                            cat.displayName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Top Stories
          if (_topStories.isNotEmpty) ...[
            const Text('Habari Kuu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('Top Stories', style: TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 10),
            // Featured story (first one, large)
            _buildFeaturedStory(_topStories.first),
            const SizedBox(height: 10),
            ..._topStories.skip(1).take(3).map((article) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NewsCard(article: article, onTap: () => _openArticle(article)),
                )),
            const SizedBox(height: 12),
          ],

          // Latest
          const Text('Habari Mpya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Latest News', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          ..._latest.map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NewsCard(article: article, onTap: () => _openArticle(article)),
              )),
          if (_latest.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.newspaper_outlined, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna habari kwa sasa', style: TextStyle(color: _kSecondary, fontSize: 14)),
                  Text('No news articles yet', style: TextStyle(color: _kSecondary, fontSize: 12)),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedStory(NewsArticle article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: article.imageUrl != null
                    ? DecorationImage(image: NetworkImage(article.imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: article.imageUrl == null
                  ? Center(child: Icon(article.category.icon, size: 48, color: _kSecondary))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.category.displayName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article.source} · ${article.readTimeMinutes} dak kusoma',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

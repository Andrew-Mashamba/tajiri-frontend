// lib/news/pages/article_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ArticlePage extends StatefulWidget {
  final int articleId;
  final int userId;
  const ArticlePage({super.key, required this.articleId, required this.userId});
  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final NewsService _service = NewsService();
  NewsArticle? _article;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _service.getArticle(widget.articleId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) _article = result.data;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Makala'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        actions: [
          if (_article != null) ...[
            IconButton(
              onPressed: () {
                _service.saveArticle(articleId: widget.articleId, userId: widget.userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Makala imehifadhiwa')),
                  );
                }
              },
              icon: const Icon(Icons.bookmark_border_rounded),
            ),
            IconButton(
              onPressed: () {
                final title = _article!.title;
                final source = _article!.source;
                SharePlus.instance.share(
                  ShareParams(text: '$title\n\nSource: $source\n\nShared via Tajiri'),
                );
              },
              icon: const Icon(Icons.share_rounded),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _article == null
              ? const Center(child: Text('Makala haipatikani', style: TextStyle(color: _kSecondary)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final article = _article!;
    return ListView(
      children: [
        // Hero image
        if (article.imageUrl != null)
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              image: DecorationImage(image: NetworkImage(article.imageUrl!), fit: BoxFit.cover),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${article.category.displayName} / ${article.category.subtitle}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                article.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary, height: 1.3),
              ),
              const SizedBox(height: 8),

              // Meta
              Row(
                children: [
                  Text(article.source, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  if (article.author != null) ...[
                    const Text(' · ', style: TextStyle(color: _kSecondary)),
                    Text(article.author!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(article.publishedAt)} · ${article.readTimeMinutes} dak kusoma',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(height: 16),

              // Summary
              if (article.summary.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(left: BorderSide(color: _kPrimary, width: 3)),
                  ),
                  child: Text(
                    article.summary,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimary, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Content
              Text(
                article.content,
                style: const TextStyle(fontSize: 15, color: _kPrimary, height: 1.7),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

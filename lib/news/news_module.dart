// lib/news/news_module.dart
import 'package:flutter/material.dart';
import 'pages/news_home_page.dart';

class NewsModule extends StatelessWidget {
  final int userId;
  const NewsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return NewsHomePage(userId: userId);
  }
}

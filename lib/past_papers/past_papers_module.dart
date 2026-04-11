// lib/past_papers/past_papers_module.dart
import 'package:flutter/material.dart';
import 'pages/past_papers_home_page.dart';

class PastPapersModule extends StatefulWidget {
  final int userId;
  const PastPapersModule({super.key, required this.userId});
  @override
  State<PastPapersModule> createState() => _PastPapersModuleState();
}

class _PastPapersModuleState extends State<PastPapersModule> {
  @override
  Widget build(BuildContext context) {
    return PastPapersHomePage(userId: widget.userId);
  }
}

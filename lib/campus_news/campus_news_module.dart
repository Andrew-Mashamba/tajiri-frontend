// lib/campus_news/campus_news_module.dart
import 'package:flutter/material.dart';
import 'pages/campus_news_home_page.dart';

class CampusNewsModule extends StatefulWidget {
  final int userId;
  const CampusNewsModule({super.key, required this.userId});
  @override
  State<CampusNewsModule> createState() => _CampusNewsModuleState();
}

class _CampusNewsModuleState extends State<CampusNewsModule> {
  @override
  Widget build(BuildContext context) {
    return CampusNewsHomePage(userId: widget.userId);
  }
}

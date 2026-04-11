// lib/jumuiya/jumuiya_module.dart
import 'package:flutter/material.dart';
import 'pages/jumuiya_home_page.dart';

class JumuiyaModule extends StatelessWidget {
  final int userId;
  const JumuiyaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return JumuiyaHomePage(userId: userId);
  }
}

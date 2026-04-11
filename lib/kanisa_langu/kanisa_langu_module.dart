// lib/kanisa_langu/kanisa_langu_module.dart
import 'package:flutter/material.dart';
import 'pages/kanisa_langu_home_page.dart';

class KanisaLanguModule extends StatelessWidget {
  final int userId;
  const KanisaLanguModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return KanisaLanguHomePage(userId: userId);
  }
}

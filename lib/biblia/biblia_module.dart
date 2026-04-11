// lib/biblia/biblia_module.dart
import 'package:flutter/material.dart';
import 'pages/biblia_home_page.dart';

class BibliaModule extends StatelessWidget {
  final int userId;
  const BibliaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BibliaHomePage(userId: userId);
  }
}

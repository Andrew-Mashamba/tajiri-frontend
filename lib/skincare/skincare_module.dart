// lib/skincare/skincare_module.dart
import 'package:flutter/material.dart';
import 'pages/skincare_home_page.dart';

class SkincareModule extends StatelessWidget {
  final int userId;
  const SkincareModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SkincareHomePage(userId: userId);
  }
}

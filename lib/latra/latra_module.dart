// lib/latra/latra_module.dart
import 'package:flutter/material.dart';
import 'pages/latra_home_page.dart';

class LatraModule extends StatelessWidget {
  final int userId;
  const LatraModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return LatraHomePage(userId: userId);
  }
}

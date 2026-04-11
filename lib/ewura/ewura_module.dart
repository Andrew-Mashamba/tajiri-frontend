// lib/ewura/ewura_module.dart
import 'package:flutter/material.dart';
import 'pages/ewura_home_page.dart';

class EwuraModule extends StatelessWidget {
  final int userId;
  const EwuraModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return EwuraHomePage(userId: userId);
  }
}

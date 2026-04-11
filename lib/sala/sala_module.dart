// lib/sala/sala_module.dart
import 'package:flutter/material.dart';
import 'pages/sala_home_page.dart';

class SalaModule extends StatelessWidget {
  final int userId;
  const SalaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SalaHomePage(userId: userId);
  }
}

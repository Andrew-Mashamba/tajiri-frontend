// lib/necta/necta_module.dart
import 'package:flutter/material.dart';
import 'pages/necta_home_page.dart';

class NectaModule extends StatelessWidget {
  final int userId;
  const NectaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return NectaHomePage(userId: userId);
  }
}

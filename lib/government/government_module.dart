// lib/government/government_module.dart
import 'package:flutter/material.dart';
import 'pages/government_home_page.dart';

class GovernmentModule extends StatelessWidget {
  final int userId;
  const GovernmentModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GovernmentHomePage(userId: userId);
  }
}

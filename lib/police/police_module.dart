// lib/police/police_module.dart
import 'package:flutter/material.dart';
import 'pages/police_home_page.dart';

class PoliceModule extends StatelessWidget {
  final int userId;
  const PoliceModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return PoliceHomePage(userId: userId);
  }
}

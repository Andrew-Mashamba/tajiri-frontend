// lib/faith/faith_module.dart
import 'package:flutter/material.dart';
import 'pages/faith_home_page.dart';

class FaithModule extends StatelessWidget {
  final int userId;
  const FaithModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FaithHomePage(userId: userId);
  }
}

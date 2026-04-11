// lib/tira/tira_module.dart
import 'package:flutter/material.dart';
import 'pages/tira_home_page.dart';

class TiraModule extends StatelessWidget {
  final int userId;
  const TiraModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TiraHomePage(userId: userId);
  }
}

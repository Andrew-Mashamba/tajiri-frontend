// lib/nightlife/nightlife_module.dart
import 'package:flutter/material.dart';
import 'pages/nightlife_home_page.dart';

class NightlifeModule extends StatelessWidget {
  final int userId;
  const NightlifeModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return NightlifeHomePage(userId: userId);
  }
}

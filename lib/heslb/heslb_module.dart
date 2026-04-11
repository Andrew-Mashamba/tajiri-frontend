// lib/heslb/heslb_module.dart
import 'package:flutter/material.dart';
import 'pages/heslb_home_page.dart';

class HeslbModule extends StatelessWidget {
  final int userId;
  const HeslbModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return HeslbHomePage(userId: userId);
  }
}

// lib/my_pregnancy/my_pregnancy_module.dart
import 'package:flutter/material.dart';
import 'pages/pregnancy_home_page.dart';

class MyPregnancyModule extends StatelessWidget {
  final int userId;
  const MyPregnancyModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return PregnancyHomePage(userId: userId);
  }
}

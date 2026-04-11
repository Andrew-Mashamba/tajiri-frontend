// lib/lawyer/lawyer_module.dart
import 'package:flutter/material.dart';
import 'pages/lawyer_home_page.dart';

class LawyerModule extends StatelessWidget {
  final int userId;
  const LawyerModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return LawyerHomePage(userId: userId);
  }
}

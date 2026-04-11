// lib/fitness/fitness_module.dart
import 'package:flutter/material.dart';
import 'pages/fitness_home_page.dart';

class FitnessModule extends StatelessWidget {
  final int userId;
  const FitnessModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FitnessHomePage(userId: userId);
  }
}

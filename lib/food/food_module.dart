// lib/food/food_module.dart
import 'package:flutter/material.dart';
import 'pages/food_home_page.dart';

class FoodModule extends StatelessWidget {
  final int userId;
  const FoodModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FoodHomePage(userId: userId);
  }
}

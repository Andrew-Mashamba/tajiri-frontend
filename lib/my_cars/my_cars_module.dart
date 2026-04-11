// lib/my_cars/my_cars_module.dart
import 'package:flutter/material.dart';
import 'pages/my_cars_home_page.dart';

class MyCarsModule extends StatelessWidget {
  final int userId;
  const MyCarsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyCarsHomePage(userId: userId);
  }
}

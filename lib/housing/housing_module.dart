// lib/housing/housing_module.dart
import 'package:flutter/material.dart';
import 'pages/housing_home_page.dart';

class HousingModule extends StatelessWidget {
  final int userId;
  const HousingModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return HousingHomePage(userId: userId);
  }
}

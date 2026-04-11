// lib/sell_car/sell_car_module.dart
import 'package:flutter/material.dart';
import 'pages/sell_car_home_page.dart';

class SellCarModule extends StatelessWidget {
  final int userId;
  const SellCarModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SellCarHomePage(userId: userId);
  }
}

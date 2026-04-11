// lib/buy_car/buy_car_module.dart
import 'package:flutter/material.dart';
import 'pages/buy_car_home_page.dart';

class BuyCarModule extends StatelessWidget {
  final int userId;
  const BuyCarModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BuyCarHomePage(userId: userId);
  }
}

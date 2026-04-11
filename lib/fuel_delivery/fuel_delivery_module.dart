// lib/fuel_delivery/fuel_delivery_module.dart
import 'package:flutter/material.dart';
import 'pages/fuel_delivery_home_page.dart';

class FuelDeliveryModule extends StatelessWidget {
  final int userId;
  const FuelDeliveryModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FuelDeliveryHomePage(userId: userId);
  }
}

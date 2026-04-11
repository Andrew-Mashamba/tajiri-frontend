// lib/vehicle/vehicle_module.dart
import 'package:flutter/material.dart';
import 'pages/vehicle_home_page.dart';

class VehicleModule extends StatelessWidget {
  final int userId;
  const VehicleModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return VehicleHomePage(userId: userId);
  }
}

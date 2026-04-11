// lib/car_insurance/car_insurance_module.dart
import 'package:flutter/material.dart';
import 'pages/car_insurance_home_page.dart';

class CarInsuranceModule extends StatelessWidget {
  final int userId;
  const CarInsuranceModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CarInsuranceHomePage(userId: userId);
  }
}

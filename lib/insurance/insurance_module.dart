// lib/insurance/insurance_module.dart
import 'package:flutter/material.dart';
import 'pages/insurance_home_page.dart';

class InsuranceModule extends StatelessWidget {
  final int userId;
  const InsuranceModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return InsuranceHomePage(userId: userId);
  }
}

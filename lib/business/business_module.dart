// lib/business/business_module.dart
// Entry point for the "Biashara Yangu" (My Business) module.
import 'package:flutter/material.dart';
import 'pages/business_home_page.dart';

class BusinessModule extends StatelessWidget {
  final int userId;
  const BusinessModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BusinessHomePage(userId: userId);
  }
}

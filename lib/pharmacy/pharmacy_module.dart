// lib/pharmacy/pharmacy_module.dart
import 'package:flutter/material.dart';
import 'pages/pharmacy_home_page.dart';

class PharmacyModule extends StatelessWidget {
  final int userId;
  const PharmacyModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return PharmacyHomePage(userId: userId);
  }
}

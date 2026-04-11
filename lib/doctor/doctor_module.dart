// lib/doctor/doctor_module.dart
import 'package:flutter/material.dart';
import 'pages/doctor_home_page.dart';

class DoctorModule extends StatelessWidget {
  final int userId;
  const DoctorModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return DoctorHomePage(userId: userId);
  }
}

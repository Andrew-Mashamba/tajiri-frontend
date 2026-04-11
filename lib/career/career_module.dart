// lib/career/career_module.dart
import 'package:flutter/material.dart';
import 'pages/career_home_page.dart';

class CareerModule extends StatefulWidget {
  final int userId;
  const CareerModule({super.key, required this.userId});
  @override
  State<CareerModule> createState() => _CareerModuleState();
}

class _CareerModuleState extends State<CareerModule> {
  @override
  Widget build(BuildContext context) {
    return CareerHomePage(userId: widget.userId);
  }
}

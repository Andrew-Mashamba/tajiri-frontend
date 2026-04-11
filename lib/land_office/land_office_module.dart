// lib/land_office/land_office_module.dart
import 'package:flutter/material.dart';
import 'pages/land_home_page.dart';

class LandOfficeModule extends StatefulWidget {
  final int userId;
  const LandOfficeModule({super.key, required this.userId});
  @override
  State<LandOfficeModule> createState() => _LandOfficeModuleState();
}

class _LandOfficeModuleState extends State<LandOfficeModule> {
  @override
  Widget build(BuildContext context) {
    return LandHomePage(userId: widget.userId);
  }
}

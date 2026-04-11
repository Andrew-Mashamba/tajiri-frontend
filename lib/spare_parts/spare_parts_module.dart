// lib/spare_parts/spare_parts_module.dart
import 'package:flutter/material.dart';
import 'pages/spare_parts_home_page.dart';

class SparePartsModule extends StatefulWidget {
  final int userId;
  const SparePartsModule({super.key, required this.userId});
  @override
  State<SparePartsModule> createState() => _SparePartsModuleState();
}

class _SparePartsModuleState extends State<SparePartsModule> {
  @override
  Widget build(BuildContext context) {
    return SparePartsHomePage(userId: widget.userId);
  }
}

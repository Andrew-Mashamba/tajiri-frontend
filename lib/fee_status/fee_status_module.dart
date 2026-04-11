// lib/fee_status/fee_status_module.dart
import 'package:flutter/material.dart';
import 'pages/fee_status_home_page.dart';

class FeeStatusModule extends StatefulWidget {
  final int userId;
  const FeeStatusModule({super.key, required this.userId});
  @override
  State<FeeStatusModule> createState() => _FeeStatusModuleState();
}

class _FeeStatusModuleState extends State<FeeStatusModule> {
  @override
  Widget build(BuildContext context) {
    return FeeStatusHomePage(userId: widget.userId);
  }
}

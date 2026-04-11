// lib/passport/passport_module.dart
import 'package:flutter/material.dart';
import 'pages/passport_home_page.dart';

class PassportModule extends StatefulWidget {
  final int userId;
  const PassportModule({super.key, required this.userId});
  @override
  State<PassportModule> createState() => _PassportModuleState();
}

class _PassportModuleState extends State<PassportModule> {
  @override
  Widget build(BuildContext context) {
    return PassportHomePage(userId: widget.userId);
  }
}

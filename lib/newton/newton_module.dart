// lib/newton/newton_module.dart
import 'package:flutter/material.dart';
import 'pages/newton_home_page.dart';

class NewtonModule extends StatefulWidget {
  final int userId;
  final String? prefillText;
  const NewtonModule({super.key, required this.userId, this.prefillText});
  @override
  State<NewtonModule> createState() => _NewtonModuleState();
}

class _NewtonModuleState extends State<NewtonModule> {
  @override
  Widget build(BuildContext context) {
    return NewtonHomePage(
      userId: widget.userId,
      prefillText: widget.prefillText,
    );
  }
}

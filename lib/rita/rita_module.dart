// lib/rita/rita_module.dart
import 'package:flutter/material.dart';
import 'pages/rita_home_page.dart';

class RitaModule extends StatefulWidget {
  final int userId;
  const RitaModule({super.key, required this.userId});

  @override
  State<RitaModule> createState() => _RitaModuleState();
}

class _RitaModuleState extends State<RitaModule> {
  @override
  Widget build(BuildContext context) {
    return RitaHomePage(userId: widget.userId);
  }
}

// lib/brela/brela_module.dart
import 'package:flutter/material.dart';
import 'pages/brela_home_page.dart';

class BrelaModule extends StatefulWidget {
  final int userId;
  const BrelaModule({super.key, required this.userId});
  @override
  State<BrelaModule> createState() => _BrelaModuleState();
}

class _BrelaModuleState extends State<BrelaModule> {
  @override
  Widget build(BuildContext context) {
    return BrelaHomePage(userId: widget.userId);
  }
}

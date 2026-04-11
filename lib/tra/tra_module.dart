// lib/tra/tra_module.dart
import 'package:flutter/material.dart';
import 'pages/tra_home_page.dart';

class TraModule extends StatefulWidget {
  final int userId;
  const TraModule({super.key, required this.userId});
  @override
  State<TraModule> createState() => _TraModuleState();
}

class _TraModuleState extends State<TraModule> {
  @override
  Widget build(BuildContext context) {
    return TraHomePage(userId: widget.userId);
  }
}

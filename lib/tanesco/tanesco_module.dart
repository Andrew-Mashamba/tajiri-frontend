// lib/tanesco/tanesco_module.dart
import 'package:flutter/material.dart';
import 'pages/tanesco_home_page.dart';

class TanescoModule extends StatefulWidget {
  final int userId;
  const TanescoModule({super.key, required this.userId});
  @override
  State<TanescoModule> createState() => _TanescoModuleState();
}

class _TanescoModuleState extends State<TanescoModule> {
  @override
  Widget build(BuildContext context) => TanescoHomePage(userId: widget.userId);
}

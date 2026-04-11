// lib/results/results_module.dart
import 'package:flutter/material.dart';
import 'pages/results_home_page.dart';

class ResultsModule extends StatefulWidget {
  final int userId;
  const ResultsModule({super.key, required this.userId});
  @override
  State<ResultsModule> createState() => _ResultsModuleState();
}

class _ResultsModuleState extends State<ResultsModule> {
  @override
  Widget build(BuildContext context) {
    return ResultsHomePage(userId: widget.userId);
  }
}

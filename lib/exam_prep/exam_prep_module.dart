// lib/exam_prep/exam_prep_module.dart
import 'package:flutter/material.dart';
import 'pages/exam_prep_home_page.dart';

class ExamPrepModule extends StatefulWidget {
  final int userId;
  const ExamPrepModule({super.key, required this.userId});
  @override
  State<ExamPrepModule> createState() => _ExamPrepModuleState();
}

class _ExamPrepModuleState extends State<ExamPrepModule> {
  @override
  Widget build(BuildContext context) {
    return ExamPrepHomePage(userId: widget.userId);
  }
}

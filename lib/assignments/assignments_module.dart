// lib/assignments/assignments_module.dart
import 'package:flutter/material.dart';
import 'pages/assignments_home_page.dart';

class AssignmentsModule extends StatefulWidget {
  final int userId;
  const AssignmentsModule({super.key, required this.userId});
  @override
  State<AssignmentsModule> createState() => _AssignmentsModuleState();
}

class _AssignmentsModuleState extends State<AssignmentsModule> {
  @override
  Widget build(BuildContext context) {
    return AssignmentsHomePage(userId: widget.userId);
  }
}

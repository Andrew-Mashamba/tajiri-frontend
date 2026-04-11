// lib/timetable/timetable_module.dart
import 'package:flutter/material.dart';
import 'pages/timetable_home_page.dart';

class TimetableModule extends StatefulWidget {
  final int userId;
  const TimetableModule({super.key, required this.userId});
  @override
  State<TimetableModule> createState() => _TimetableModuleState();
}

class _TimetableModuleState extends State<TimetableModule> {
  @override
  Widget build(BuildContext context) {
    return TimetableHomePage(userId: widget.userId);
  }
}

// lib/calendar/calendar_module.dart
import 'package:flutter/material.dart';
import 'pages/calendar_home_page.dart';

class CalendarModule extends StatelessWidget {
  final int userId;
  const CalendarModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CalendarHomePage(userId: userId);
  }
}

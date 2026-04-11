// lib/alerts/alerts_module.dart
import 'package:flutter/material.dart';
import 'pages/alerts_home_page.dart';

class AlertsModule extends StatelessWidget {
  final int userId;
  const AlertsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return AlertsHomePage(userId: userId);
  }
}

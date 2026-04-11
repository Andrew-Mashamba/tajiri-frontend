// lib/traffic/traffic_module.dart
import 'package:flutter/material.dart';
import 'pages/traffic_home_page.dart';

class TrafficModule extends StatelessWidget {
  final int userId;
  const TrafficModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TrafficHomePage(userId: userId);
  }
}

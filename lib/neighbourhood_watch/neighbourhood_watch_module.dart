// lib/neighbourhood_watch/neighbourhood_watch_module.dart
import 'package:flutter/material.dart';
import 'pages/neighbourhood_watch_home_page.dart';

class NeighbourhoodWatchModule extends StatelessWidget {
  final int userId;
  const NeighbourhoodWatchModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return NeighbourhoodWatchHomePage(userId: userId);
  }
}

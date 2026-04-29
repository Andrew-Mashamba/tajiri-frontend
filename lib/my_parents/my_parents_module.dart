// lib/my_parents/my_parents_module.dart
import 'package:flutter/material.dart';
import 'pages/my_parents_home_page.dart';

class MyParentsModule extends StatelessWidget {
  final int userId;
  const MyParentsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyParentsHomePage(userId: userId);
  }
}

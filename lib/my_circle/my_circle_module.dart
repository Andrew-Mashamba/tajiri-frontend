// lib/my_circle/my_circle_module.dart
import 'package:flutter/material.dart';
import 'pages/my_circle_home_page.dart';

class MyCircleModule extends StatelessWidget {
  final int userId;
  const MyCircleModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyCircleHomePage(userId: userId);
  }
}

// lib/my_baby/my_baby_module.dart
import 'package:flutter/material.dart';
import 'pages/my_baby_home_page.dart';

class MyBabyModule extends StatelessWidget {
  final int userId;
  const MyBabyModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyBabyHomePage(userId: userId);
  }
}

// lib/my_faith/my_faith_module.dart
import 'package:flutter/material.dart';
import 'pages/my_faith_home_page.dart';

class MyFaithModule extends StatelessWidget {
  final int userId;
  const MyFaithModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyFaithHomePage(userId: userId);
  }
}

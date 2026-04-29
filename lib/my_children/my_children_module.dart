// lib/my_children/my_children_module.dart
import 'package:flutter/material.dart';
import 'pages/my_children_home_page.dart';

class MyChildrenModule extends StatelessWidget {
  final int userId;
  const MyChildrenModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyChildrenHomePage(userId: userId);
  }
}

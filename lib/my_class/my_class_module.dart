// lib/my_class/my_class_module.dart
import 'package:flutter/material.dart';
import 'pages/my_class_home_page.dart';

class MyClassModule extends StatefulWidget {
  final int userId;
  const MyClassModule({super.key, required this.userId});
  @override
  State<MyClassModule> createState() => _MyClassModuleState();
}

class _MyClassModuleState extends State<MyClassModule> {
  @override
  Widget build(BuildContext context) {
    return MyClassHomePage(userId: widget.userId);
  }
}

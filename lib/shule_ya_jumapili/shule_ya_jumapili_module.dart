// lib/shule_ya_jumapili/shule_ya_jumapili_module.dart
import 'package:flutter/material.dart';
import 'pages/shule_ya_jumapili_home_page.dart';

class ShuleYaJumapiliModule extends StatelessWidget {
  final int userId;
  const ShuleYaJumapiliModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ShuleYaJumapiliHomePage(userId: userId);
  }
}

// lib/huduma/huduma_module.dart
import 'package:flutter/material.dart';
import 'pages/huduma_home_page.dart';

class HudumaModule extends StatelessWidget {
  final int userId;
  const HudumaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return HudumaHomePage(userId: userId);
  }
}

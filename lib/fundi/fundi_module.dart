// lib/fundi/fundi_module.dart
import 'package:flutter/material.dart';
import 'pages/fundi_home_page.dart';

class FundiModule extends StatelessWidget {
  final int userId;
  const FundiModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FundiHomePage(userId: userId);
  }
}

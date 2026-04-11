// lib/fungu_la_kumi/fungu_la_kumi_module.dart
import 'package:flutter/material.dart';
import 'pages/fungu_la_kumi_home_page.dart';

class FunguLaKumiModule extends StatelessWidget {
  final int userId;
  const FunguLaKumiModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FunguLaKumiHomePage(userId: userId);
  }
}

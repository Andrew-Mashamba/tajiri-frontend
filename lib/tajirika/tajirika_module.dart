import 'package:flutter/material.dart';
import 'pages/tajirika_home_page.dart';

class TajirikaModule extends StatelessWidget {
  final int? userId;

  const TajirikaModule({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return const TajirikaHomePage();
  }
}

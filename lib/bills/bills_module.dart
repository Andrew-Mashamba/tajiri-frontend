// lib/bills/bills_module.dart
import 'package:flutter/material.dart';
import 'pages/bills_home_page.dart';

class BillsModule extends StatelessWidget {
  final int userId;
  const BillsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BillsHomePage(userId: userId);
  }
}

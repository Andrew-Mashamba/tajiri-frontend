// lib/transport/transport_module.dart
import 'package:flutter/material.dart';
import 'pages/transport_home_page.dart';

class TransportModule extends StatelessWidget {
  final int userId;
  const TransportModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TransportHomePage(userId: userId);
  }
}

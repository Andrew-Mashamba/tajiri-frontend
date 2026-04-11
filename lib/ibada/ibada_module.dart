// lib/ibada/ibada_module.dart
import 'package:flutter/material.dart';
import 'pages/ibada_home_page.dart';

class IbadaModule extends StatelessWidget {
  final int userId;
  const IbadaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return IbadaHomePage(userId: userId);
  }
}

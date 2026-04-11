// lib/tafuta_kanisa/tafuta_kanisa_module.dart
import 'package:flutter/material.dart';
import 'pages/tafuta_kanisa_home_page.dart';

class TafutaKanisaModule extends StatelessWidget {
  final int userId;
  const TafutaKanisaModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TafutaKanisaHomePage(userId: userId);
  }
}

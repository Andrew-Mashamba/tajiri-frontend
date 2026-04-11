// lib/hair_nails/hair_nails_module.dart
import 'package:flutter/material.dart';
import 'pages/hair_nails_home_page.dart';

class HairNailsModule extends StatelessWidget {
  final int userId;
  const HairNailsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return HairNailsHomePage(userId: userId);
  }
}

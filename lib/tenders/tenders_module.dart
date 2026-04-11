// Tenders (Zabuni) Module — entry point
// Returns TendersHomePage for integration into TAJIRI app
import 'package:flutter/material.dart';
import 'pages/tenders_home_page.dart';

class TendersModule extends StatelessWidget {
  final int userId;
  const TendersModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TendersHomePage(userId: userId);
  }
}

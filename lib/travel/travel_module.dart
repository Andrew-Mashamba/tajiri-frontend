import 'package:flutter/material.dart';
import 'pages/travel_home_page.dart';

class TravelModule extends StatelessWidget {
  final int userId;
  const TravelModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) => TravelHomePage(userId: userId);
}

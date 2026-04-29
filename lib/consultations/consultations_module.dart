import 'package:flutter/material.dart';
import 'pages/health_profile_page.dart';

class ConsultationsModule extends StatelessWidget {
  final int userId;
  const ConsultationsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return HealthProfilePage(userId: userId);
  }
}

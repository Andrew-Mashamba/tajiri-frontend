// lib/service_garage/service_garage_module.dart
import 'package:flutter/material.dart';
import 'pages/service_garage_home_page.dart';

class ServiceGarageModule extends StatelessWidget {
  final int userId;
  const ServiceGarageModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ServiceGarageHomePage(userId: userId);
  }
}

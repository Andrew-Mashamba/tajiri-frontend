// lib/ambulance/ambulance_module.dart
import 'package:flutter/material.dart';
import 'pages/emergency_home_page.dart';

class AmbulanceModule extends StatefulWidget {
  final int userId;
  const AmbulanceModule({super.key, required this.userId});
  @override
  State<AmbulanceModule> createState() => _AmbulanceModuleState();
}

class _AmbulanceModuleState extends State<AmbulanceModule> {
  @override
  Widget build(BuildContext context) {
    return EmergencyHomePage(userId: widget.userId);
  }
}

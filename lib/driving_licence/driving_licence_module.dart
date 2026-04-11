// lib/driving_licence/driving_licence_module.dart
import 'package:flutter/material.dart';
import 'pages/licence_home_page.dart';

class DrivingLicenceModule extends StatefulWidget {
  final int userId;
  const DrivingLicenceModule({super.key, required this.userId});
  @override
  State<DrivingLicenceModule> createState() => _DrivingLicenceModuleState();
}

class _DrivingLicenceModuleState extends State<DrivingLicenceModule> {
  @override
  Widget build(BuildContext context) {
    return LicenceHomePage(userId: widget.userId);
  }
}

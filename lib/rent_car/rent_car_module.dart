// lib/rent_car/rent_car_module.dart
import 'package:flutter/material.dart';
import 'pages/rent_car_home_page.dart';

class RentCarModule extends StatefulWidget {
  final int userId;
  const RentCarModule({super.key, required this.userId});
  @override
  State<RentCarModule> createState() => _RentCarModuleState();
}

class _RentCarModuleState extends State<RentCarModule> {
  @override
  Widget build(BuildContext context) {
    return RentCarHomePage(userId: widget.userId);
  }
}

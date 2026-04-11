// lib/nhif/nhif_module.dart
import 'package:flutter/material.dart';
import 'pages/nhif_home_page.dart';

class NhifModule extends StatefulWidget {
  final int userId;
  const NhifModule({super.key, required this.userId});
  @override
  State<NhifModule> createState() => _NhifModuleState();
}

class _NhifModuleState extends State<NhifModule> {
  @override
  Widget build(BuildContext context) => NhifHomePage(userId: widget.userId);
}

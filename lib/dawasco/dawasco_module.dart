// lib/dawasco/dawasco_module.dart
import 'package:flutter/material.dart';
import 'pages/dawasco_home_page.dart';

class DawascoModule extends StatefulWidget {
  final int userId;
  const DawascoModule({super.key, required this.userId});
  @override
  State<DawascoModule> createState() => _DawascoModuleState();
}

class _DawascoModuleState extends State<DawascoModule> {
  @override
  Widget build(BuildContext context) => DawascoHomePage(userId: widget.userId);
}

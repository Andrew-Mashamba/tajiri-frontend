// lib/nssf/nssf_module.dart
import 'package:flutter/material.dart';
import 'pages/nssf_home_page.dart';

class NssfModule extends StatefulWidget {
  final int userId;
  const NssfModule({super.key, required this.userId});
  @override
  State<NssfModule> createState() => _NssfModuleState();
}

class _NssfModuleState extends State<NssfModule> {
  @override
  Widget build(BuildContext context) => NssfHomePage(userId: widget.userId);
}

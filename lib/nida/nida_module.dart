// lib/nida/nida_module.dart
import 'package:flutter/material.dart';
import 'pages/nida_home_page.dart';

class NidaModule extends StatefulWidget {
  final int userId;
  const NidaModule({super.key, required this.userId});

  @override
  State<NidaModule> createState() => _NidaModuleState();
}

class _NidaModuleState extends State<NidaModule> {
  @override
  Widget build(BuildContext context) {
    return NidaHomePage(userId: widget.userId);
  }
}

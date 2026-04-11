// lib/legal_gpt/legal_gpt_module.dart
import 'package:flutter/material.dart';
import 'pages/legal_gpt_home_page.dart';

class LegalGptModule extends StatefulWidget {
  final int userId;
  const LegalGptModule({super.key, required this.userId});

  @override
  State<LegalGptModule> createState() => _LegalGptModuleState();
}

class _LegalGptModuleState extends State<LegalGptModule> {
  @override
  Widget build(BuildContext context) {
    return LegalGptHomePage(userId: widget.userId);
  }
}

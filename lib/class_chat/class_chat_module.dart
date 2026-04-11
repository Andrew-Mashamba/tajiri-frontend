// lib/class_chat/class_chat_module.dart
import 'package:flutter/material.dart';
import 'pages/class_chat_home_page.dart';

class ClassChatModule extends StatefulWidget {
  final int userId;
  const ClassChatModule({super.key, required this.userId});
  @override
  State<ClassChatModule> createState() => _ClassChatModuleState();
}

class _ClassChatModuleState extends State<ClassChatModule> {
  @override
  Widget build(BuildContext context) {
    return ClassChatHomePage(userId: widget.userId);
  }
}

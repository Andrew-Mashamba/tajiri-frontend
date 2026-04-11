// lib/class_notes/class_notes_module.dart
import 'package:flutter/material.dart';
import 'pages/class_notes_home_page.dart';

class ClassNotesModule extends StatefulWidget {
  final int userId;
  const ClassNotesModule({super.key, required this.userId});
  @override
  State<ClassNotesModule> createState() => _ClassNotesModuleState();
}

class _ClassNotesModuleState extends State<ClassNotesModule> {
  @override
  Widget build(BuildContext context) {
    return ClassNotesHomePage(userId: widget.userId);
  }
}

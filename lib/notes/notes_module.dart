// lib/notes/notes_module.dart
import 'package:flutter/material.dart';
import 'pages/notes_home_page.dart';

class NotesModule extends StatelessWidget {
  final int userId;
  const NotesModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return NotesHomePage(userId: userId);
  }
}

// lib/library/library_module.dart
import 'package:flutter/material.dart';
import 'pages/library_home_page.dart';

class LibraryModule extends StatefulWidget {
  final int userId;
  const LibraryModule({super.key, required this.userId});
  @override
  State<LibraryModule> createState() => _LibraryModuleState();
}

class _LibraryModuleState extends State<LibraryModule> {
  @override
  Widget build(BuildContext context) {
    return LibraryHomePage(userId: widget.userId);
  }
}

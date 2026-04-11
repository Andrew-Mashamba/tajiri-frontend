// lib/study_groups/study_groups_module.dart
import 'package:flutter/material.dart';
import 'pages/study_groups_home_page.dart';

class StudyGroupsModule extends StatefulWidget {
  final int userId;
  const StudyGroupsModule({super.key, required this.userId});
  @override
  State<StudyGroupsModule> createState() => _StudyGroupsModuleState();
}

class _StudyGroupsModuleState extends State<StudyGroupsModule> {
  @override
  Widget build(BuildContext context) {
    return StudyGroupsHomePage(userId: widget.userId);
  }
}

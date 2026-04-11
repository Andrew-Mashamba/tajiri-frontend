// lib/owners_club/owners_club_module.dart
import 'package:flutter/material.dart';
import 'pages/owners_club_home_page.dart';

class OwnersClubModule extends StatefulWidget {
  final int userId;
  const OwnersClubModule({super.key, required this.userId});
  @override
  State<OwnersClubModule> createState() => _OwnersClubModuleState();
}

class _OwnersClubModuleState extends State<OwnersClubModule> {
  @override
  Widget build(BuildContext context) {
    return OwnersClubHomePage(userId: widget.userId);
  }
}

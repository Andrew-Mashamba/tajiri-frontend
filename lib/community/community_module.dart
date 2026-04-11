// lib/community/community_module.dart
import 'package:flutter/material.dart';
import 'pages/community_home_page.dart';

class CommunityModule extends StatelessWidget {
  final int userId;
  const CommunityModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CommunityHomePage(userId: userId);
  }
}

// lib/my_family/my_family_module.dart
import 'package:flutter/material.dart';
import 'pages/family_home_page.dart';

class MyFamilyModule extends StatelessWidget {
  final int userId;
  const MyFamilyModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FamilyHomePage(userId: userId);
  }
}

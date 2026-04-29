// lib/my_children/pages/child_dashboard_page.dart
import 'package:flutter/material.dart';
import '../models/my_children_models.dart';
import 'baby_dashboard_page.dart';
import 'school_age_dashboard_page.dart';
import 'toddler_dashboard_page.dart';
import 'teen_dashboard_page.dart';

/// Age-adaptive wrapper that routes to the correct stage dashboard.
class ChildDashboardPage extends StatelessWidget {
  final Child child;
  final int userId;

  const ChildDashboardPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    switch (child.stage) {
      case 'infant':
        return BabyDashboardPage(baby: child, userId: userId);
      case 'toddler':
        return ToddlerDashboardPage(child: child, userId: userId);
      case 'school_age':
        return SchoolAgeDashboardPage(child: child, userId: userId);
      case 'teen':
        return TeenDashboardPage(child: child, userId: userId);
      default:
        return BabyDashboardPage(baby: child, userId: userId);
    }
  }
}

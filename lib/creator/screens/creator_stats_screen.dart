// CreatorStatsScreen — Scaffold wrapper around CreatorDashboardSection.
//
// After the lib/creator/ landing was changed to IncomeSourcesScreen, the
// existing tier/streak/multipliers/projected-payout dashboard moved one
// tap deeper: it's reachable via the "Stats" action button in the Mapato
// AppBar.
//
// CreatorDashboardSection itself is unchanged — this is just a chrome
// wrapper so it can stand alone as a route/screen.

import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import 'dashboard_section.dart';

class CreatorStatsScreen extends StatelessWidget {
  final int creatorId;

  const CreatorStatsScreen({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Takwimu' : 'Stats',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            CreatorDashboardSection(userId: creatorId),
          ],
        ),
      ),
    );
  }
}

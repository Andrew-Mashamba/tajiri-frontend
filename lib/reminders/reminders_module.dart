// lib/reminders/reminders_module.dart
import 'package:flutter/material.dart';

import 'pages/reminders_home_page.dart';

/// [userId] must be the **logged-in user’s** Tajiri profile id (`user_profiles.id`),
/// same as `?user_id=` on `/api/reminders` — use [ProfileScreen] `currentUserId`, not the viewed profile’s id.
class RemindersModule extends StatelessWidget {
  final int userId;

  /// When `true`, [RemindersHomePage] omits its own [AppBar] — use when the
  /// parent already provides the scaffold + title (e.g. profile tab).
  final bool embedInProfileTab;

  const RemindersModule({
    super.key,
    required this.userId,
    this.embedInProfileTab = false,
  });

  @override
  Widget build(BuildContext context) {
    return RemindersHomePage(
      userId: userId,
      embedInProfileTab: embedInProfileTab,
    );
  }
}

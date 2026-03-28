import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  final int currentUserId;

  const NotificationsScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: TajiriAppBar(
        title: s?.notifications ?? 'Notifications',
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeroIcon(
                  HeroIcons.bellSlash,
                  style: HeroIconStyle.outline,
                  size: 64,
                  color: const Color(0xFF999999),
                ),
                const SizedBox(height: 16),
                Text(
                  s?.noNotifications ?? 'No notifications yet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  s?.notificationsHint ?? 'When you get likes, comments, and follows they will show up here',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

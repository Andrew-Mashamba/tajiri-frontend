import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

/// Determines user's engagement intensity level based on account age.
/// Spec: Week 1-2 = gentle, Week 3-6 = medium, Week 7+ = full.
/// Features are progressively unlocked based on level.
enum EngagementLevel { gentle, medium, full }

class EngagementLevelService {
  static const String _firstSeenKey = 'engagement_first_seen';

  static Future<EngagementLevel> getLevel() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final firstSeenStr = storage.getString(_firstSeenKey);

      if (firstSeenStr == null) {
        // First time — record now, start at gentle
        await storage.setString(_firstSeenKey, DateTime.now().toIso8601String());
        return EngagementLevel.gentle;
      }

      final firstSeen = DateTime.tryParse(firstSeenStr);
      if (firstSeen == null) return EngagementLevel.gentle;

      final daysSinceFirst = DateTime.now().difference(firstSeen).inDays;

      if (daysSinceFirst >= 49) return EngagementLevel.full;    // Week 7+
      if (daysSinceFirst >= 14) return EngagementLevel.medium;   // Week 3-6
      return EngagementLevel.gentle;                              // Week 1-2
    } catch (e) {
      if (kDebugMode) debugPrint('[EngagementLevel] Error: $e');
      return EngagementLevel.gentle;
    }
  }

  /// Check if a specific feature should be enabled
  static bool shouldShow({
    required EngagementLevel level,
    required EngagementFeature feature,
  }) {
    switch (feature) {
      case EngagementFeature.digestNotifications:
      case EngagementFeature.milestones:
      case EngagementFeature.organicFeed:
        return true; // Always on
      case EngagementFeature.teaserCards:
      case EngagementFeature.reactionPrompts:
      case EngagementFeature.streakVisibility:
      case EngagementFeature.fomoTriggers:
        return level == EngagementLevel.medium || level == EngagementLevel.full;
      case EngagementFeature.depthMilestones:
      case EngagementFeature.autoplayChains:
      case EngagementFeature.competitiveElements:
      case EngagementFeature.lossAversion:
        return level == EngagementLevel.full;
    }
  }
}

enum EngagementFeature {
  digestNotifications,
  milestones,
  organicFeed,
  teaserCards,
  reactionPrompts,
  streakVisibility,
  fomoTriggers,
  depthMilestones,
  autoplayChains,
  competitiveElements,
  lossAversion,
}

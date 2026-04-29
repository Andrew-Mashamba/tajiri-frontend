import 'package:flutter/material.dart';

import '../../engagements/pages/engagement_workspace_page.dart' as shared;

/// Customer-side wrapper per spec §8 line 758.
/// Same TabController-driven workspace, role=customer.
class EngagementWorkspacePage extends StatelessWidget {
  final int userId;
  final int engagementId;
  const EngagementWorkspacePage({
    super.key,
    required this.userId,
    required this.engagementId,
  });

  @override
  Widget build(BuildContext context) {
    return shared.EngagementWorkspacePage(
      userId: userId,
      engagementId: engagementId,
      role: 'customer',
    );
  }
}

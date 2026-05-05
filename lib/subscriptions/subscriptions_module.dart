// lib/subscriptions/subscriptions_module.dart
//
// Entry point for the Subscriptions module — the Finance-category
// landing surface for everything the user pays for. This is the
// subscriber-side hub; the creator side (manage subscribers, tiers,
// earnings) is reachable from the Subscribers stat chip on the
// profile header instead.
//
// Module structure:
//   subscriptions_module.dart      ← this file (entry shim)
//   pages/
//     subscriptions_home_page.dart ← state + UI
//   widgets/
//     subscription_hub_card.dart
//     subscription_section_label.dart
//     subscription_spending_header.dart

import 'package:flutter/material.dart';

import 'pages/subscriptions_home_page.dart';

class SubscriptionsModule extends StatelessWidget {
  final int userId;
  const SubscriptionsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SubscriptionsHomePage(userId: userId);
  }
}

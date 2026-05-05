// lib/subscriptions/widgets/subscription_section_label.dart
//
// Small all-caps label that separates groups of cards in the hub.

import 'package:flutter/material.dart';

const Color _kTertiary = Color(0xFF999999);

class SubscriptionSectionLabel extends StatelessWidget {
  final String label;
  const SubscriptionSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kTertiary,
          letterSpacing: 0.6,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

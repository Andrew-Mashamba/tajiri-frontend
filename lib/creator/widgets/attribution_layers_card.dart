// lib/creator/widgets/attribution_layers_card.dart
//
// Strategy alignment §1 (three earning layers) + §4 (bounded
// propagation). Educational card explaining how earnings flow:
//
//   A) Direct engagement   100%  — author of the post that was viewed
//   B) Context royalty     10–20% — comment/reply/host receiving
//                                   engagement on a hosted thread
//   C) Derivative royalty  10–20% — original creator when someone
//                                   built a quote/stitch/remix on top
//   D) Distribution credit 5–15%  — sharer that drove unique traffic
//
// Drops onto any earnings surface (PostEarningsScreen, dashboard,
// provenance ledger). Monochromatic, bilingual, ellipsised.

import 'package:flutter/material.dart';

import '../models/creator_earnings_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kIconBg = Color(0xFFF5F5F5);

class AttributionLayersCard extends StatelessWidget {
  final bool isSw;
  const AttributionLayersCard({super.key, required this.isSw});

  static const _layers = [
    PayoutLayer.direct,
    PayoutLayer.context,
    PayoutLayer.derivative,
    PayoutLayer.distribution,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _layers.length; i++) ...[
            _LayerRow(layer: _layers[i], isSw: isSw),
            if (i < _layers.length - 1)
              const Divider(
                  height: 1, color: _kBorder, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  final PayoutLayer layer;
  final bool isSw;
  const _LayerRow({required this.layer, required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(_iconFor(layer), size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        layer.label(isSw),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        layer.shareLabel(isSw),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  layer.description(isSw),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondary,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(PayoutLayer layer) => switch (layer) {
        PayoutLayer.direct => Icons.bolt_rounded,
        PayoutLayer.context => Icons.forum_outlined,
        PayoutLayer.derivative => Icons.copy_all_outlined,
        PayoutLayer.distribution => Icons.share_outlined,
      };
}

/// Caption row that explains the bounded-propagation principle from
/// strategy §4 — used as a footer below the card to set expectations
/// that royalties don't recurse infinitely.
class AttributionPropagationFooter extends StatelessWidget {
  final bool isSw;
  const AttributionPropagationFooter({super.key, required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: _kTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isSw
                  ? 'Royalty huishia kwa wazazi wa karibu (mzazi wa moja kwa moja na asili). Hairudii bila kikomo — kuepuka mgawanyiko mdogo na unyanyasaji.'
                  : 'Royalties stop at the immediate parent and the root. They do not recurse — keeping payouts auditable and resistant to abuse.',
              style: const TextStyle(
                fontSize: 11,
                color: _kTertiary,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

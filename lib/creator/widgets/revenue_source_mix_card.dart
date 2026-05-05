// lib/creator/widgets/revenue_source_mix_card.dart
//
// Strategy alignment §12 — "Imagine dashboards like: 42% direct
// engagement / 28% shares / 18% derivative royalties / 12% follower
// conversions". A monochrome donut visualization of source mix
// driven by [CreatorEarningsDashboard.breakdownByStream].
//
// The donut uses 4 grayscale shades (matching the playbook
// monochrome rule). Legend rows show stream label, % share, and
// the underlying TZS cleared amount. Empty state collapses to a
// single 'no earnings yet' tile.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/creator_earnings_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;

/// 4 monochrome shades for donut wedges (per playbook palette §3).
const List<Color> _kSliceColors = [
  Color(0xFF1A1A1A),
  Color(0xFF555555),
  Color(0xFF888888),
  Color(0xFFBBBBBB),
  Color(0xFFD8D8D8),
  Color(0xFFE9E9E9),
];

class RevenueSourceMixCard extends StatelessWidget {
  final Map<String, StreamBreakdown> breakdownByStream;
  final bool isSw;

  const RevenueSourceMixCard({
    super.key,
    required this.breakdownByStream,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _composeEntries();
    final total = entries.fold<double>(0, (a, e) => a + e.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large_rounded,
                  size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw ? 'Mchanganyiko wa vyanzo' : 'Revenue source mix',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (total <= 0)
            _EmptyDonut(isSw: isSw)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Donut(entries: entries, total: total, isSw: isSw),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        _LegendRow(
                          color: _kSliceColors[i % _kSliceColors.length],
                          label: entries[i].label(isSw),
                          pct: entries[i].amount / total,
                          amount: entries[i].amount,
                        ),
                        if (i < entries.length - 1)
                          const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<_MixEntry> _composeEntries() {
    final order = [
      'engagement',
      'fan_funding',
      'marketplace',
      'brand_deal',
      'live_gifts',
      'affiliate',
    ];
    final items = <_MixEntry>[];
    for (final key in order) {
      final s = breakdownByStream[key];
      if (s == null) continue;
      final amount = s.clearedTsh + s.pendingTsh;
      if (amount <= 0) continue;
      items.add(_MixEntry(streamKey: key, amount: amount));
    }
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }
}

class _MixEntry {
  final String streamKey;
  final double amount;
  _MixEntry({required this.streamKey, required this.amount});

  String label(bool isSw) {
    return switch (streamKey) {
      'engagement' => isSw ? 'Mwingiliano' : 'Direct engagement',
      'fan_funding' => isSw ? 'Misaada ya mashabiki' : 'Fan funding',
      'marketplace' => isSw ? 'Soko' : 'Marketplace',
      'brand_deal' => isSw ? 'Mikataba ya brand' : 'Brand deals',
      'live_gifts' => isSw ? 'Zawadi za live' : 'Live gifts',
      'affiliate' => isSw ? 'Tume za affiliate' : 'Affiliate',
      _ => streamKey,
    };
  }
}

class _Donut extends StatelessWidget {
  final List<_MixEntry> entries;
  final double total;
  final bool isSw;

  const _Donut({
    required this.entries,
    required this.total,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _DonutPainter(entries: entries, total: total),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmtCompact(total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isSw ? 'TZS jumla' : 'TZS total',
                style: const TextStyle(
                  fontSize: 9,
                  color: _kTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_MixEntry> entries;
  final double total;

  _DonutPainter({required this.entries, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const ringWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius - ringWidth / 2);
    var start = -math.pi / 2;
    for (var i = 0; i < entries.length; i++) {
      final pct = entries[i].amount / total;
      final sweep = pct * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt
        ..color = _kSliceColors[i % _kSliceColors.length];
      // 1 degree gap between wedges (subtle separation)
      const gap = math.pi / 180;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.entries != entries || old.total != total;
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  final double amount;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.pct,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _kPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(pct * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 12,
            color: _kSecondary,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _EmptyDonut extends StatelessWidget {
  final bool isSw;
  const _EmptyDonut({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.donut_large_rounded,
                size: 22, color: _kTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSw
                  ? 'Bado hakuna mapato kuonyesha mchanganyiko.'
                  : 'No earnings yet to chart a source mix.',
              style: const TextStyle(
                  fontSize: 12, color: _kSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtCompact(double v) {
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
  }
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  final whole = v.truncateToDouble() == v;
  return whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

// lib/creator/screens/creator_tier_screen.dart
//
// Creator tier overview screen — strategy §4.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../services/creator_earnings_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);

class CreatorTierScreen extends StatefulWidget {
  final int currentUserId;
  const CreatorTierScreen({super.key, required this.currentUserId});

  @override
  State<CreatorTierScreen> createState() => _CreatorTierScreenState();
}

class _CreatorTierScreenState extends State<CreatorTierScreen> {
  final _service = CreatorEarningsService();
  Map<String, dynamic>? _rateCard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rc = await _service.getRateCard();
      if (!mounted) return;
      setState(() {
        _rateCard = rc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load rate card.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: isSw ? 'Kiwango cha Mtoa Mada' : 'Creator Tier'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? _buildError(isSw)
                : _buildContent(isSw),
      ),
    );
  }

  Widget _buildContent(bool isSw) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          isSw
              ? 'Kupandisha kiwango huongeza ufikiaji wa zana mpya za mapato (mikataba ya brand, Discovery Mode, malipo ya juu).'
              : 'Higher tiers unlock new earnings tools (brand-deal marketplace, Discovery Mode, premium splits).',
          style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.45),
          maxLines: 4, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 20),
        _tierCard('mwanzo', isSw),
        const SizedBox(height: 12),
        _tierCard('standard', isSw),
        const SizedBox(height: 12),
        _tierCard('verified', isSw),
        const SizedBox(height: 12),
        _tierCard('partner', isSw),
        const SizedBox(height: 24),
        _SectionLabel(isSw ? 'KARTI YA VIWANGO' : 'PUBLIC RATE CARD'),
        const SizedBox(height: 8),
        _ratesCard(),
      ],
    );
  }

  Widget _tierCard(String tier, bool isSw) {
    final tierLabel = {
      'mwanzo': isSw ? 'Mwanzo' : 'Starter',
      'standard': isSw ? 'Kawaida' : 'Standard',
      'verified': isSw ? 'Iliyothibitishwa' : 'Verified',
      'partner': isSw ? 'Mshirika' : 'Partner',
    }[tier] ?? tier;

    final blurb = {
      'mwanzo': isSw ? 'Pata 2× nguvu kwa siku 30 za kwanza.' : '2× boost for first 30 days.',
      'standard': isSw ? 'Lango la zawadi za moja kwa moja na Discovery Mode.' : 'Unlocks live gifts + Discovery Mode.',
      'verified': isSw ? 'Lango la mikataba ya brand.' : 'Unlocks brand-deal marketplace.',
      'partner': isSw ? '75/25 mgawo wa mfuko + 92.5% kwa zawadi.' : '75/25 fund split + 92.5% on live gifts.',
    }[tier] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tierLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 4),
                Text(blurb, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratesCard() {
    final ratesByStream = _rateCard?['rates_by_stream'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in ratesByStream.entries) ...[
            Text(entry.key.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kTertiary, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            for (final r in (entry.value as List)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r['metric']} · ${r['actor_role']}',
                        style: const TextStyle(fontSize: 12, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'TZS ${r['rate_tsh']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 16, color: _kBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildError(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error ?? '', style: const TextStyle(color: _kSecondary, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isSw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.6)),
      );
}

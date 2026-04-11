// lib/loans/pages/score_breakdown_page.dart
import 'package:flutter/material.dart';
import '../models/loan_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ScoreBreakdownPage extends StatelessWidget {
  final CreatorCreditScore creditScore;
  const ScoreBreakdownPage({super.key, required this.creditScore});

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Alama ya Mkopo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Big score
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: creditScore.gradeColor, width: 4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${creditScore.score}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          creditScore.grade,
                          style: TextStyle(color: creditScore.gradeColor, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creditScore.maxEligibleTier != null
                            ? 'Unastahili mkopo wa ${creditScore.maxEligibleTier!.displayName}'
                            : 'Bado hukidhi vigezo vya mkopo',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mapato: TZS ${_fmt(creditScore.monthlyEarningsAvg)}/mwezi',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Breakdown
          const Text(
            'Mgawanyo wa Alama',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),

          if (creditScore.breakdown.isNotEmpty)
            ...creditScore.breakdown.map((b) => _BreakdownItem(breakdown: b))
          else ...[
            // Show static factors when no breakdown data
            _StaticFactor(
              label: 'Utulivu wa Mapato',
              description: 'Wastani wa mapato ya miezi 3 iliyopita',
              weight: 30,
              value: 'TZS ${_fmt(creditScore.monthlyEarningsAvg)}/mwezi',
            ),
            _StaticFactor(
              label: 'Uthabiti wa Maudhui',
              description: 'Mfululizo wa siku za kutengeneza maudhui',
              weight: 15,
              value: '${creditScore.streakDays} siku mfululizo',
            ),
            _StaticFactor(
              label: 'Ukuaji wa Mapato',
              description: 'Ongezeko la mapato mwezi huu vs uliopita',
              weight: 10,
              value: '${creditScore.earningsGrowthPercent >= 0 ? '+' : ''}${creditScore.earningsGrowthPercent.toStringAsFixed(1)}%',
            ),
            _StaticFactor(
              label: 'Mseto wa Mapato',
              description: 'Vyanzo tofauti vya mapato (usajili, zawadi, duka, n.k.)',
              weight: 10,
              value: '${creditScore.revenueSources} vyanzo',
            ),
            _StaticFactor(
              label: 'Muda kwenye Jukwaa',
              description: 'Miezi tangu usajili',
              weight: 10,
              value: '${creditScore.platformTenureMonths} miezi',
            ),
            _StaticFactor(
              label: 'Historia ya Malipo',
              description: 'Asilimia ya malipo yaliyolipwa kwa wakati',
              weight: 5,
              value: '${(creditScore.repaymentRate * 100).toStringAsFixed(0)}%',
            ),
          ],
          const SizedBox(height: 24),

          // Tips to improve
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 20, color: _kPrimary),
                    SizedBox(width: 8),
                    Text('Jinsi ya Kuboresha Alama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                _TipItem(text: 'Tengeneza maudhui mara kwa mara ili kuongeza mfululizo'),
                _TipItem(text: 'Pata mapato kutoka vyanzo vingi (usajili + duka + zawadi)'),
                _TipItem(text: 'Ongeza wafuasi na wasajili kupitia maudhui bora'),
                _TipItem(text: 'Lipa mikopo kwa wakati ili kuboresha historia'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final ScoreBreakdown breakdown;
  const _BreakdownItem({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final percent = breakdown.maxScore > 0 ? breakdown.score / breakdown.maxScore : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                breakdown.factorLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              Text(
                '${breakdown.score.toStringAsFixed(0)}/${breakdown.maxScore.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Uzito: ${(breakdown.weight * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: _kPrimary.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent >= 0.7 ? const Color(0xFF4CAF50) : percent >= 0.4 ? Colors.orange : Colors.red,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticFactor extends StatelessWidget {
  final String label;
  final String description;
  final int weight;
  final String value;

  const _StaticFactor({
    required this.label,
    required this.description,
    required this.weight,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text(description, style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              Text('$weight%', style: const TextStyle(fontSize: 10, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _kSecondary))),
        ],
      ),
    );
  }
}

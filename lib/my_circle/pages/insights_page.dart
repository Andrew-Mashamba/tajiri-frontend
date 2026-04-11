// lib/my_circle/pages/insights_page.dart
import 'package:flutter/material.dart';
import '../../doctor/doctor_module.dart';
import '../models/my_circle_models.dart';
import '../services/my_circle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InsightsPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const InsightsPage({super.key, required this.userId, this.isSwahili = false});
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final MyCircleService _service = MyCircleService();
  CycleStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final result = await _service.getStats(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _stats = result.success ? result.data : CycleStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(widget.isSwahili ? 'Takwimu za Duru' : 'Cycle Insights', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Cycle statistics
                  _SectionTitle(title: widget.isSwahili ? 'Muhtasari wa Duru' : 'Cycle Summary'),
                  const SizedBox(height: 10),
                  _CycleStatsCard(stats: _stats!, isSwahili: widget.isSwahili),
                  const SizedBox(height: 20),

                  // Cycle length trend
                  if (_stats!.cycleLengthHistory.isNotEmpty) ...[
                    _SectionTitle(title: widget.isSwahili ? 'Mwenendo wa Urefu wa Duru' : 'Cycle Length Trend'),
                    const SizedBox(height: 10),
                    _CycleTrendChart(history: _stats!.cycleLengthHistory, isSwahili: widget.isSwahili),
                    const SizedBox(height: 20),
                  ],

                  // Most common symptoms
                  if (_stats!.symptomFrequency.isNotEmpty) ...[
                    _SectionTitle(title: widget.isSwahili ? 'Dalili za Mara kwa Mara' : 'Most Common Symptoms'),
                    const SizedBox(height: 10),
                    _SymptomFrequencyCard(frequency: _stats!.symptomFrequency, isSwahili: widget.isSwahili),
                    const SizedBox(height: 20),
                  ],

                  // Mood patterns
                  if (_stats!.moodFrequency.isNotEmpty) ...[
                    _SectionTitle(title: widget.isSwahili ? 'Mwenendo wa Hisia' : 'Mood Patterns'),
                    const SizedBox(height: 10),
                    _MoodPatternCard(frequency: _stats!.moodFrequency, isSwahili: widget.isSwahili),
                    const SizedBox(height: 20),
                  ],

                  // Abnormal cycle alert
                  if (_stats!.isAbnormal) ...[
                    _AbnormalAlert(userId: widget.userId, isSwahili: widget.isSwahili),
                    const SizedBox(height: 20),
                  ],

                  // Doctor link
                  Material(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DoctorModule(userId: widget.userId),
                        ));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services_rounded, color: _kPrimary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.isSwahili ? 'Ongea na Daktari' : 'Talk to a Doctor', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                                  Text(widget.isSwahili ? 'Pata ushauri kuhusu duru yako' : 'Get advice about your cycle', style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: _kSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─── Section Title ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary));
  }
}

// ─── Cycle Stats Card ──────────────────────────────────────────

class _CycleStatsCard extends StatelessWidget {
  final CycleStats stats;
  final bool isSwahili;
  const _CycleStatsCard({required this.stats, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final unit = isSwahili ? 'siku' : 'days';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatItem(value: '${stats.averageCycleLength.round()}', unit: unit, label: isSwahili ? 'Urefu wa duru' : 'Cycle length')),
              Container(width: 1, height: 40, color: _kPrimary.withValues(alpha: 0.1)),
              Expanded(child: _StatItem(value: '${stats.averagePeriodLength.round()}', unit: unit, label: isSwahili ? 'Urefu wa hedhi' : 'Period length')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatItem(value: '${stats.longestCycle}', unit: unit, label: isSwahili ? 'Duru ndefu' : 'Longest cycle')),
              Container(width: 1, height: 40, color: _kPrimary.withValues(alpha: 0.1)),
              Expanded(child: _StatItem(value: '${stats.shortestCycle}', unit: unit, label: isSwahili ? 'Duru fupi' : 'Shortest cycle')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatItem(value: '${stats.totalCyclesLogged}', unit: '', label: isSwahili ? 'Duru zilizorekodwa' : 'Cycles logged')),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  const _StatItem({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kPrimary)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ─── Cycle Trend Chart (Simple bar chart) ──────────────────────

class _CycleTrendChart extends StatelessWidget {
  final List<int> history;
  final bool isSwahili;
  const _CycleTrendChart({required this.history, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
    final maxVal = recent.isEmpty ? 1 : recent.reduce((a, b) => a > b ? a : b);
    final minVal = recent.isEmpty ? 0 : recent.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(recent.length, (i) {
                final val = recent[i];
                final height = maxVal > 0 ? (val / maxVal * 100).clamp(10.0, 100.0) : 10.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$val', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('D${i + 1}', style: const TextStyle(fontSize: 9, color: _kSecondary)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          if (maxVal != minVal) ...[
            const SizedBox(height: 8),
            Text(
              isSwahili ? 'Tofauti: ${maxVal - minVal} siku' : 'Variation: ${maxVal - minVal} days',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Symptom Frequency ─────────────────────────────────────────

class _SymptomFrequencyCard extends StatelessWidget {
  final Map<String, int> frequency;
  final bool isSwahili;
  const _SymptomFrequencyCard({required this.frequency, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final sorted = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6);
    final maxCount = sorted.isNotEmpty ? sorted.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: top.map((entry) {
          final symptom = Symptom.fromString(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(symptom?.icon ?? Icons.circle, size: 16, color: _kPrimary),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: Text(
                    symptom?.displayName(isSwahili) ?? entry.key,
                    style: const TextStyle(fontSize: 12, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxCount > 0 ? entry.value / maxCount : 0,
                    backgroundColor: _kPrimary.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Mood Pattern ──────────────────────────────────────────────

class _MoodPatternCard extends StatelessWidget {
  final Map<String, int> frequency;
  final bool isSwahili;
  const _MoodPatternCard({required this.frequency, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final sorted = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sorted.take(5).map((entry) {
          final mood = Mood.fromString(entry.key);
          final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
          return Column(
            children: [
              Text(mood?.emoji ?? '', style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text('$percentage%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
              Text(mood?.displayName(isSwahili) ?? entry.key, style: const TextStyle(fontSize: 9, color: _kSecondary)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Abnormal Alert ────────────────────────────────────────────

class _AbnormalAlert extends StatelessWidget {
  final int userId;
  final bool isSwahili;
  const _AbnormalAlert({required this.userId, this.isSwahili = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 24, color: Color(0xFFFF9800)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? 'Duru isiyo ya kawaida' : 'Irregular cycle detected',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  isSwahili
                      ? 'Tofauti kubwa imegunduliwa kati ya duru zako. Tunapendekeza uzungumze na daktari wa uzazi.'
                      : 'A significant variation has been detected between your cycles. We recommend consulting a gynecologist.',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DoctorModule(userId: userId),
                    ));
                  },
                  child: Text(
                    isSwahili ? 'Ongea na Daktari' : 'Talk to a Doctor',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

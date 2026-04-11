// lib/hair_nails/pages/growth_tracker_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class GrowthTrackerPage extends StatefulWidget {
  final int userId;
  const GrowthTrackerPage({super.key, required this.userId});
  @override
  State<GrowthTrackerPage> createState() => _GrowthTrackerPageState();
}

class _GrowthTrackerPageState extends State<GrowthTrackerPage> {
  final HairNailsService _service = HairNailsService();

  List<GrowthLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getGrowthHistory(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _logs = result.items;
      });
    }
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  double? get _growthRate {
    if (_logs.length < 2) return null;
    final sorted = List<GrowthLog>.from(_logs)..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final last = sorted.last;
    final months = last.date.difference(first.date).inDays / 30.0;
    if (months <= 0) return null;
    return (last.lengthCm - first.lengthCm) / months;
  }

  void _showAddDialog() {
    final lengthCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Rekodi Ukuaji', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 6),
              const Text('Pima urefu wa nywele zako kutoka kwenye ngozi ya kichwa hadi ncha', style: TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 16),

              TextField(
                controller: lengthCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Urefu (cm)',
                  hintText: 'mfano: 15.5',
                  hintStyle: const TextStyle(color: _kSecondary),
                  filled: true,
                  fillColor: _kCardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixText: 'cm',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Maelezo (si lazima)',
                  hintText: 'mfano: Nilitumia mafuta ya coconut wiki hii',
                  hintStyle: const TextStyle(color: _kSecondary, fontSize: 12),
                  filled: true,
                  fillColor: _kCardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final length = double.tryParse(lengthCtrl.text);
                          if (length == null || length <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weka urefu sahihi'), backgroundColor: Colors.red));
                            return;
                          }
                          setSheetState(() => saving = true);
                          final result = await _service.logGrowth(
                            userId: widget.userId,
                            lengthCm: length,
                            notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                          );
                          if (context.mounted) {
                            if (result.success) {
                              Navigator.pop(context);
                              _loadData();
                            } else {
                              setSheetState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa'), backgroundColor: Colors.red));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: _kSecondary,
                  ),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Hifadhi', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Ukuaji wa Nywele', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats
                    _buildStatsCard(),
                    const SizedBox(height: 16),

                    // Growth chart (simplified bar representation)
                    if (_logs.length >= 2) ...[
                      _buildGrowthChart(),
                      const SizedBox(height: 16),
                    ],

                    // Tips
                    _buildTipsCard(),
                    const SizedBox(height: 16),

                    // Timeline
                    const Text('Historia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 10),
                    if (_logs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
                        child: const Column(
                          children: [
                            Icon(Icons.straighten_rounded, size: 40, color: _kSecondary),
                            SizedBox(height: 10),
                            Text('Bado hakuna rekodi', style: TextStyle(fontSize: 14, color: _kSecondary)),
                            Text('Bonyeza + kuanza kupima', style: TextStyle(fontSize: 12, color: _kSecondary)),
                          ],
                        ),
                      )
                    else
                      ..._logs.map((log) => _logItem(log)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final rate = _growthRate;
    final latest = _logs.isNotEmpty ? _logs.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(latest != null ? '${latest.lengthCm.toStringAsFixed(1)}cm' : '-', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kPrimary)),
                const Text('Urefu Sasa', style: TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: _kPrimary.withValues(alpha: 0.1)),
          Expanded(
            child: Column(
              children: [
                Text(rate != null ? '${rate.toStringAsFixed(1)}cm' : '-', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kPrimary)),
                const Text('Kwa Mwezi', style: TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: _kPrimary.withValues(alpha: 0.1)),
          Expanded(
            child: Column(
              children: [
                Text('${_logs.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kPrimary)),
                const Text('Rekodi', style: TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    final sorted = List<GrowthLog>.from(_logs)..sort((a, b) => a.date.compareTo(b.date));
    final maxLength = sorted.map((l) => l.lengthCm).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mwenendo wa Ukuaji', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sorted.take(12).map((log) {
                final fraction = maxLength > 0 ? log.lengthCm / maxLength : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${log.lengthCm.toStringAsFixed(0)}', style: const TextStyle(fontSize: 8, color: _kSecondary)),
                        const SizedBox(height: 2),
                        Container(
                          height: 80 * fraction,
                          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(height: 4),
                        Text('${log.date.month}/${log.date.year.toString().substring(2)}', style: const TextStyle(fontSize: 7, color: _kSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: _kPrimary),
              SizedBox(width: 6),
              Text('Vidokezo vya Ukuaji', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '\u2022 Kunywa maji mengi — angalau lita 2 kwa siku\n'
            '\u2022 Kula vyakula vyenye protini (mayai, samaki, maharage)\n'
            '\u2022 Epuka joto kali kwenye nywele\n'
            '\u2022 Lala na kitambaa cha satin/silk\n'
            '\u2022 Pima kila wiki 4-6 kwa matokeo bora\n'
            '\u2022 Massage ngozi ya kichwa kwa dakika 5 kila siku',
            style: TextStyle(fontSize: 12, color: _kSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _logItem(GrowthLog log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text('${log.lengthCm.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${log.lengthCm.toStringAsFixed(1)} cm', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text(_fmtDate(log.date), style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  if (log.notes != null) Text(log.notes!, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (log.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(log.photoUrl!, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
          ],
        ),
      ),
    );
  }
}

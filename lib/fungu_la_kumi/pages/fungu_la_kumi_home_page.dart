// lib/fungu_la_kumi/pages/fungu_la_kumi_home_page.dart
import 'package:flutter/material.dart';
import '../models/fungu_la_kumi_models.dart';
import '../services/fungu_la_kumi_service.dart';
import '../widgets/pledge_card.dart';
import 'give_now_page.dart';
import 'giving_history_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class FunguLaKumiHomePage extends StatefulWidget {
  final int userId;
  const FunguLaKumiHomePage({super.key, required this.userId});
  @override
  State<FunguLaKumiHomePage> createState() => _FunguLaKumiHomePageState();
}

class _FunguLaKumiHomePageState extends State<FunguLaKumiHomePage> {
  GivingSummary? _summary;
  List<Pledge> _pledges = [];
  List<GivingRecord> _recentRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      FunguLaKumiService.getSummary(),
      FunguLaKumiService.getPledges(),
      FunguLaKumiService.getHistory(),
    ]);
    if (mounted) {
      final sumR = results[0] as SingleResult<GivingSummary>;
      final pledgeR = results[1] as PaginatedResult<Pledge>;
      final histR = results[2] as PaginatedResult<GivingRecord>;
      setState(() {
        _isLoading = false;
        if (sumR.success) _summary = sumR.data;
        if (pledgeR.success) _pledges = pledgeR.items;
        if (histR.success) _recentRecords = histR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : Stack(
            children: [
              RefreshIndicator(
                onRefresh: _load,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Action bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history_rounded, size: 22, color: _kPrimary),
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const GivingHistoryPage())),
                        ),
                      ],
                    ),
                    // Summary card
                    if (_summary != null) _buildSummary(),
                    const SizedBox(height: 20),

                    // Pledges
                    if (_pledges.isNotEmpty) ...[
                      const Text('Ahadi / Pledges',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 10),
                      ..._pledges.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PledgeCard(pledge: p),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Recent giving
                    const Text('Hivi Karibuni',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text('Recent Giving',
                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    if (_recentRecords.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: const Text('Bado hujatoa\nNo giving records yet',
                            style: TextStyle(color: _kSecondary, fontSize: 13),
                            textAlign: TextAlign.center),
                      )
                    else
                      ..._recentRecords.take(5).map((r) => _RecordRow(record: r)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    final given = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const GiveNowPage()),
                    );
                    if (given == true && mounted) _load();
                  },
                  backgroundColor: _kPrimary,
                  icon: const Icon(Icons.volunteer_activism_rounded, color: Colors.white),
                  label: const Text('Toa / Give',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
  }

  Widget _buildSummary() {
    final s = _summary!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Text('Muhtasari / Summary',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (s.givingStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${s.givingStreak} wiki mfululizo / weeks streak',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TSh ${_formatAmount(s.totalThisMonth)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('Mwezi huu / This month',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TSh ${_formatAmount(s.totalThisYear)}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('Mwaka huu / This year',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

class _RecordRow extends StatelessWidget {
  final GivingRecord record;
  const _RecordRow({required this.record});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.type.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(record.date,
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ),
            ),
            Text('TSh ${record.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}

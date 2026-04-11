// lib/rc/pages/rc_investments_page.dart
import 'package:flutter/material.dart';
import '../models/rc_models.dart';
import '../services/rc_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RcInvestmentsPage extends StatefulWidget {
  final int regionId;
  const RcInvestmentsPage({super.key, required this.regionId});

  @override
  State<RcInvestmentsPage> createState() => _RcInvestmentsPageState();
}

class _RcInvestmentsPageState extends State<RcInvestmentsPage> {
  List<InvestmentOpportunity> _investments = [];
  bool _loading = true;
  final _service = RcService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getInvestments(widget.regionId);
    if (mounted) {
      setState(() {
        _investments = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Fursa za Uwekezaji',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _investments.isEmpty
              ? const Center(child: Text('Hakuna fursa kwa sasa', style: TextStyle(color: _kSecondary)))
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _investments.length,
                    itemBuilder: (_, i) => _buildInvestment(_investments[i]),
                  ),
                ),
    );
  }

  Widget _buildInvestment(InvestmentOpportunity inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(inv.sector, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(inv.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Text(inv.description, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          if (inv.incentives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: _kSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(inv.incentives, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kSecondary))),
            ]),
          ],
        ],
      ),
    );
  }
}

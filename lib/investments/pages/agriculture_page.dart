// lib/investments/pages/agriculture_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AgriculturePage extends StatefulWidget {
  final int userId;
  const AgriculturePage({super.key, required this.userId});
  @override
  State<AgriculturePage> createState() => _AgriculturePageState();
}

class _AgriculturePageState extends State<AgriculturePage> {
  final InvestmentService _service = InvestmentService();
  List<AgricultureProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final result = await _service.getAgricultureProjects();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _projects = result.items;
      });
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  IconData _cropIcon(String crop) {
    final c = crop.toLowerCase();
    if (c.contains('korosho') || c.contains('cashew')) return Icons.spa_rounded;
    if (c.contains('kahawa') || c.contains('coffee')) return Icons.coffee_rounded;
    if (c.contains('chai') || c.contains('tea')) return Icons.emoji_food_beverage_rounded;
    if (c.contains('mahindi') || c.contains('maize')) return Icons.grass_rounded;
    return Icons.agriculture_rounded;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Wazi';
      case 'funded': return 'Imejaa';
      case 'growing': return 'Inakua';
      case 'harvested': return 'Imevunwa';
      case 'closed': return 'Imefungwa';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return const Color(0xFF4CAF50);
      case 'funded': return Colors.blue;
      case 'growing': return Colors.orange;
      case 'harvested': return Colors.teal;
      default: return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Uwekezaji wa Kilimo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.agriculture_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Hakuna miradi ya kilimo kwa sasa', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text(
                        'Miradi ya korosho, kahawa, na\nmingineyo itaonekana hapa.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final p = _projects[index];
                      final statusColor = _statusColor(p.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_cropIcon(p.crop), size: 24, color: const Color(0xFF4CAF50)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                                      Text(
                                        '${p.crop} • ${p.location} • ${p.season}',
                                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel(p.status),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            if (p.description != null) ...[
                              const SizedBox(height: 10),
                              Text(p.description!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 12),
                            // Progress
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (p.fundedPercent / 100).clamp(0.0, 1.0),
                                backgroundColor: _kPrimary.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TZS ${_fmt(p.raisedAmount)} / ${_fmt(p.targetAmount)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                Text('${p.fundedPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _Tag(label: 'Mapato: ${p.expectedReturn.toStringAsFixed(0)}%'),
                                const SizedBox(width: 8),
                                _Tag(label: 'Muda: ${p.durationMonths} miezi'),
                                const SizedBox(width: 8),
                                _Tag(label: 'Min: TZS ${_fmt(p.minInvestment)}'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
    );
  }
}

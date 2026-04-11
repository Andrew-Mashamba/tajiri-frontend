// lib/investments/pages/real_estate_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RealEstatePage extends StatefulWidget {
  final int userId;
  const RealEstatePage({super.key, required this.userId});
  @override
  State<RealEstatePage> createState() => _RealEstatePageState();
}

class _RealEstatePageState extends State<RealEstatePage> {
  final InvestmentService _service = InvestmentService();
  List<RealEstateProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final result = await _service.getRealEstateProjects();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Uwekezaji wa Nyumba', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_city_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Hakuna miradi kwa sasa', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text(
                        'Miradi ya W-REIT na uwekezaji\nwa pamoja itaonekana hapa.',
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image placeholder
                            Container(
                              height: 140,
                              width: double.infinity,
                              color: _kPrimary.withValues(alpha: 0.06),
                              child: p.imageUrl != null
                                  ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                                  : const Center(child: Icon(Icons.location_city_rounded, size: 48, color: _kSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: p.isOpen
                                              ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                              : _kSecondary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          p.isOpen ? 'Wazi' : 'Imefungwa',
                                          style: TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w600,
                                            color: p.isOpen ? const Color(0xFF4CAF50) : _kSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${p.typeName} • ${p.location}',
                                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (p.fundedPercent / 100).clamp(0.0, 1.0),
                                      backgroundColor: _kPrimary.withValues(alpha: 0.08),
                                      valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TZS ${_fmt(p.raisedAmount)} / ${_fmt(p.targetAmount)}',
                                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                                      ),
                                      Text(
                                        '${p.fundedPercent.toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                                      ),
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

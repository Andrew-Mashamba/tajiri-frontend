// lib/car_insurance/pages/car_insurance_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/car_insurance_models.dart';
import '../services/car_insurance_service.dart';
import '../widgets/policy_card.dart';
import 'get_quotes_page.dart';
import 'file_claim_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class CarInsuranceHomePage extends StatefulWidget {
  final int userId;
  const CarInsuranceHomePage({super.key, required this.userId});
  @override
  State<CarInsuranceHomePage> createState() => _CarInsuranceHomePageState();
}

class _CarInsuranceHomePageState extends State<CarInsuranceHomePage> {
  List<InsurancePolicy> _policies = [];
  List<InsuranceClaim> _claims = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pRes = await CarInsuranceService.getMyPolicies();
    final cRes = await CarInsuranceService.getMyClaims();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (pRes.success) _policies = pRes.items;
      if (cRes.success) _claims = cRes.items;
    });
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  _summaryBanner(),
                  const SizedBox(height: 16),
                  _quickActions(),
                  const SizedBox(height: 20),

                  // Expiring soon
                  if (_policies.any((p) => p.daysRemaining <= 30 && p.isActive)) ...[
                    _section(_isSwahili ? 'Zinazoisha Hivi Karibuni' : 'Expiring Soon'),
                    const SizedBox(height: 8),
                    ..._policies
                        .where((p) => p.daysRemaining <= 30 && p.isActive)
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _expiryAlert(p),
                            )),
                    const SizedBox(height: 12),
                  ],

                  // Active policies
                  _section(_isSwahili ? 'Bima Zangu' : 'My Policies'),
                  const SizedBox(height: 8),
                  if (_policies.isEmpty)
                    _emptyState(
                        Icons.shield_rounded,
                        _isSwahili
                            ? 'Huna bima bado'
                            : 'No insurance policies yet')
                  else
                    ..._policies.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PolicyCard(policy: p, isSwahili: _isSwahili),
                        )),
                  const SizedBox(height: 16),

                  // Recent claims
                  _section(_isSwahili ? 'Madai' : 'Claims'),
                  const SizedBox(height: 8),
                  if (_claims.isEmpty)
                    _emptyState(Icons.description_rounded,
                        _isSwahili ? 'Hakuna madai' : 'No claims')
                  else
                    ..._claims.take(3).map((c) => _claimTile(c)),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }

  Widget _summaryBanner() {
    final active = _policies.where((p) => p.isActive).length;
    final expired = _policies.where((p) => p.isExpired).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _kPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(_isSwahili ? 'Bima ya Gari' : 'Car Insurance',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('$active', _isSwahili ? 'Hai' : 'Active'),
          const SizedBox(width: 20),
          _stat('$expired', _isSwahili ? 'Zimeisha' : 'Expired'),
          const SizedBox(width: 20),
          _stat('${_claims.length}', _isSwahili ? 'Madai' : 'Claims'),
        ]),
      ]),
    );
  }

  Widget _stat(String val, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(val,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]);
  }

  Widget _quickActions() {
    return Row(children: [
      _action(Icons.compare_rounded, _isSwahili ? 'Linganisha' : 'Compare',
          () => _nav(const GetQuotesPage())),
      const SizedBox(width: 10),
      _action(Icons.add_circle_outline_rounded,
          _isSwahili ? 'Dai Bima' : 'File Claim', () {
        if (_policies.where((p) => p.isActive).isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_isSwahili
                  ? 'Huna bima hai'
                  : 'No active policy to claim against')));
          return;
        }
        _nav(FileClaimPage(
            policies: _policies.where((p) => p.isActive).toList()));
      }),
    ]);
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Widget _expiryAlert(InsurancePolicy p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.warning_rounded, size: 20, color: Colors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${p.vehicleDisplay} — ${_isSwahili ? 'inaisha siku' : 'expires in'} ${p.daysRemaining}',
            style: const TextStyle(fontSize: 13, color: _kPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _claimTile(InsuranceClaim c) {
    final statusColor = c.status == 'approved' || c.status == 'settled'
        ? const Color(0xFF4CAF50)
        : c.status == 'rejected'
            ? Colors.red
            : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(Icons.description_rounded, size: 20, color: statusColor),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.claimNumber,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(c.type,
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(c.status.toUpperCase(),
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
        ),
      ]),
    );
  }

  Widget _section(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary));
  }

  Widget _emptyState(IconData icon, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(children: [
          Icon(icon, size: 40, color: _kSecondary),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(fontSize: 13, color: _kSecondary)),
        ]),
      ),
    );
  }
}

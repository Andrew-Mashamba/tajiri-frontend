// lib/nssf/pages/nssf_home_page.dart
import 'package:flutter/material.dart';
import '../models/nssf_models.dart';
import '../services/nssf_service.dart';
import 'contribution_history_page.dart';
import 'retirement_calculator_page.dart';
import 'employer_check_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NssfHomePage extends StatefulWidget {
  final int userId;
  const NssfHomePage({super.key, required this.userId});
  @override
  State<NssfHomePage> createState() => _NssfHomePageState();
}

class _NssfHomePageState extends State<NssfHomePage> {
  NssfMembership? _membership;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await NssfService.getMembership();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _membership = result.data; });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _load, color: _kPrimary,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Member card
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('NSSF MEMBER', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
              ]),
              const SizedBox(height: 12),
              if (_membership != null) ...[
                Text(_membership!.memberNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(children: [
                  _Stat(label: 'Michango', value: 'TZS ${(_membership!.totalContributions / 1000000).toStringAsFixed(1)}M'),
                  const SizedBox(width: 16),
                  _Stat(label: 'Miezi', value: '${_membership!.monthsContributed}'),
                ]),
                if (_membership!.employerName != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.business_rounded, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_membership!.employerName!, style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Icon(_membership!.employerCompliant ? Icons.check_circle_rounded : Icons.warning_rounded,
                        size: 14, color: _membership!.employerCompliant ? const Color(0xFF4CAF50) : Colors.orange),
                  ]),
                ],
              ] else
                const Text('Hakuna uanachama', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ])),
          const SizedBox(height: 20),

          Row(children: [
            _Act(icon: Icons.history_rounded, label: 'Historia ya\nMichango', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContributionHistoryPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.trending_up_rounded, label: 'Hesabu\nPensheni', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RetirementCalculatorPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.business_center_rounded, label: 'Angalia\nMwajiri', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EmployerCheckPage()))),
          ]),
          const SizedBox(height: 24),

          // Info
          _InfoTile(icon: Icons.people_rounded, title: 'Wasimamizi / Nominees',
              subtitle: 'Manage your beneficiaries', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wasimamizi / Nominees - coming soon')));
              }),
          const SizedBox(height: 8),
          _InfoTile(icon: Icons.description_rounded, title: 'Faida / Benefits',
              subtitle: 'Old age, invalidity, maternity, funeral', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Faida / Benefits info - coming soon')));
              }),
          const SizedBox(height: 8),
          _InfoTile(icon: Icons.person_add_rounded, title: 'Jiandikishe / Self-Employed',
              subtitle: 'Register for voluntary contributions', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jiandikishe / Registration - coming soon')));
              }),

          if (_loading) const Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
          const SizedBox(height: 32),
        ]));
  }
}

class _Stat extends StatelessWidget {
  final String label; final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}

class _Act extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _Act({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: _kPrimary)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ])))));
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: _kPrimary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
      ]))));
}

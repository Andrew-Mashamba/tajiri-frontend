import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../tajirika/services/membership_service.dart';

/// Spec F6 #43 — Drop-in vs membership view + ClassPass-style credits.
class ClassMembershipsPage extends StatefulWidget {
  final int userId;
  const ClassMembershipsPage({super.key, required this.userId});

  @override
  State<ClassMembershipsPage> createState() => _ClassMembershipsPageState();
}

class _ClassMembershipsPageState extends State<ClassMembershipsPage> {
  bool _loading = true;
  List<Membership> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await MembershipService.myMemberships(userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _useCredit(Membership m) async {
    final ok = await MembershipService.deductCredit(
      userId: widget.userId,
      membershipId: m.id,
      credits: 1,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Credit umetumika' : 'Imeshindikana')),
    );
    _load();
  }

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Pakiti za madarasa' : 'Class passes'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isSw
                          ? 'Hujajijiunga bado. Pata pakiti kwenye partner unayependa.'
                          : 'No passes yet. Subscribe via your favorite partner.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final m = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.partnerName ?? 'Partner ${m.partnerId}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                ),
                              ),
                              Text('TZS ${_fmt(m.priceTzs)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(m.plan, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          if (m.creditsRemaining != null) ...[
                            LinearProgressIndicator(
                              value: m.creditsTotal == null || m.creditsTotal == 0
                                  ? 0
                                  : (m.creditsRemaining! / m.creditsTotal!),
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEEEEEE),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isSw
                                  ? '${m.creditsRemaining}/${m.creditsTotal} credits zimebaki'
                                  : '${m.creditsRemaining}/${m.creditsTotal} credits left',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF666666)),
                            ),
                          ],
                          if (m.expiresAt != null)
                            Text(
                              isSw
                                  ? 'Inaisha ${m.expiresAt!.day}/${m.expiresAt!.month}/${m.expiresAt!.year}'
                                  : 'Expires ${m.expiresAt!.day}/${m.expiresAt!.month}/${m.expiresAt!.year}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF666666)),
                            ),
                          if ((m.creditsRemaining ?? 0) > 0) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.bolt_rounded, size: 14),
                              label: Text(isSw ? 'Tumia credit' : 'Use credit'),
                              onPressed: () => _useCredit(m),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

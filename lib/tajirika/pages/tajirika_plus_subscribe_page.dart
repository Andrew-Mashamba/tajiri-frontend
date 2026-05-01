import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../services/tajirika_plus_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

/// Partner-facing page to subscribe to Tajirika+.
class TajirikaPlusSubscribePage extends StatefulWidget {
  final int partnerUserId;
  const TajirikaPlusSubscribePage({super.key, required this.partnerUserId});

  @override
  State<TajirikaPlusSubscribePage> createState() => _TajirikaPlusSubscribePageState();
}

class _TajirikaPlusSubscribePageState extends State<TajirikaPlusSubscribePage> {
  List<TajirikaPlusPlan> _plans = [];
  TajirikaPlusStatus? _status;
  bool _loading = true;
  String? _error;
  bool _subscribing = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final plansRes = await TajirikaPlusService.getPlans();
    final statusRes = await TajirikaPlusService.getStatus(widget.partnerUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _plans = plansRes.plans ?? [];
      _status = statusRes.status;
      _error = plansRes.success ? null : (plansRes.message ?? statusRes.message);
    });
  }

  Future<void> _subscribe(String tier) async {
    setState(() => _subscribing = true);
    final res = await TajirikaPlusService.subscribe(
      partnerUserId: widget.partnerUserId,
      tier: tier,
    );
    if (!mounted) return;
    setState(() => _subscribing = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isSwahili ? 'Umefanikiwa kujiunga!' : 'Subscribed successfully!')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? (_isSwahili ? 'Imeshindwa' : 'Failed'))),
      );
    }
  }

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Tajirika+' : 'Tajirika+',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null && _plans.isEmpty
              ? Center(child: Text(_error!, style: const TextStyle(color: _kSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_status?.active == true) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFA000)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFA000)),
                                  const SizedBox(width: 8),
                                  Text(
                                    isSw ? 'Msimbo wako unaendelea' : 'Your subscription is active',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFA000),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${isSw ? 'Kipindi' : 'Tier'}: ${_status!.tier?.toUpperCase() ?? ''}',
                                style: const TextStyle(fontSize: 13, color: _kSecondary),
                              ),
                              if (_status!.expiresAt != null)
                                Text(
                                  '${isSw ? 'Inaisha' : 'Expires'}: ${_status!.expiresAt!.toLocal().toString().split(' ').first}',
                                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        isSw ? 'Chagua mpango wako' : 'Choose your plan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      const SizedBox(height: 16),
                      ..._plans.map((plan) => _planCard(plan, isSw)),
                    ],
                  ),
                ),
    );
  }

  Widget _planCard(TajirikaPlusPlan plan, bool isSw) {
    final isPro = plan.tier == 'pro';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPro ? const Color(0xFFFFA000) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPro ? Icons.workspace_premium_rounded : Icons.star_rounded,
                color: const Color(0xFFFFA000),
              ),
              const SizedBox(width: 8),
              Text(
                isSw ? plan.nameSw : plan.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmtTzs(plan.priceMonthlyTzs)} / ${isSw ? 'mwezi' : 'month'}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 12),
          ...((isSw ? plan.benefitsSw : plan.benefits)).map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b, style: const TextStyle(fontSize: 13, color: _kSecondary))),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subscribing ? null : () => _subscribe(plan.tier),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _subscribing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isSw ? 'Jiunga' : 'Subscribe'),
            ),
          ),
        ],
      ),
    );
  }
}

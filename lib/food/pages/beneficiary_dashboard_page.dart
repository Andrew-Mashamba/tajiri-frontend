import 'package:flutter/material.dart';

import '../models/beneficiary_org.dart';
import '../services/food_service.dart';
import 'post_need_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kWarn = Color(0xFFE67E22);

class BeneficiaryDashboardPage extends StatefulWidget {
  final int userId;
  const BeneficiaryDashboardPage({super.key, required this.userId});

  @override
  State<BeneficiaryDashboardPage> createState() => _BeneficiaryDashboardPageState();
}

class _BeneficiaryDashboardPageState extends State<BeneficiaryDashboardPage> {
  final FoodService _service = FoodService();
  BeneficiaryOrg? _org;
  List<Map<String, dynamic>> _incoming = const [];
  List<BeneficiaryNeed> _needs = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final mine = await _service.getMyBeneficiaryOrg(widget.userId);
    if (!mounted) return;
    if (!mine.success) {
      setState(() {
        _loading = false;
        _loadError = mine.message ?? 'Imeshindwa';
      });
      return;
    }
    final org = mine.data;
    if (org == null) {
      setState(() {
        _loading = false;
        _org = null;
      });
      return;
    }
    final incoming = await _service.incomingDonations(orgId: org.id, userId: widget.userId);
    final details = await _service.getBeneficiaryOrg(org.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _org = org;
      _incoming = incoming.success ? incoming.items : const [];
      _needs = details.success && details.data != null
          ? (details.data!['needs'] as List).cast<BeneficiaryNeed>()
          : const [];
    });
  }

  Future<void> _confirm(Map<String, dynamic> receipt) async {
    if (_org == null) return;
    final listingId = (receipt['listing_id'] as num?)?.toInt();
    if (listingId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.confirmReceipt(
      orgId: _org!.id,
      listingId: listingId,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Imethibitishwa. Risiti iko tayari.')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  Future<void> _closeNeed(BeneficiaryNeed n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Funga hitaji?', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
        content: Text('Hitaji "${n.title}" litaondolewa kwenye orodha.',
            style: const TextStyle(color: _kSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ndio, funga')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.closeBeneficiaryNeed(needId: n.id, userId: widget.userId);
    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Imefungwa')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text('Shirika Langu', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _loadError != null
              ? Center(child: Text(_loadError!, style: const TextStyle(color: _kSecondary)))
              : _org == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Huna shirika lililosajiliwa. Sajili kwanza.',
                            textAlign: TextAlign.center, style: TextStyle(color: _kSecondary)),
                      ),
                    )
                  : _body(_org!),
      floatingActionButton: _org != null && _org!.isVerified
          ? FloatingActionButton.extended(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              onPressed: _postNeed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tuma hitaji'),
            )
          : null,
    );
  }

  Future<void> _postNeed() async {
    if (_org == null) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostNeedPage(orgId: _org!.id, userId: widget.userId),
      ),
    );
    if (posted == true && mounted) _load();
  }

  Future<void> _togglePauseNeed(BeneficiaryNeed n) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = n.isPaused
        ? await _service.resumeBeneficiaryNeed(needId: n.id, userId: widget.userId)
        : await _service.pauseBeneficiaryNeed(needId: n.id, userId: widget.userId);
    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(SnackBar(content: Text(n.isPaused ? 'Imerudishwa' : 'Imesimamishwa')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  Widget _body(BeneficiaryOrg org) {
    final pending = _incoming.where((r) => r['status'] == 'pending').toList();
    final confirmed = _incoming.where((r) => r['status'] == 'confirmed').toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(org.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ),
                    if (org.isVerified)
                      const Icon(Icons.verified_rounded, color: _kAccent, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _stat('Mwezi', '${org.portionsReceivedMonth}')),
                    Expanded(child: _stat('Mwaka', '${org.portionsReceivedYear}')),
                    Expanded(child: _stat('Wafadhili', '${org.uniqueDonorsCount}')),
                  ],
                ),
                if (!org.isVerified) ...[
                  const SizedBox(height: 8),
                  Text(
                    org.isRejected
                        ? 'Imekataliwa: ${org.rejectionReason ?? "—"}'
                        : 'Inakaguliwa. Utaarifiwa itakapohakikiwa.',
                    style: const TextStyle(color: _kSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Zinazokuja (hazijathibitishwa)'),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Hamna bado', style: TextStyle(color: _kSecondary, fontSize: 13)),
            )
          else
            ...pending.map((r) => _incomingTile(r, actionable: true)),
          const SizedBox(height: 16),
          _sectionLabel('Zilizothibitishwa'),
          const SizedBox(height: 8),
          if (confirmed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Hamna bado', style: TextStyle(color: _kSecondary, fontSize: 13)),
            )
          else
            ...confirmed.take(20).map((r) => _incomingTile(r, actionable: false)),
          const SizedBox(height: 16),
          _sectionLabel('Mahitaji yangu'),
          const SizedBox(height: 8),
          if (_needs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Hamna mahitaji', style: TextStyle(color: _kSecondary, fontSize: 13)),
            )
          else
            ..._needs.map((n) => _needRow(n)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      );

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kSecondary,
          letterSpacing: 0.6,
        ),
      );

  Widget _incomingTile(Map<String, dynamic> r, {required bool actionable}) {
    final dish = r['dish_title']?.toString() ?? 'Chakula';
    final portions = (r['portions'] as num?)?.toInt() ?? 0;
    final donor = r['donor_name']?.toString() ?? 'Mfadhili';
    final pickup = r['pickup_address']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$dish · $portions milo',
              style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Kutoka kwa: $donor', style: const TextStyle(color: _kSecondary, fontSize: 12)),
          if (pickup.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(pickup, style: const TextStyle(color: _kSecondary, fontSize: 11)),
          ],
          if (actionable) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _confirm(r),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                child: const Text('Thibitisha upokeaji', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text('✓ Imethibitishwa', style: TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _needRow(BeneficiaryNeed n) {
    final dayShort = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final parts = <String>[];
    parts.add('${n.portionsRemaining}/${n.portionsNeeded} milo');
    if (n.isRecurring) {
      if (n.daysOfWeek.isNotEmpty) {
        final sorted = [...n.daysOfWeek]..sort();
        parts.add(sorted.map((i) => (i >= 0 && i < 7) ? dayShort[i] : '').where((s) => s.isNotEmpty).join(','));
      }
      if (n.durationWeeks != null) {
        parts.add('${n.durationWeeks} wk');
      } else {
        parts.add('bila mwisho');
      }
    } else if (n.dueDate != null) {
      parts.add(n.dueDate!.toLocal().toString().split(' ').first);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (n.isRecurring)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('KURUDIWA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kPrimary, letterSpacing: 0.5)),
                      ),
                    if (n.isPaused) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kWarn.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('IMESIMAMISHWA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kWarn, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  parts.join(' · '),
                  style: const TextStyle(color: _kSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: n.isPaused ? 'Rudisha' : 'Simamisha',
            icon: Icon(
              n.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: _kPrimary,
              size: 20,
            ),
            onPressed: () => _togglePauseNeed(n),
          ),
          IconButton(
            tooltip: 'Funga',
            icon: const Icon(Icons.close_rounded, color: _kWarn, size: 20),
            onPressed: () => _closeNeed(n),
          ),
        ],
      ),
    );
  }
}


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../calendar/models/calendar_models.dart';
import '../../calendar/services/calendar_service.dart';
import '../../screens/messages/chat_screen.dart';
import '../../services/message_service.dart';
import '../models/beneficiary_org.dart';
import '../models/food_preferences.dart';
import '../services/food_service.dart';
import 'cash_donation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

class BeneficiaryProfilePage extends StatefulWidget {
  final int orgId;
  final int userId;
  /// If true, shows "Select this beneficiary" CTA that pops with the org.
  final bool pickerMode;
  const BeneficiaryProfilePage({
    super.key,
    required this.orgId,
    required this.userId,
    this.pickerMode = false,
  });

  @override
  State<BeneficiaryProfilePage> createState() => _BeneficiaryProfilePageState();
}

class _BeneficiaryProfilePageState extends State<BeneficiaryProfilePage> {
  final FoodService _service = FoodService();
  final MessageService _messageService = MessageService();
  BeneficiaryOrg? _org;
  List<BeneficiaryNeed> _needs = const [];
  List<String> _gallery = const [];
  List<Map<String, dynamic>> _impactTimeline = const [];
  List<Map<String, dynamic>> _unifiedDonors = const [];
  int _galleryIndex = 0;
  bool _loading = true;
  String? _loadError;
  bool _openingChat = false;
  bool _isFollowing = false;
  int _followersCount = 0;
  bool _togglingFollow = false;
  FoodPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
    _loadFollowState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final res = await _service.getFoodPreferences(userId: widget.userId);
    if (!mounted || !res.success || res.data == null) return;
    setState(() => _prefs = res.data);
  }

  Future<void> _loadFollowState() async {
    final res = await _service.getBeneficiaryFollowState(
      orgId: widget.orgId,
      userId: widget.userId,
    );
    if (!mounted || !res.success || res.data == null) return;
    setState(() {
      _isFollowing = res.data!['following'] == true;
      _followersCount = (res.data!['followers'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> _toggleFollow() async {
    if (_togglingFollow) return;
    setState(() => _togglingFollow = true);
    final res = _isFollowing
        ? await _service.unfollowBeneficiaryOrg(orgId: widget.orgId, userId: widget.userId)
        : await _service.followBeneficiaryOrg(orgId: widget.orgId, userId: widget.userId);
    if (!mounted) return;
    setState(() => _togglingFollow = false);
    if (res.success && res.data != null) {
      setState(() {
        _isFollowing = res.data!['following'] == true;
        _followersCount = (res.data!['followers'] as num?)?.toInt() ?? _followersCount;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Imeshindwa')),
      );
    }
  }

  Future<void> _openReportSheet() async {
    final reasons = const [
      'Taarifa za uongo',
      'Ulaghai au wizi',
      'Haitumii michango vizuri',
      'Matukio ya udanganyifu',
      'Taarifa za mawasiliano si sahihi',
      'Nyingine',
    ];
    String selected = reasons.first;
    final detailCtrl = TextEditingController();
    final reported = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Ripoti shirika',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 4),
              const Text('Timu ya usalama itachunguza na kukujibu.',
                  style: TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reasons.map((r) {
                  final picked = selected == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: picked,
                    onSelected: (_) => setSheet(() => selected = r),
                    selectedColor: _kPrimary,
                    backgroundColor: _kCardBg,
                    side: BorderSide(color: _kPrimary.withValues(alpha: 0.15)),
                    labelStyle: TextStyle(
                      color: picked ? Colors.white : _kPrimary,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Maelezo (hiari)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await _service.reportBeneficiaryOrg(
                      orgId: widget.orgId,
                      userId: widget.userId,
                      reason: selected,
                      detail: detailCtrl.text.trim().isEmpty ? null : detailCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx, res.success);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tuma ripoti',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (reported == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ripoti imetumwa. Asante.')),
      );
    } else if (reported == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kutuma ripoti')),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final res = await _service.getBeneficiaryOrg(widget.orgId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final cashDonors =
          ((res.data!['recent_donors'] as List?) ?? const []).cast<Map<String, dynamic>>();
      final timeline =
          ((res.data!['impact_timeline'] as List?) ?? const []).cast<Map<String, dynamic>>();
      setState(() {
        _org = res.data!['org'] as BeneficiaryOrg;
        _needs = (res.data!['needs'] as List).cast<BeneficiaryNeed>();
        _gallery = ((res.data!['gallery'] as List?) ?? const []).cast<String>();
        _impactTimeline = timeline;
        _unifiedDonors = _buildUnifiedDonors(cashDonors, timeline);
        if (_galleryIndex >= _gallery.length) _galleryIndex = 0;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _loadError = res.message ?? 'Imeshindwa';
      });
    }
  }

  void _openDonate(BeneficiaryOrg org, {required bool institutional}) {
    final p = _prefs;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CashDonationPage(
          userId: widget.userId,
          org: org,
          institutional: institutional,
          prefillZaka: p?.resolveAutoTagZakat() ?? false,
          prefillFungu: p?.resolveAutoTagFungu() ?? false,
        ),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _openChatWithCoordinator() async {
    if (_org == null || _openingChat) return;
    if (_org!.userId == widget.userId) return;
    setState(() => _openingChat = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await _messageService.getPrivateConversation(widget.userId, _org!.userId);
    if (!mounted) return;
    setState(() => _openingChat = false);
    if (result.success && result.conversation != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: result.conversation!.id,
            currentUserId: widget.userId,
            conversation: result.conversation,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
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
        title: const Text('Shirika', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _loadError != null
              ? Center(child: Text(_loadError!, style: const TextStyle(color: _kSecondary)))
              : _body(_org!),
      bottomNavigationBar: (!widget.pickerMode || _org == null || !_org!.isVerified)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(context, _org),
                  child: const Text('Chagua shirika hili', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
    );
  }

  Widget _body(BeneficiaryOrg org) {
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _hero(org),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(org.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ),
                    if (org.isVerified)
                      const Icon(Icons.verified_rounded, color: _kAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(org.type.labelSwahili, style: const TextStyle(color: _kSecondary, fontSize: 13)),
                if (org.locationText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: _kSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(org.locationText,
                            style: const TextStyle(color: _kSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
                if (org.populationServed != null || org.mealsPerWeek != null) ...[
                  const SizedBox(height: 12),
                  _statsRow(org),
                ],
                if (org.description != null && org.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Kuhusu'),
                  const SizedBox(height: 4),
                  Text(org.description!, style: const TextStyle(color: _kPrimary, fontSize: 14, height: 1.4)),
                ],
                const SizedBox(height: 16),
                _sectionLabel('Kwa ujumla'),
                const SizedBox(height: 8),
                _runningTotals(org),
                if (_needs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Mahitaji ya sasa'),
                  const SizedBox(height: 8),
                  ..._needs.map(_needCard),
                ],
                if (_unifiedDonors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _recentDonorsSection(),
                ],
                if (_impactTimeline.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _impactTimelineSection(),
                ],
                const SizedBox(height: 16),
                if (org.userId != widget.userId) ...[
                  if (org.isVerified) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openDonate(org, institutional: false),
                            icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                            label: const Text('Changia', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDonate(org, institutional: true),
                            icon: const Icon(Icons.apartment_rounded, color: _kPrimary, size: 18),
                            label: const Text('Tumikia kikundi',
                                style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              side: BorderSide(color: _kPrimary.withValues(alpha: 0.35)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _togglingFollow ? null : _toggleFollow,
                          icon: _togglingFollow
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                              : Icon(
                                  _isFollowing
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_none_rounded,
                                  color: _kPrimary,
                                  size: 18,
                                ),
                          label: Text(
                            _isFollowing
                                ? 'Unafuatilia${_followersCount > 0 ? ' · $_followersCount' : ''}'
                                : 'Fuatilia${_followersCount > 0 ? ' · $_followersCount' : ''}',
                            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            side: BorderSide(
                              color: _isFollowing
                                  ? _kPrimary
                                  : _kPrimary.withValues(alpha: 0.15),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openingChat ? null : _openChatWithCoordinator,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: _kPrimary, size: 18),
                          label: const Text('Ujumbe',
                              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            side: BorderSide(color: _kPrimary.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _openReportSheet,
                    icon: const Icon(Icons.flag_outlined, size: 16, color: _kSecondary),
                    label: const Text('Ripoti shirika hili',
                        style: TextStyle(color: _kSecondary, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BeneficiaryOrg org) {
    final fallback = org.resolvedPhotoUrl;
    final urls = _gallery.isNotEmpty
        ? _gallery
        : (fallback.isEmpty ? const <String>[] : [fallback]);
    if (urls.isEmpty) {
      return Container(
        height: 220,
        color: _kPrimary.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: const Icon(Icons.volunteer_activism_rounded, size: 64, color: _kSecondary),
      );
    }
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _galleryIndex = i),
            itemBuilder: (ctx, i) => CachedNetworkImage(
              imageUrl: urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorWidget: (_, _, _) => Container(
                color: _kPrimary.withValues(alpha: 0.06),
                alignment: Alignment.center,
                child: const Icon(Icons.volunteer_activism_rounded, size: 64, color: _kSecondary),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _galleryIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// Merge cash donors with pledge contributors from the impact timeline so
  /// the panel reflects all recent supporters, not just cash. Cash entries
  /// carry richer fields (avatar, masked name, is_institutional); pledge
  /// entries enrich from a name-keyed lookup when the same donor also gave
  /// cash.
  List<Map<String, dynamic>> _buildUnifiedDonors(
    List<Map<String, dynamic>> cashDonors,
    List<Map<String, dynamic>> timeline,
  ) {
    final cashByName = <String, Map<String, dynamic>>{
      for (final d in cashDonors) (d['name_masked'] ?? '').toString(): d,
    };
    final unified = <Map<String, dynamic>>[];

    for (final d in cashDonors) {
      unified.add({
        'type': 'cash',
        'name_masked': d['name_masked'] ?? 'Mtoaji',
        'avatar_url': d['avatar_url'],
        'is_institutional': d['is_institutional'] == true,
        'amount': (d['amount'] as num?)?.toDouble() ?? 0,
        'occurred_at': d['donated_at'] ?? d['occurred_at'],
      });
    }

    for (final t in timeline) {
      if (t['type'] != 'pledge') continue;
      final name = (t['donor_name'] ?? 'Mtoaji').toString();
      final cashMatch = cashByName[name];
      unified.add({
        'type': 'pledge',
        'name_masked': name,
        'avatar_url': cashMatch?['avatar_url'],
        'is_institutional': cashMatch?['is_institutional'] == true,
        'portions': (t['portions'] as num?)?.toInt() ?? 0,
        'occurred_at': t['occurred_at'],
      });
    }

    unified.sort((a, b) {
      final ad = DateTime.tryParse(a['occurred_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse(b['occurred_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return unified;
  }

  Widget _recentDonorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Wafadhili wa karibuni'),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _unifiedDonors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _donorChip(_unifiedDonors[i]),
          ),
        ),
      ],
    );
  }

  Widget _donorChip(Map<String, dynamic> d) {
    final name = (d['name_masked'] ?? 'Mtoaji').toString();
    final type = (d['type'] ?? 'cash').toString();
    final isPledge = type == 'pledge';
    final amount = (d['amount'] as num?)?.toDouble() ?? 0;
    final portions = (d['portions'] as num?)?.toInt() ?? 0;
    final avatar = d['avatar_url']?.toString();
    final isInst = d['is_institutional'] == true;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              image: (avatar != null && avatar.isNotEmpty)
                  ? DecorationImage(image: CachedNetworkImageProvider(avatar), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: (avatar == null || avatar.isEmpty)
                ? Icon(
                    isInst ? Icons.apartment_rounded : Icons.person_rounded,
                    size: 22,
                    color: _kSecondary,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600),
          ),
          Text(
            isPledge ? 'Milo $portions' : 'TZS ${_fmtThousands(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
          ),
        ],
      ),
    );
  }

  Widget _impactTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Athari za karibuni'),
        const SizedBox(height: 8),
        ..._impactTimeline.map(_timelineRow),
      ],
    );
  }

  Widget _timelineRow(Map<String, dynamic> e) {
    final type = e['type']?.toString() ?? 'cash';
    final donor = (e['donor_name'] ?? 'Mtoaji').toString();
    final occurredAt = _parseDate(e['occurred_at']?.toString());
    final isCash = type == 'cash';
    final summary = isCash
        ? 'Alichanga TZS ${_fmtThousands((e['amount'] as num?)?.toDouble() ?? 0)}'
        : 'Alitimiza milo ${e['portions'] ?? 0}'
            '${(e['need_title'] ?? '').toString().isEmpty ? '' : ' · ${e['need_title']}'}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (isCash ? _kAccent : _kPrimary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isCash ? Icons.payments_rounded : Icons.restaurant_rounded,
              size: 14,
              color: isCash ? _kAccent : _kPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text(summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
          if (occurredAt != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(_relativeTime(occurredAt),
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ),
        ],
      ),
    );
  }

  String _fmtThousands(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when.toLocal());
    if (diff.inMinutes < 1) return 'sasa';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    if (diff.inDays < 7) return '${diff.inDays}sk';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}wk';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mz';
    return '${(diff.inDays / 365).floor()}mk';
  }

  Widget _statsRow(BeneficiaryOrg org) {
    return Row(
      children: [
        if (org.populationServed != null)
          Expanded(child: _stat('Watu', '${org.populationServed}')),
        if (org.mealsPerWeek != null)
          Expanded(child: _stat('Milo/wiki', '${org.mealsPerWeek}')),
      ],
    );
  }

  Widget _runningTotals(BeneficiaryOrg org) {
    return Row(
      children: [
        Expanded(child: _stat('Mwezi', '${org.portionsReceivedMonth}')),
        Expanded(child: _stat('Mwaka', '${org.portionsReceivedYear}')),
        Expanded(child: _stat('Wafadhili', '${org.uniqueDonorsCount}')),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kSecondary,
          letterSpacing: 0.6,
        ),
      );

  Widget _needCard(BeneficiaryNeed n) {
    final canPledge = _org != null && _org!.userId != widget.userId && n.portionsRemaining > 0;
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
          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 14)),
          if (n.description != null && n.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(n.description!, style: const TextStyle(color: _kSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Text(
            'Mahitaji: ${n.portionsRemaining}/${n.portionsNeeded} milo'
            '${n.dueDate == null ? '' : ' · Ifikapo: ${n.dueDate!.toLocal().toString().split(' ').first}'}',
            style: const TextStyle(color: _kSecondary, fontSize: 11),
          ),
          if (canPledge) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPledgeSheet(n),
                icon: const Icon(Icons.volunteer_activism_rounded, size: 16, color: Colors.white),
                label: const Text('Nitatimiza hitaji hili', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openPledgeSheet(BeneficiaryNeed need) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PledgeSheet(
        need: need,
        service: _service,
        userId: widget.userId,
        onPledged: () {
          if (mounted) _load();
        },
      ),
    );
  }
}

class _PledgeSheet extends StatefulWidget {
  final BeneficiaryNeed need;
  final FoodService service;
  final int userId;
  final VoidCallback onPledged;

  const _PledgeSheet({
    required this.need,
    required this.service,
    required this.userId,
    required this.onPledged,
  });

  @override
  State<_PledgeSheet> createState() => _PledgeSheetState();
}

class _PledgeSheetState extends State<_PledgeSheet> {
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late int _portions;
  DateTime? _deliveryDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _portions = widget.need.portionsRemaining > 0
        ? (widget.need.portionsRemaining > 10 ? 10 : widget.need.portionsRemaining)
        : 1;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? (widget.need.dueDate ?? now.add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await widget.service.createNeedPledge(
      needId: widget.need.id,
      donorUserId: widget.userId,
      portions: _portions,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      deliveryDate: _deliveryDate,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      _dropPledgeCalendarEvent();
      navigator.pop();
      widget.onPledged();
      messenger.showSnackBar(
        const SnackBar(content: Text('Ahadi yako imepokelewa. Shirika litakupigia simu.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kutuma ahadi')),
      );
    }
  }

  void _dropPledgeCalendarEvent() {
    final need = widget.need;
    final scheduled = _deliveryDate ?? need.dueDate;
    if (scheduled == null) return;
    final repeat = need.isRecurring ? EventRepeat.weekly : EventRepeat.none;
    final event = CalendarEvent(
      id: 0,
      userId: widget.userId,
      title: 'Mchango: ${need.title}',
      date: DateTime(scheduled.year, scheduled.month, scheduled.day),
      isAllDay: true,
      repeat: repeat,
      reminder: EventReminder.hour1,
      notes: 'Milo $_portions kwa shirika',
      source: EventSource.personal,
    );
    CalendarService().createEvent(event).catchError(
        (_) => CalendarResult<CalendarEvent>(success: false));
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.need.portionsRemaining;
    final maxPortions = remaining + 50;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Nitatimiza hitaji',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(widget.need.title,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 4),
          Text('Yanayohitajika: $remaining milo',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const SizedBox(height: 16),
          const Text('Milo ngapi utatoa?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepBtn(Icons.remove_rounded, () {
                if (_portions > 1) setState(() => _portions--);
              }),
              Expanded(
                child: Center(
                  child: Text('$_portions',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
              ),
              _stepBtn(Icons.add_rounded, () {
                if (_portions < maxPortions) setState(() => _portions++);
              }),
            ],
          ),
          if (_portions > remaining) ...[
            const SizedBox(height: 4),
            Text('Utatoa zaidi ya mahitaji. Shirika litachagua cha kufanya na ziada.',
                style: TextStyle(fontSize: 11, color: _kPrimary.withValues(alpha: 0.7))),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDec('Namba ya simu (hiari)', hint: '+255...'),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 18, color: _kSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _deliveryDate == null
                          ? 'Tarehe ya kufikisha (hiari)'
                          : 'Nitafikisha: ${_deliveryDate!.toLocal().toString().split(' ').first}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _deliveryDate == null ? _kSecondary : _kPrimary,
                      ),
                    ),
                  ),
                  if (_deliveryDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _deliveryDate = null),
                      child: const Icon(Icons.close_rounded, size: 16, color: _kSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: _inputDec('Maelezo (hiari)', hint: 'k.m. Nitaleta wali na maharage'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tuma ahadi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _kPrimary, size: 20),
      ),
    );
  }

  InputDecoration _inputDec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

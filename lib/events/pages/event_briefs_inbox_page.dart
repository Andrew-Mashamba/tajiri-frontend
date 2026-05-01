import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/event_quote_request_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCardBg = Colors.white;
const Color _kBorder = Color(0xFFE0E0E0);

/// Partner-side inbox of open event briefs that match the partner's skill
/// categories. Tap a brief → bid sheet → submit. Spec line 1018.
class EventBriefsInboxPage extends StatefulWidget {
  final int partnerUserId;

  const EventBriefsInboxPage({super.key, required this.partnerUserId});

  @override
  State<EventBriefsInboxPage> createState() => _EventBriefsInboxPageState();
}

class _EventBriefsInboxPageState extends State<EventBriefsInboxPage> {
  List<EventQuoteRequest> _briefs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await EventQuoteRequestService.list(
      userId: widget.partnerUserId,
      role: 'partner',
      status: 'open',
    );
    if (!mounted) return;
    setState(() {
      _briefs = list;
      _loading = false;
    });
  }

  Future<void> _openBidSheet(EventQuoteRequest brief) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _BidSheet(
        brief: brief,
        partnerUserId: widget.partnerUserId,
      ),
    );
    if (submitted == true) {
      // Remove the briefed-on item from local list (one bid per partner per
      // brief — server enforces unique constraint).
      setState(() {
        _briefs = _briefs.where((b) => b.id != brief.id).toList();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          sw ? 'Maombi ya hafla' : 'Open event briefs',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _briefs.isEmpty
              ? _buildEmpty(sw)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: _briefs.length,
                    itemBuilder: (_, i) => _buildCard(_briefs[i], sw),
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool sw) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.inbox_outlined, size: 56, color: _kSecondary),
          const SizedBox(height: 12),
          Center(
            child: Text(
              sw ? 'Hakuna maombi mapya' : 'No open briefs',
              style: const TextStyle(fontSize: 15, color: _kSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                sw
                    ? 'Tutakujulisha mara ombi jipya linapowekwa kwenye huduma yako.'
                    : 'We\'ll notify you when a new brief in your skills is posted.',
                style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(EventQuoteRequest b, bool sw) {
    final fmt = DateFormat('d MMM, HH:mm', sw ? 'sw' : 'en');
    final remaining = b.expiresAt.difference(DateTime.now());
    final urgent = remaining.inHours < 6;

    return GestureDetector(
      onTap: () => _openBidSheet(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.eventTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgent ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgent
                        ? (sw ? '< 6 saa' : '< 6h')
                        : (sw ? '${remaining.inHours} saa' : '${remaining.inHours}h'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: urgent ? const Color(0xFFB00020) : const Color(0xFF0D47A1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(_kindLabel(b.eventKind, sw)),
                const SizedBox(width: 6),
                _chip(_skillLabel(b.skillCategory, sw)),
              ],
            ),
            const SizedBox(height: 10),
            _row(Icons.event_outlined, fmt.format(b.eventStartsAt)),
            if (b.eventAddress != null && b.eventAddress!.isNotEmpty)
              _row(Icons.place_outlined, b.eventAddress!),
            _row(Icons.group_outlined, sw ? '${b.partySize} wageni' : '${b.partySize} guests'),
            if (b.budgetMaxTzs != null || b.budgetMinTzs != null)
              _row(Icons.payments_outlined, _formatBudget(b.budgetMinTzs, b.budgetMaxTzs, sw)),
            if (b.description != null && b.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                b.description!,
                style: const TextStyle(fontSize: 12.5, color: _kSecondary, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5, color: _kSecondary)),
          ),
        ],
      ),
    );
  }

  String _kindLabel(String kind, bool sw) {
    const swMap = {
      'wedding': 'Harusi',
      'birthday': 'Sherehe ya kuzaliwa',
      'corporate': 'Hafla ya kampuni',
      'graduation': 'Mahafali',
      'safari': 'Safari',
      'other': 'Nyingine',
    };
    const enMap = {
      'wedding': 'Wedding',
      'birthday': 'Birthday',
      'corporate': 'Corporate',
      'graduation': 'Graduation',
      'safari': 'Safari',
      'other': 'Other',
    };
    return (sw ? swMap[kind] : enMap[kind]) ?? kind;
  }

  String _skillLabel(String skill, bool sw) {
    const swMap = {
      'djing': 'DJ',
      'mc': 'Mtangazaji',
      'photography': 'Picha',
      'videography': 'Video',
      'eventPlanning': 'Upangaji',
      'catering': 'Upishi',
      'baking': 'Keki',
      'makeup': 'Make-up',
      'tourGuide': 'Mwongozaji',
      'travelAgent': 'Wakala',
      'safariOperator': 'Opareta',
    };
    const enMap = {
      'djing': 'DJ',
      'mc': 'MC',
      'photography': 'Photo',
      'videography': 'Video',
      'eventPlanning': 'Planning',
      'catering': 'Catering',
      'baking': 'Cake',
      'makeup': 'Make-up',
      'tourGuide': 'Tour guide',
      'travelAgent': 'Travel',
      'safariOperator': 'Safari',
    };
    return (sw ? swMap[skill] : enMap[skill]) ?? skill;
  }

  String _formatBudget(int? min, int? max, bool sw) {
    String fmt(int n) {
      final s = n.toString();
      final sb = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
        sb.write(s[i]);
      }
      return sb.toString();
    }

    if (min != null && max != null) return 'TZS ${fmt(min)}–${fmt(max)}';
    if (max != null) return sw ? 'Hadi TZS ${fmt(max)}' : 'Up to TZS ${fmt(max)}';
    if (min != null) return sw ? 'Kuanzia TZS ${fmt(min)}' : 'From TZS ${fmt(min)}';
    return '';
  }
}

// ── Bid sheet (inline private widget) ────────────────────────────────

class _BidSheet extends StatefulWidget {
  final EventQuoteRequest brief;
  final int partnerUserId;

  const _BidSheet({required this.brief, required this.partnerUserId});

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  final _totalCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _pitchCtrl = TextEditingController();
  bool _submitting = false;
  String? _err;

  @override
  void dispose() {
    _totalCtrl.dispose();
    _depositCtrl.dispose();
    _pitchCtrl.dispose();
    super.dispose();
  }

  bool get _valid => (int.tryParse(_totalCtrl.text.trim()) ?? 0) > 0;

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() {
      _submitting = true;
      _err = null;
    });
    final ok = await EventQuoteRequestService.bid(
      requestId: widget.brief.id,
      partnerUserId: widget.partnerUserId,
      bidTotalTzs: int.parse(_totalCtrl.text.trim()),
      bidDepositTzs: int.tryParse(_depositCtrl.text.trim()),
      pitch: _pitchCtrl.text.trim().isEmpty ? null : _pitchCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _err = 'Imeshindikana. Jaribu tena.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? true;
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mq.viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              sw ? 'Tuma ofa yako' : 'Submit your bid',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.brief.eventTitle,
              style: const TextStyle(fontSize: 13.5, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Text(
              sw ? 'Bei ya jumla (TZS) *' : 'Total price (TZS) *',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            _input(_totalCtrl, sw ? 'Mfano: 800000' : 'e.g. 800000', isNumeric: true),
            const SizedBox(height: 14),
            Text(
              sw ? 'Amana ya kuhifadhi (hiari)' : 'Deposit to hold (optional)',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            _input(_depositCtrl, sw ? 'Mfano: 200000' : 'e.g. 200000', isNumeric: true),
            const SizedBox(height: 14),
            Text(
              sw ? 'Maelezo (kwa nini wewe?)' : 'Pitch (why you?)',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            _input(
              _pitchCtrl,
              sw
                  ? 'Mfano: Niko na uzoefu wa miaka 5, vifaa vya kitaalamu, na nimefanya harusi 30+ Dar.'
                  : 'e.g. 5 years experience, professional gear, 30+ weddings in Dar.',
              maxLines: 4,
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFB00020))),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _valid && !_submitting ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  disabledBackgroundColor: const Color(0xFFCCCCCC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        sw ? 'Tuma ofa' : 'Submit bid',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String hint, {
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: c,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.multiline,
        inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

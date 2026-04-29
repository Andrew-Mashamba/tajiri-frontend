import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../engagements/models/engagement.dart';
import '../../engagements/services/engagement_service.dart';
import '../../engagements/widgets/ai_brief_sheet.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Partner-side proposal form (spec §8 lines 762–771).
/// Customer gets pushed a notification; reviews via engagement_proposal_review_page.
class ProposeEngagementPage extends StatefulWidget {
  /// `userId` is the partner sending the proposal.
  final int userId;

  /// Optional pre-selected customer (e.g. from in-chat shortcut).
  final int? presetCustomerUserId;
  final String? presetCustomerName;

  const ProposeEngagementPage({
    super.key,
    required this.userId,
    this.presetCustomerUserId,
    this.presetCustomerName,
  });

  @override
  State<ProposeEngagementPage> createState() => _ProposeEngagementPageState();
}

class _MilestoneDraft {
  final TextEditingController titleCtrl;
  final TextEditingController amountCtrl;
  DateTime? dueDate;
  _MilestoneDraft()
      : titleCtrl = TextEditingController(),
        amountCtrl = TextEditingController();
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
  }
}

class _ProposeEngagementPageState extends State<ProposeEngagementPage> {
  int? _customerUserId;
  String? _customerName;
  // Customer "search" is v1 = manual user-ID entry. A dedicated /users/search
  // endpoint lands when the customer-discovery foundational feature ships.

  final _titleCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();
  EngagementContractType _contractType = EngagementContractType.fixedPrice;
  final _hourlyCtrl = TextEditingController();
  final _retainerCtrl = TextEditingController();
  final _fixedCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _ndaRequired = false;

  final List<_MilestoneDraft> _milestones = [];

  bool _submitting = false;
  String? _submitError;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _customerUserId = widget.presetCustomerUserId;
    _customerName = widget.presetCustomerName;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _scopeCtrl.dispose();
    _hourlyCtrl.dispose();
    _retainerCtrl.dispose();
    _fixedCtrl.dispose();
    for (final m in _milestones) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate?.add(const Duration(days: 30)) ?? now.add(const Duration(days: 30)),
      firstDate: _startDate ?? now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickMilestoneDue(_MilestoneDraft m) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: m.dueDate ?? _startDate ?? now.add(const Duration(days: 30)),
      firstDate: _startDate ?? now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => m.dueDate = picked);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_customerUserId == null) {
      _toast(_isSwahili ? 'Chagua mteja' : 'Pick a customer');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _toast(_isSwahili ? 'Andika kichwa' : 'Enter a title');
      return;
    }
    if (_scopeCtrl.text.trim().length < 30) {
      _toast(_isSwahili ? 'Eleza kazi vizuri (≥30)' : 'Describe scope (≥30 chars)');
      return;
    }
    if (_startDate == null) {
      _toast(_isSwahili ? 'Chagua tarehe ya kuanza' : 'Pick a start date');
      return;
    }
    int? hourly, retainer, fixed;
    switch (_contractType) {
      case EngagementContractType.hourly:
        hourly = int.tryParse(_hourlyCtrl.text.replaceAll(',', '').trim());
        if (hourly == null || hourly <= 0) {
          _toast(_isSwahili ? 'Andika gharama kwa saa' : 'Enter hourly rate');
          return;
        }
        break;
      case EngagementContractType.retainer:
        retainer = int.tryParse(_retainerCtrl.text.replaceAll(',', '').trim());
        if (retainer == null || retainer <= 0) {
          _toast(_isSwahili ? 'Andika mkataba wa mwezi' : 'Enter monthly retainer');
          return;
        }
        break;
      case EngagementContractType.fixedPrice:
        fixed = int.tryParse(_fixedCtrl.text.replaceAll(',', '').trim());
        if (fixed == null || fixed <= 0) {
          _toast(_isSwahili ? 'Andika bei thabiti' : 'Enter fixed total');
          return;
        }
        break;
      case EngagementContractType.productized:
        _toast(_isSwahili
            ? 'Aina ya bidhaa itaongezwa baadaye'
            : 'Productized contract type ships in a follow-up');
        return;
    }

    final ms = <Map<String, dynamic>>[];
    for (final m in _milestones) {
      final t = m.titleCtrl.text.trim();
      final a = int.tryParse(m.amountCtrl.text.replaceAll(',', '').trim());
      if (t.isEmpty || a == null || a < 0) continue;
      ms.add({
        'title': t,
        'amount_tzs': a,
        if (m.dueDate != null) 'due_date': m.dueDate!.toIso8601String().split('T').first,
      });
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final res = await EngagementService.create(
      userId: _customerUserId!,
      partnerUserId: widget.userId,
      title: _titleCtrl.text.trim(),
      scopeBrief: _scopeCtrl.text.trim(),
      contractType: _contractType,
      hourlyRateTzs: hourly,
      retainerTzs: retainer,
      fixedTotalTzs: fixed,
      startDate: _startDate!,
      endDate: _endDate,
      ndaRequired: _ndaRequired,
      milestones: ms.isEmpty ? null : ms,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.engagement != null) {
      _toast(_isSwahili
          ? 'Pendekezo limetumwa kwa ${_customerName ?? "mteja"}'
          : 'Proposal sent to ${_customerName ?? "customer"}');
      Navigator.of(context).pop(res.engagement);
    } else {
      setState(() => _submitError = res.message ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Pendekezo Mpya' : 'New Proposal',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _customerSection(),
            const SizedBox(height: 12),
            _aiBriefBanner(),
            const SizedBox(height: 16),
            _section(
              title: _isSwahili ? 'Kichwa' : 'Title',
              child: TextField(
                controller: _titleCtrl,
                maxLength: 255,
                decoration: _input(_isSwahili
                    ? 'Mfano: Kuhakiki vitabu vya Mama Mboga kwa mwezi'
                    : 'e.g. Monthly bookkeeping for Mama Mboga'),
              ),
            ),
            _section(
              title: _isSwahili ? 'Wigo wa kazi' : 'Scope brief',
              subtitle: _isSwahili
                  ? 'Eleza kinachofanyika, kisichofanyika, na deliverables (≥30 herufi)'
                  : 'In scope, out of scope, deliverables (≥30 chars)',
              child: TextField(
                controller: _scopeCtrl,
                minLines: 4,
                maxLines: 10,
                maxLength: 5000,
                decoration: _input(_isSwahili ? 'Maelezo...' : 'Details...'),
              ),
            ),
            _section(
              title: _isSwahili ? 'Aina ya mkataba' : 'Contract type',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EngagementContractType.values.map((t) {
                  final selected = _contractType == t;
                  return ChoiceChip(
                    avatar: Icon(t.icon, size: 16, color: selected ? Colors.white : _kPrimary),
                    label: Text(_isSwahili ? t.labelSwahili : t.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _contractType = t),
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
            _pricingField(),
            _section(
              title: _isSwahili ? 'Tarehe' : 'Dates',
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.event_rounded, size: 16),
                      label: Text(_startDate == null
                          ? (_isSwahili ? 'Anza' : 'Start')
                          : DateFormat('d MMM y').format(_startDate!)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kBorder),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.event_available_rounded, size: 16),
                      label: Text(_endDate == null
                          ? (_isSwahili ? 'Maliza (hiari)' : 'End (optional)')
                          : DateFormat('d MMM y').format(_endDate!)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _ndaRequired,
              onChanged: (v) => setState(() => _ndaRequired = v),
              title: Text(_isSwahili ? 'Inahitaji NDA' : 'Requires NDA',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            _milestonesSection(),
            const SizedBox(height: 12),
            if (_submitError != null) ...[
              Text(_submitError!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_isSwahili ? 'Tuma pendekezo' : 'Send proposal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAiBrief() async {
    final brief = await AiBriefSheet.show(context);
    if (brief == null || !mounted) return;
    setState(() {
      // Prefer the localised title; fall back to the other language.
      final title = _isSwahili
          ? (brief.titleSw.isNotEmpty ? brief.titleSw : brief.titleEn)
          : (brief.titleEn.isNotEmpty ? brief.titleEn : brief.titleSw);
      _titleCtrl.text = title;
      final scope = _isSwahili
          ? (brief.scopeSw.isNotEmpty ? brief.scopeSw : brief.scopeEn)
          : (brief.scopeEn.isNotEmpty ? brief.scopeEn : brief.scopeSw);
      final scopeWithDeliverables = StringBuffer(scope);
      if (brief.deliverables.isNotEmpty) {
        scopeWithDeliverables.write('\n\n');
        scopeWithDeliverables.write(_isSwahili ? 'Deliverables:' : 'Deliverables:');
        for (final d in brief.deliverables) {
          scopeWithDeliverables.write('\n• $d');
        }
      }
      _scopeCtrl.text = scopeWithDeliverables.toString();
      switch (brief.contractType) {
        case 'hourly':
          _contractType = EngagementContractType.hourly;
          break;
        case 'retainer':
          _contractType = EngagementContractType.retainer;
          break;
        default:
          _contractType = EngagementContractType.fixedPrice;
      }
      // Map AI milestones -> form drafts (replace existing).
      for (final m in _milestones) {
        m.dispose();
      }
      _milestones.clear();
      for (final m in brief.milestones.take(10)) {
        final draft = _MilestoneDraft();
        draft.titleCtrl.text = m.title;
        draft.amountCtrl.text = m.amountTzs.toString();
        _milestones.add(draft);
      }
      // Suggest end date from timeline_days.
      if (brief.timelineDays > 0) {
        _startDate ??= DateTime.now().add(const Duration(days: 1));
        _endDate = _startDate!.add(Duration(days: brief.timelineDays));
      }
      // Preload fixed-total estimate from the AI band midpoint.
      if (brief.contractType == 'fixed_price' &&
          brief.budgetBandLowTzs > 0 &&
          brief.budgetBandHighTzs > 0) {
        final mid = (brief.budgetBandLowTzs + brief.budgetBandHighTzs) ~/ 2;
        _fixedCtrl.text = mid.toString();
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Muhtasari umejazwa. Hariri kabla ya kutuma.'
            : 'Brief applied. Review before submitting.'),
      ));
    }
  }

  Widget _aiBriefBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 18, color: Color(0xFF0D47A1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSwahili
                  ? 'Hauna uhakika? Andika lengo lako kwa mstari mmoja na AI ikutengenezee muhtasari kamili.'
                  : 'Not sure where to start? Describe your goal in one line — AI drafts the full brief.',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: _runAiBrief,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isSwahili ? 'Tengeneza' : 'Generate',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerSection() {
    if (widget.presetCustomerUserId != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, size: 18, color: _kPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.presetCustomerName ??
                    '#${widget.presetCustomerUserId} (${_isSwahili ? "Mteja" : "Customer"})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
          ],
        ),
      );
    }
    return _section(
      title: _isSwahili ? 'Mteja (ID)' : 'Customer (user ID)',
      subtitle: _isSwahili
          ? 'Ingiza nambari ya kitambulisho. Utafutaji wa wateja unakuja baadaye.'
          : 'Enter the user ID. Customer search arrives in a follow-up.',
      child: TextField(
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _input(_isSwahili ? 'Mfano: 2' : 'e.g. 2'),
        onChanged: (v) => setState(() {
          _customerUserId = int.tryParse(v.trim());
          _customerName = null;
        }),
      ),
    );
  }

  Widget _pricingField() {
    switch (_contractType) {
      case EngagementContractType.hourly:
        return _section(
          title: _isSwahili ? 'Gharama kwa saa (TZS)' : 'Hourly rate (TZS)',
          child: TextField(
            controller: _hourlyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _input('e.g. 50000'),
          ),
        );
      case EngagementContractType.retainer:
        return _section(
          title: _isSwahili ? 'Mkataba wa mwezi (TZS)' : 'Monthly retainer (TZS)',
          child: TextField(
            controller: _retainerCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _input('e.g. 250000'),
          ),
        );
      case EngagementContractType.fixedPrice:
        return _section(
          title: _isSwahili ? 'Bei thabiti (TZS)' : 'Fixed total (TZS)',
          child: TextField(
            controller: _fixedCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _input('e.g. 600000'),
          ),
        );
      case EngagementContractType.productized:
        return _section(
          title: _isSwahili ? 'Bidhaa' : 'Productized',
          subtitle: _isSwahili
              ? 'Aina hii itaongezwa baadaye (inategemea bidhaa za mshirika).'
              : 'Productized contracts ship in a follow-up — they need a partner_product picker.',
          child: const SizedBox.shrink(),
        );
    }
  }

  Widget _milestonesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSwahili ? 'Hatua (hiari)' : 'Milestones (optional)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _milestones.add(_MilestoneDraft())),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(_isSwahili ? 'Ongeza' : 'Add'),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ],
          ),
          ..._milestones.asMap().entries.map((e) => _milestoneTile(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _milestoneTile(int index, _MilestoneDraft m) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_isSwahili ? "Hatua" : "Milestone"} ${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    m.dispose();
                    _milestones.removeAt(index);
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: _isSwahili ? 'Ondoa' : 'Remove',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: m.titleCtrl,
            decoration: _input(_isSwahili ? 'Kichwa' : 'Title'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: m.amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(_isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickMilestoneDue(m),
                  icon: const Icon(Icons.event_rounded, size: 14),
                  label: Text(m.dueDate == null
                      ? (_isSwahili ? 'Tarehe' : 'Due')
                      : DateFormat('d MMM').format(m.dueDate!)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, String? subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
          ],
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/partner_availability.dart';
import '../models/tajirika_models.dart';
import '../services/partner_availability_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

const List<int> _kSlotMinutesOptions = [15, 30, 45, 60];
const List<String> _kWeekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const List<String> _kWeekdayLabelsSwahili = ['Jumapili', 'Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi'];

/// Spec §12 entry — Tajirika home → "Muda Wangu".
/// Two tabs (Weekly hours + Blackouts), scoped via the optional skill picker.
class ManageAvailabilityPage extends StatefulWidget {
  final int userId;
  /// Partner's registered skills (used by the scope picker). When empty we
  /// hide the picker and edit Default scope only.
  final List<SkillCategory> skills;

  const ManageAvailabilityPage({
    super.key,
    required this.userId,
    this.skills = const [],
  });

  @override
  State<ManageAvailabilityPage> createState() => _ManageAvailabilityPageState();
}

class _ManageAvailabilityPageState extends State<ManageAvailabilityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  /// null = Default scope
  String? _scope;
  bool _loading = true;
  List<PartnerAvailability> _hours = const [];
  List<PartnerBlackout> _blackouts = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  bool get _hasMultipleSkills => widget.skills.length >= 2;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hoursF = PartnerAvailabilityService.listHours(
      partnerUserId: widget.userId,
      skillCategory: _scope,
    );
    final blackoutsF = PartnerAvailabilityService.listBlackouts(
      partnerUserId: widget.userId,
    );
    final hoursRes = await hoursF;
    final blackoutsRes = await blackoutsF;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hours = hoursRes.items;
      _blackouts = blackoutsRes.items;
    });
  }

  /// Returns the row to render for a given weekday under the current scope.
  /// When viewing a per-skill scope, the per-skill row beats Default.
  PartnerAvailability? _rowFor(int weekday) {
    PartnerAvailability? def;
    PartnerAvailability? skillRow;
    for (final h in _hours) {
      if (h.weekday != weekday) continue;
      if (h.isDefault) def = h;
      if (_scope != null && h.skillCategory == _scope) skillRow = h;
    }
    if (_scope != null && skillRow != null) return skillRow;
    return def;
  }

  Future<void> _editRow(int weekday, PartnerAvailability? existing) async {
    final result = await showDialog<_HoursDraft?>(
      context: context,
      builder: (_) => _HoursDialog(
        weekday: weekday,
        existing: existing,
        scopeLabel: _scope == null
            ? (_isSwahili ? 'Kawaida' : 'Default')
            : _scope!,
        isSwahili: _isSwahili,
      ),
    );
    if (result == null) return;

    if (!result.isActive && existing != null) {
      // Deactivate row.
      await PartnerAvailabilityService.deactivateHours(
        id: existing.id,
        partnerUserId: widget.userId,
      );
    } else if (result.isActive) {
      await PartnerAvailabilityService.upsertHours(
        partnerUserId: widget.userId,
        weekday: weekday,
        openTime: result.openTime,
        closeTime: result.closeTime,
        slotMinutes: result.slotMinutes,
        skillCategory: _scope,
        reminderCadenceHours: result.reminderCadenceHours,
        pricingModifierPct: result.pricingModifierPct,
        preBufferMinutes: result.preBufferMinutes,
        processingMinutes: result.processingMinutes,
        postBufferMinutes: result.postBufferMinutes,
        travelSurchargeTzs: result.travelSurchargeTzs,
        afterHoursSurchargeTzs: result.afterHoursSurchargeTzs,
        holidayPremiumTzs: result.holidayPremiumTzs,
        parkingPassThroughTzs: result.parkingPassThroughTzs,
      );
    }
    if (mounted) _load();
  }

  Future<void> _addBlackout() async {
    final draft = await showDialog<_BlackoutDraft?>(
      context: context,
      builder: (_) => _BlackoutDialog(
        skills: widget.skills,
        isSwahili: _isSwahili,
      ),
    );
    if (draft == null) return;
    // Spec line 1144 — recurring weekly blackout. Expand into individual rows
    // on the client (one blackout per weekly occurrence) since the backend
    // takes a single window per call.
    final ranges = draft.isRecurringWeekly && draft.recurringUntil != null
        ? _expandWeekly(draft.startsAt, draft.endsAt, draft.recurringUntil!)
        : <(DateTime, DateTime)>[(draft.startsAt, draft.endsAt)];
    int failures = 0;
    for (final r in ranges) {
      final res = await PartnerAvailabilityService.addBlackout(
        partnerUserId: widget.userId,
        startsAt: r.$1,
        endsAt: r.$2,
        reason: draft.reason,
        allDay: draft.allDay,
        skillCategories: draft.skillCategories,
      );
      if (!res.success) failures++;
    }
    if (!mounted) return;
    if (failures == ranges.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isSwahili ? 'Imeshindikana' : 'Failed')),
      );
      return;
    }
    if (failures > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Nyingine zimeshindikana ($failures kati ya ${ranges.length})'
              : 'Some failed ($failures of ${ranges.length})'),
        ),
      );
    }
    _load();
  }

  List<(DateTime, DateTime)> _expandWeekly(
    DateTime start,
    DateTime end,
    DateTime until,
  ) {
    final out = <(DateTime, DateTime)>[];
    final span = end.difference(start);
    var cursor = start;
    while (!cursor.isAfter(until)) {
      out.add((cursor, cursor.add(span)));
      cursor = cursor.add(const Duration(days: 7));
      if (out.length > 60) break; // safety: cap at ~1 year of weeklies
    }
    return out;
  }

  Future<void> _removeBlackout(PartnerBlackout b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa likizo?' : 'Delete blackout?'),
        content: Text(b.reason ?? '—'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await PartnerAvailabilityService.deleteBlackout(
      id: b.id,
      partnerUserId: widget.userId,
    );
    if (!mounted) return;
    if (success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
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
          _isSwahili ? 'Muda Wangu' : 'My Availability',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: _kPrimary,
          unselectedLabelColor: _kMuted,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: _isSwahili ? 'Saa za Wiki' : 'Weekly Hours'),
            Tab(text: _isSwahili ? 'Likizo' : 'Blackouts'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_hasMultipleSkills) _scopePicker(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_weeklyHoursTab(), _blackoutsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: _tab.index == 1
          ? FloatingActionButton.extended(
              onPressed: _addBlackout,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(_isSwahili ? 'Ongeza Likizo' : 'Add Blackout'),
            )
          : null,
    );
  }

  Widget _scopePicker() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: Text(_isSwahili ? 'Kawaida' : 'Default'),
              selected: _scope == null,
              onSelected: (_) => setState(() {
                _scope = null;
                _load();
              }),
              selectedColor: _kPrimary,
              labelStyle: TextStyle(
                color: _scope == null ? Colors.white : _kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            for (final s in widget.skills) ...[
              ChoiceChip(
                avatar: Icon(s.icon, size: 14, color: _scope == s.name ? Colors.white : _kPrimary),
                label: Text(_isSwahili ? s.labelSwahili : s.label),
                selected: _scope == s.name,
                onSelected: (_) => setState(() {
                  _scope = s.name;
                  _load();
                }),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: _scope == s.name ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weeklyHoursTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        if (_scope != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _isSwahili
                  ? 'Saa hizi zinabadilisha "Kawaida" kwa $_scope tu.'
                  : 'These hours override Default for $_scope only.',
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
          ),
        // weekday list — Mon to Sun for natural order, but dates use 0=Sun..6=Sat.
        ...List.generate(7, (i) {
          final wd = (i + 1) % 7; // start at Mon
          return _hoursRow(wd);
        }),
      ],
    );
  }

  Widget _hoursRow(int weekday) {
    final row = _rowFor(weekday);
    final isOn = row != null && row.isActive;
    final label = _isSwahili ? _kWeekdayLabelsSwahili[weekday] : _kWeekdayLabels[weekday];
    final modifier = row?.pricingModifierPct ?? 0;
    final reminder = row?.reminderCadenceHours;
    final totalBuffer = (row?.preBufferMinutes ?? 0) + (row?.processingMinutes ?? 0) + (row?.postBufferMinutes ?? 0);
    final hasSurcharge = (row?.travelSurchargeTzs ?? 0) > 0 ||
        (row?.afterHoursSurchargeTzs ?? 0) > 0 ||
        (row?.holidayPremiumTzs ?? 0) > 0 ||
        (row?.parkingPassThroughTzs ?? 0) > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _editRow(weekday, row),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
                Expanded(
                  child: isOn
                      ? Text(
                          '${row.openTime} – ${row.closeTime}',
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                        )
                      : Text(
                          _isSwahili ? 'Imefungwa' : 'Closed',
                          style: const TextStyle(fontSize: 13, color: _kMuted),
                        ),
                ),
                if (isOn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${row.slotMinutes}m',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 18),
              ],
            ),
            if (isOn && (modifier != 0 || (reminder != null && reminder != 24) || totalBuffer > 0 || hasSurcharge))
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 80),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (modifier != 0)
                      _miniChip(
                        modifier > 0 ? '+$modifier%' : '$modifier%',
                        modifier > 0
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF1B5E20),
                      ),
                    if (reminder != null && reminder != 24)
                      _miniChip(
                        reminder == 0
                            ? (_isSwahili ? 'Hakuna kumbusho' : 'No reminders')
                            : '${reminder}h',
                        _kPrimary,
                      ),
                    if (totalBuffer > 0)
                      _miniChip(
                        _isSwahili ? 'Muda $totalBuffer daka' : 'Buffer ${totalBuffer}m',
                        const Color(0xFF0D47A1),
                      ),
                    if (hasSurcharge)
                      _miniChip(
                        _isSwahili ? 'Ada za ziada' : 'Surcharges',
                        const Color(0xFFE65100),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _blackoutsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_blackouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_rounded, size: 48, color: _kMuted),
              const SizedBox(height: 12),
              Text(
                _isSwahili ? 'Hakuna likizo bado' : 'No blackouts yet',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _isSwahili
                    ? 'Bonyeza "Ongeza Likizo" kuanza.'
                    : 'Tap "Add Blackout" to start.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: _blackouts.length,
        itemBuilder: (_, i) => _blackoutRow(_blackouts[i]),
      ),
    );
  }

  Widget _blackoutRow(PartnerBlackout b) {
    final endsBefore = b.endsAt.isBefore(DateTime.now());
    return InkWell(
      onLongPress: endsBefore ? null : () => _removeBlackout(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.reason ?? (_isSwahili ? 'Bila sababu' : 'No reason'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
                if (b.appliesToAllSkills())
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isSwahili ? 'Kazi zote' : 'All skills',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB71C1C)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      b.skillCategories!.join(', '),
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('d MMM HH:mm').format(b.startsAt)} → ${DateFormat('d MMM HH:mm').format(b.endsAt)}',
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
            if (!endsBefore) ...[
              const SizedBox(height: 4),
              Text(
                _isSwahili ? 'Bonyeza kwa muda mrefu kufuta' : 'Long-press to delete',
                style: const TextStyle(fontSize: 10, color: _kMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoursDraft {
  final bool isActive;
  final String openTime;
  final String closeTime;
  final int slotMinutes;
  final int? reminderCadenceHours;
  final int? pricingModifierPct;
  final int? preBufferMinutes;
  final int? processingMinutes;
  final int? postBufferMinutes;
  final int? travelSurchargeTzs;
  final int? afterHoursSurchargeTzs;
  final int? holidayPremiumTzs;
  final int? parkingPassThroughTzs;
  _HoursDraft({
    required this.isActive,
    required this.openTime,
    required this.closeTime,
    required this.slotMinutes,
    required this.reminderCadenceHours,
    required this.pricingModifierPct,
    this.preBufferMinutes,
    this.processingMinutes,
    this.postBufferMinutes,
    this.travelSurchargeTzs,
    this.afterHoursSurchargeTzs,
    this.holidayPremiumTzs,
    this.parkingPassThroughTzs,
  });
}

class _HoursDialog extends StatefulWidget {
  final int weekday;
  final PartnerAvailability? existing;
  final String scopeLabel;
  final bool isSwahili;
  const _HoursDialog({
    required this.weekday,
    required this.existing,
    required this.scopeLabel,
    required this.isSwahili,
  });

  @override
  State<_HoursDialog> createState() => _HoursDialogState();
}

class _HoursDialogState extends State<_HoursDialog> {
  late bool _isOn;
  late TimeOfDay _open;
  late TimeOfDay _close;
  late int _slotMinutes;
  late int _reminderHours;
  late int _pricingPct;
  late final TextEditingController _preBufferCtrl;
  late final TextEditingController _processingCtrl;
  late final TextEditingController _postBufferCtrl;
  late final TextEditingController _travelSurchargeCtrl;
  late final TextEditingController _afterHoursCtrl;
  late final TextEditingController _holidayCtrl;
  late final TextEditingController _parkingCtrl;

  static const _kReminderOptions = <int>[0, 2, 6, 12, 24];
  static const _kPricingOptions = <int>[-25, -15, -10, 0, 10, 15, 25];

  @override
  void initState() {
    super.initState();
    _isOn = widget.existing != null && widget.existing!.isActive;
    _open = _parseTime(widget.existing?.openTime ?? '09:00');
    _close = _parseTime(widget.existing?.closeTime ?? '17:00');
    _slotMinutes = widget.existing?.slotMinutes ?? 30;
    _reminderHours = widget.existing?.reminderCadenceHours ?? 24;
    _pricingPct = widget.existing?.pricingModifierPct ?? 0;
    _preBufferCtrl = TextEditingController(text: _fmtN(widget.existing?.preBufferMinutes));
    _processingCtrl = TextEditingController(text: _fmtN(widget.existing?.processingMinutes));
    _postBufferCtrl = TextEditingController(text: _fmtN(widget.existing?.postBufferMinutes));
    _travelSurchargeCtrl = TextEditingController(text: _fmtN(widget.existing?.travelSurchargeTzs));
    _afterHoursCtrl = TextEditingController(text: _fmtN(widget.existing?.afterHoursSurchargeTzs));
    _holidayCtrl = TextEditingController(text: _fmtN(widget.existing?.holidayPremiumTzs));
    _parkingCtrl = TextEditingController(text: _fmtN(widget.existing?.parkingPassThroughTzs));
  }

  String _fmtN(int? v) => v == null || v == 0 ? '' : '$v';

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _numberField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _open : _close,
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _open = picked;
      } else {
        _close = picked;
      }
    });
  }

  @override
  void dispose() {
    _preBufferCtrl.dispose();
    _processingCtrl.dispose();
    _postBufferCtrl.dispose();
    _travelSurchargeCtrl.dispose();
    _afterHoursCtrl.dispose();
    _holidayCtrl.dispose();
    _parkingCtrl.dispose();
    super.dispose();
  }

  int? _parseCtrl(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : int.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    final wdLabel = widget.isSwahili
        ? _kWeekdayLabelsSwahili[widget.weekday]
        : _kWeekdayLabels[widget.weekday];
    final totalMin = (_parseCtrl(_preBufferCtrl) ?? 0) +
        (_parseCtrl(_processingCtrl) ?? 0) +
        (_parseCtrl(_postBufferCtrl) ?? 0);
    return AlertDialog(
      title: Text('$wdLabel — ${widget.scopeLabel}',
          style: const TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(widget.isSwahili ? 'Iko wazi' : 'Open',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                value: _isOn,
                onChanged: (v) => setState(() => _isOn = v),
              ),
              if (_isOn) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(true),
                        icon: const Icon(Icons.access_time_rounded, size: 14),
                        label: Text(_fmtTime(_open)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(false),
                        icon: const Icon(Icons.access_time_filled_rounded, size: 14),
                        label: Text(_fmtTime(_close)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      widget.isSwahili ? 'Slot' : 'Slot',
                      style: const TextStyle(fontSize: 12, color: _kMuted),
                    ),
                    const Spacer(),
                    ..._kSlotMinutesOptions.map((m) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ChoiceChip(
                            label: Text('${m}m'),
                            selected: _slotMinutes == m,
                            onSelected: (_) => setState(() => _slotMinutes = m),
                            selectedColor: _kPrimary,
                            labelStyle: TextStyle(
                              color: _slotMinutes == m ? Colors.white : _kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isSwahili ? 'Kumbusho' : 'Reminders',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _kReminderOptions.map((h) {
                    final selected = _reminderHours == h;
                    final label = h == 0
                        ? (widget.isSwahili ? 'Hapana' : 'Off')
                        : (widget.isSwahili ? 'Saa $h kabla' : '${h}h before');
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _reminderHours = h),
                      selectedColor: _kPrimary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : _kPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isSwahili ? 'Bei (siku hii)' : 'Pricing (this day)',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _kPricingOptions.map((p) {
                    final selected = _pricingPct == p;
                    final label = p == 0
                        ? (widget.isSwahili ? 'Kawaida' : 'Base')
                        : (p > 0 ? '+$p%' : '$p%');
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _pricingPct = p),
                      selectedColor: p > 0
                          ? const Color(0xFFB71C1C)
                          : (p < 0 ? const Color(0xFF1B5E20) : _kPrimary),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : _kPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isSwahili ? 'Muda kabla / Pre-buffer' : 'Pre-buffer (min)',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 4),
                _numberField(_preBufferCtrl, widget.isSwahili ? 'dakika' : 'min'),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isSwahili ? 'Muda wa mchakato / Processing time' : 'Processing time (min)',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 4),
                _numberField(_processingCtrl, widget.isSwahili ? 'dakika' : 'min'),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isSwahili ? 'Muda baada / Post-buffer' : 'Post-buffer (min)',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 4),
                _numberField(_postBufferCtrl, widget.isSwahili ? 'dakika' : 'min'),
                if (totalMin > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.isSwahili
                          ? 'Jumla ya muda: $totalMin daka'
                          : 'Total duration: $totalMin min',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isSwahili ? 'Ada za ziada (TZS)' : 'Surcharges (TZS)',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 4),
                _numberField(_travelSurchargeCtrl, widget.isSwahili ? 'Usafiri' : 'Travel'),
                const SizedBox(height: 6),
                _numberField(_afterHoursCtrl, widget.isSwahili ? 'Baada ya masaa' : 'After-hours'),
                const SizedBox(height: 6),
                _numberField(_holidayCtrl, widget.isSwahili ? 'Sikukuu' : 'Holiday'),
                const SizedBox(height: 6),
                _numberField(_parkingCtrl, widget.isSwahili ? 'Maegesho' : 'Parking'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isSwahili ? 'Funga' : 'Close'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isOn && _close.hour * 60 + _close.minute <= _open.hour * 60 + _open.minute) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(widget.isSwahili
                    ? 'Muda wa kufunga lazima uwe baada ya wa kufungua'
                    : 'Close time must be after open time'),
              ));
              return;
            }
            Navigator.pop(
              context,
              _HoursDraft(
                isActive: _isOn,
                openTime: _fmtTime(_open),
                closeTime: _fmtTime(_close),
                slotMinutes: _slotMinutes,
                reminderCadenceHours: _reminderHours,
                pricingModifierPct: _pricingPct,
                preBufferMinutes: _parseCtrl(_preBufferCtrl),
                processingMinutes: _parseCtrl(_processingCtrl),
                postBufferMinutes: _parseCtrl(_postBufferCtrl),
                travelSurchargeTzs: _parseCtrl(_travelSurchargeCtrl),
                afterHoursSurchargeTzs: _parseCtrl(_afterHoursCtrl),
                holidayPremiumTzs: _parseCtrl(_holidayCtrl),
                parkingPassThroughTzs: _parseCtrl(_parkingCtrl),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isSwahili ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}

class _BlackoutDraft {
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
  final bool allDay;
  final List<String>? skillCategories;
  final bool isRecurringWeekly;
  final DateTime? recurringUntil;
  _BlackoutDraft({
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.allDay,
    required this.skillCategories,
    this.isRecurringWeekly = false,
    this.recurringUntil,
  });
}

class _BlackoutDialog extends StatefulWidget {
  final List<SkillCategory> skills;
  final bool isSwahili;
  const _BlackoutDialog({required this.skills, required this.isSwahili});

  @override
  State<_BlackoutDialog> createState() => _BlackoutDialogState();
}

class _BlackoutDialogState extends State<_BlackoutDialog> {
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 2));
  final _reasonCtrl = TextEditingController();
  bool _allDay = true;
  bool _allSkills = true;
  final Set<String> _scopedSkills = <String>{};
  bool _recurringWeekly = false;
  DateTime _recurringUntil = DateTime.now().add(const Duration(days: 90));

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final hasSkills = widget.skills.isNotEmpty;
    return AlertDialog(
      title: Text(widget.isSwahili ? 'Likizo Mpya' : 'New Blackout',
          style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _pickDateTime(_start);
                  if (picked != null) setState(() => _start = picked);
                },
                icon: const Icon(Icons.event_rounded, size: 16),
                label: Text(
                  '${widget.isSwahili ? "Anza" : "Start"}: ${DateFormat('EEE d MMM • HH:mm').format(_start)}',
                ),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _pickDateTime(_end);
                  if (picked != null) setState(() => _end = picked);
                },
                icon: const Icon(Icons.event_available_rounded, size: 16),
                label: Text(
                  '${widget.isSwahili ? "Maliza" : "End"}: ${DateFormat('EEE d MMM • HH:mm').format(_end)}',
                ),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              ),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(widget.isSwahili ? 'Siku nzima' : 'All day',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: _allDay,
                onChanged: (v) => setState(() => _allDay = v),
              ),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.isSwahili ? 'Rudia kila wiki' : 'Repeat weekly',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  widget.isSwahili
                      ? 'Mfano: kila Jumapili'
                      : 'e.g. every Sunday',
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
                value: _recurringWeekly,
                onChanged: (v) => setState(() => _recurringWeekly = v),
              ),
              if (_recurringWeekly)
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _recurringUntil,
                      firstDate: _start,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _recurringUntil = picked);
                  },
                  icon: const Icon(Icons.event_available_rounded, size: 16),
                  label: Text(
                    '${widget.isSwahili ? "Hadi" : "Until"}: ${DateFormat('EEE d MMM y').format(_recurringUntil)}',
                  ),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                ),
              TextField(
                controller: _reasonCtrl,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: widget.isSwahili ? 'Sababu (hiari)' : 'Reason (optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (hasSkills) ...[
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.isSwahili ? 'Kazi zote' : 'All skills',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _allSkills,
                  onChanged: (v) => setState(() => _allSkills = v),
                ),
                if (!_allSkills)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.skills.map((s) {
                      final selected = _scopedSkills.contains(s.name);
                      return FilterChip(
                        label: Text(widget.isSwahili ? s.labelSwahili : s.label),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _scopedSkills.add(s.name);
                          } else {
                            _scopedSkills.remove(s.name);
                          }
                        }),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isSwahili ? 'Funga' : 'Close'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_end.isAfter(_start)) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(widget.isSwahili
                    ? 'Tarehe ya kumaliza lazima iwe baada ya kuanza'
                    : 'End must be after start'),
              ));
              return;
            }
            Navigator.pop(
              context,
              _BlackoutDraft(
                startsAt: _start,
                endsAt: _end,
                reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
                allDay: _allDay,
                skillCategories: _allSkills || _scopedSkills.isEmpty
                    ? null
                    : _scopedSkills.toList(),
                isRecurringWeekly: _recurringWeekly,
                recurringUntil: _recurringWeekly ? _recurringUntil : null,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isSwahili ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}

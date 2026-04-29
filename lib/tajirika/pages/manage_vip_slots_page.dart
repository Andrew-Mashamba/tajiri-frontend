import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/partner_vip_slot.dart';
import '../models/tajirika_models.dart';
import '../services/partner_vip_slot_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

const List<String> _kWeekdayLabelsEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const List<String> _kWeekdayLabelsSw = ['Jpl', 'Jtt', 'Jnn', 'Jtn', 'Alh', 'Iju', 'Jms'];

/// Spec line 1183 — VIP standing-slot reservation. Partner can grant a
/// specific repeat customer a "VIP" tag that holds their preferred
/// recurring slot before public booking opens each week.
class ManageVipSlotsPage extends StatefulWidget {
  final int partnerUserId;
  final List<SkillCategory> skills;
  const ManageVipSlotsPage({
    super.key,
    required this.partnerUserId,
    this.skills = const [],
  });

  @override
  State<ManageVipSlotsPage> createState() => _ManageVipSlotsPageState();
}

class _ManageVipSlotsPageState extends State<ManageVipSlotsPage> {
  bool _loading = true;
  List<PartnerVipSlot> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await PartnerVipSlotService.listForPartner(widget.partnerUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  Future<void> _add() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _VipDialog(
        partnerUserId: widget.partnerUserId,
        skills: widget.skills,
        isSwahili: _isSwahili,
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _remove(PartnerVipSlot s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa VIP slot?' : 'Remove VIP slot?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Futa' : 'Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await PartnerVipSlotService.delete(s.id);
    if (!mounted) return;
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSw ? 'VIP Slots' : 'VIP Slots',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: _items.map(_row).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(isSw ? 'Ongeza' : 'Add'),
      ),
    );
  }

  Widget _empty() {
    final isSw = _isSwahili;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 56, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              isSw ? 'Hakuna VIP slots' : 'No VIP slots',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isSw
                  ? 'Wateja wa kawaida wanapata kipaumbele kwa muda walowapenda.'
                  : 'Repeat clients get priority on their preferred slot.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(PartnerVipSlot s) {
    final isSw = _isSwahili;
    final wd = isSw ? _kWeekdayLabelsSw[s.weekday] : _kWeekdayLabelsEn[s.weekday];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF8E1),
          child: Icon(Icons.workspace_premium_rounded,
              color: Color(0xFFE65100)),
        ),
        title: Text(
          '$wd · ${s.slotTime}',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _kPrimary),
        ),
        subtitle: Text(
          [
            isSw ? 'Mteja #${s.customerUserId}' : 'Customer #${s.customerUserId}',
            if (s.skillCategory != null && s.skillCategory!.isNotEmpty)
              s.skillCategory!,
          ].join(' • '),
          style: const TextStyle(fontSize: 11, color: _kSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Color(0xFFB71C1C)),
          tooltip: isSw ? 'Toa' : 'Remove',
          onPressed: () => _remove(s),
        ),
      ),
    );
  }
}

class _VipDialog extends StatefulWidget {
  final int partnerUserId;
  final List<SkillCategory> skills;
  final bool isSwahili;
  const _VipDialog({
    required this.partnerUserId,
    required this.skills,
    required this.isSwahili,
  });

  @override
  State<_VipDialog> createState() => _VipDialogState();
}

class _VipDialogState extends State<_VipDialog> {
  final _customerCtrl = TextEditingController();
  int _weekday = 1;
  TimeOfDay _time = const TimeOfDay(hour: 14, minute: 0);
  String? _skill;
  bool _saving = false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final customerId = int.tryParse(_customerCtrl.text.trim());
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'ID si halali' : 'Invalid customer ID'),
      ));
      return;
    }
    setState(() => _saving = true);
    final ok = await PartnerVipSlotService.create(
      partnerUserId: widget.partnerUserId,
      customerUserId: customerId,
      skillCategory: _skill,
      weekday: _weekday,
      slotTime: _fmt(_time),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return AlertDialog(
      title: Text(sw ? 'Slot ya VIP Mpya' : 'New VIP Slot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _customerCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: sw ? 'ID ya mteja' : 'Customer user ID',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(sw ? 'Siku' : 'Day',
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: List.generate(7, (i) {
                final selected = _weekday == i;
                return ChoiceChip(
                  label:
                      Text(sw ? _kWeekdayLabelsSw[i] : _kWeekdayLabelsEn[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _weekday = i),
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : _kPrimary,
                    fontSize: 11,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time_rounded, size: 14),
              label: Text(_fmt(_time)),
            ),
            if (widget.skills.length > 1) ...[
              const SizedBox(height: 8),
              Text(sw ? 'Ujuzi (hiari)' : 'Skill (optional)',
                  style:
                      const TextStyle(fontSize: 11, color: _kSecondary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(sw ? 'Yote' : 'All'),
                    selected: _skill == null,
                    onSelected: (_) => setState(() => _skill = null),
                  ),
                  ...widget.skills.map((s) => ChoiceChip(
                        label: Text(sw ? s.labelSwahili : s.label),
                        selected: _skill == s.name,
                        onSelected: (_) =>
                            setState(() => _skill = s.name),
                      )),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(sw ? 'Funga' : 'Close')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(sw ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}

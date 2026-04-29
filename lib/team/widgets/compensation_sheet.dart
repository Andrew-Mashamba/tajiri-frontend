// lib/team/widgets/compensation_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/team_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

/// Add (employee==null, user required) or edit (employee!=null) sheet.
class CompensationSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final PlatformUser? user; // null when editing existing employee
  final Employee? employee; // null when adding new
  final VoidCallback onSaved;

  const CompensationSheet({
    super.key,
    required this.token,
    required this.businessId,
    this.user,
    this.employee,
    required this.onSaved,
  });

  @override
  State<CompensationSheet> createState() => _CompensationSheetState();
}

class _CompensationSheetState extends State<CompensationSheet> {
  late final TextEditingController _posCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _salaryCtrl;

  late String _contractType;
  late bool _applyPAYE;
  late bool _applyNSSF;
  late bool _applyNHIF;
  late bool _isActive;
  late List<Allowance> _allowances;
  DateTime? _startDate;
  bool _saving = false;

  static const _contractTypes = ['permanent', 'contract', 'part_time'];

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _posCtrl = TextEditingController(text: e?.position ?? '');
    _deptCtrl = TextEditingController(text: e?.department ?? '');
    _salaryCtrl = TextEditingController(
        text: e != null ? e.grossSalary.toStringAsFixed(0) : '');
    _contractType = e?.contractType ?? 'permanent';
    _applyPAYE = e?.applyPAYE ?? true;
    _applyNSSF = e?.applyNSSF ?? true;
    _applyNHIF = e?.applyNHIF ?? true;
    _isActive = e?.isActive ?? true;
    _allowances = List.from(e?.allowances ?? []);
    _startDate = e?.startDate;
  }

  @override
  void dispose() {
    for (final c in [_posCtrl, _deptCtrl, _salaryCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String _contractLabel(String type, bool sw) {
    switch (type) {
      case 'permanent':
        return sw ? 'Kudumu' : 'Permanent';
      case 'contract':
        return sw ? 'Mkataba' : 'Contract';
      case 'part_time':
        return sw ? 'Sehemu ya Wakati' : 'Part-time';
      default:
        return type;
    }
  }

  Future<void> _pickDate(bool sw) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  Future<void> _addAllowanceDialog(bool sw) async {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ongeza Posho' : 'Add Allowance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                  hintText: sw ? 'Jina (k.m. Usafiri)' : 'Name (e.g. Transport)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  hintText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(sw ? 'Ongeza' : 'Add'),
          ),
        ],
      ),
    );
    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _allowances.add(Allowance(
          name: nameCtrl.text.trim(),
          amount:
              double.tryParse(amtCtrl.text.replaceAll(',', '')) ?? 0,
        ));
      });
    }
    nameCtrl.dispose();
    amtCtrl.dispose();
  }

  Future<void> _save(bool sw) async {
    final gross =
        double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0;
    if (_posCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Tafadhali weka nafasi'
              : 'Please enter a position')));
      return;
    }
    if (gross <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Tafadhali weka mshahara'
              : 'Please enter a valid salary')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final body = <String, dynamic>{
      'user_business_id': widget.businessId,
      if (widget.user != null) 'user_id': widget.user!.id,
      if (widget.user != null) 'name': widget.user!.name,
      'position': _posCtrl.text.trim(),
      'department': _deptCtrl.text.trim(),
      'contract_type': _contractType,
      'gross_salary': gross,
      'apply_paye': _applyPAYE,
      'apply_nssf': _applyNSSF,
      'apply_nhif': _applyNHIF,
      'allowances': _allowances.map((a) => a.toJson()).toList(),
      'start_date': _startDate?.toIso8601String(),

      'is_active': _isActive,
    };
    try {
      final bool success;
      String? msg;
      if (widget.employee == null) {
        final res = await TeamService.addEmployee(widget.token, body);
        success = res.success;
        msg = res.message;
      } else {
        final res = await TeamService.updateEmployee(
            widget.token, widget.employee!.id!, body);
        success = res.success;
        msg = res.message;
      }
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(success
              ? (sw ? 'Imehifadhiwa' : 'Saved')
              : (msg ?? (sw ? 'Imeshindikana' : 'Failed')))));
      if (success) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
            content:
                Text(sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _toggle(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, color: _kPrimary)),
        Switch(
            value: value,
            activeThumbColor: _kPrimary,
            onChanged: onChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final displayName =
        widget.user?.name ?? widget.employee?.name ?? '';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.employee == null
                  ? (sw ? 'Ongeza Mwanatimu' : 'Add Team Member')
                  : (sw ? 'Hariri Mwanatimu' : 'Edit Team Member'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
            if (displayName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(displayName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kSecondary)),
            ],
            const SizedBox(height: 16),
            _field(_posCtrl, sw ? 'Nafasi / Cheo' : 'Position / Role',
                Icons.work_rounded),
            const SizedBox(height: 10),
            _field(_deptCtrl, sw ? 'Idara' : 'Department',
                Icons.business_rounded),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _contractType,
              decoration: InputDecoration(
                labelText:
                    sw ? 'Aina ya Mkataba' : 'Contract Type',
                prefixIcon: const Icon(Icons.description_rounded,
                    size: 20, color: _kSecondary),
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: _contractTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_contractLabel(t, sw)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _contractType = v ?? 'permanent'),
            ),
            const SizedBox(height: 10),
            _field(
                _salaryCtrl,
                sw
                    ? 'Mshahara Jumla (TZS/mwezi)'
                    : 'Gross Salary (TZS/month)',
                Icons.payments_rounded,
                keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            Text(sw ? 'Makato' : 'Deductions',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            _toggle('PAYE', _applyPAYE,
                (v) => setState(() => _applyPAYE = v)),
            _toggle('NSSF', _applyNSSF,
                (v) => setState(() => _applyNSSF = v)),
            _toggle('NHIF', _applyNHIF,
                (v) => setState(() => _applyNHIF = v)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sw ? 'Posho' : 'Allowances',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary)),
                TextButton.icon(
                  onPressed: () => _addAllowanceDialog(sw),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(sw ? 'Ongeza' : 'Add'),
                  style: TextButton.styleFrom(
                      foregroundColor: _kPrimary),
                ),
              ],
            ),
            if (_allowances.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _allowances.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  return Chip(
                    label: Text(
                        '${a.name}: ${a.amount.toStringAsFixed(0)}'),
                    deleteIcon:
                        const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () =>
                        setState(() => _allowances.removeAt(i)),
                    backgroundColor: _kBackground,
                    side: BorderSide(color: Colors.grey.shade300),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickDate(sw),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText:
                      sw ? 'Tarehe ya Kuanza' : 'Start Date',
                  prefixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: _kSecondary),
                  filled: true,
                  fillColor: _kBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                child: Text(
                  _startDate != null
                      ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                      : (sw ? 'Chagua tarehe' : 'Select date'),
                  style: TextStyle(
                      color: _startDate != null
                          ? _kPrimary
                          : Colors.grey.shade500,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _toggle(sw ? 'Mfanyakazi Hai' : 'Active Employee',
                _isActive, (v) => setState(() => _isActive = v)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(sw),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

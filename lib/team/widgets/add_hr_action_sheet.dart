// lib/team/widgets/add_hr_action_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/team_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class _ActionDef {
  final String type;
  final String category;
  final String labelEn;
  final String labelSw;
  final IconData icon;
  const _ActionDef(this.type, this.category, this.labelEn, this.labelSw, this.icon);
}

const _kActions = <_ActionDef>[
  _ActionDef('promote',            'employment',   'Promotion',         'Kukuza Cheo',         Icons.trending_up_rounded),
  _ActionDef('transfer',           'employment',   'Transfer',          'Uhamishaji',           Icons.swap_horiz_rounded),
  _ActionDef('rehire',             'employment',   'Rehire',            'Kuajiri Tena',         Icons.person_add_alt_1_rounded),
  _ActionDef('terminate',          'employment',   'Terminate',         'Maliza Mkataba',       Icons.exit_to_app_rounded),
  _ActionDef('salary_review',      'compensation', 'Salary Review',     'Pitia Mshahara',       Icons.payments_rounded),
  _ActionDef('bonus',              'compensation', 'Bonus',             'Bonasi',               Icons.card_giftcard_rounded),
  _ActionDef('warning',            'discipline',   'Warning',           'Onyo',                 Icons.warning_amber_rounded),
  _ActionDef('final_warning',      'discipline',   'Final Warning',     'Onyo la Mwisho',       Icons.report_rounded),
  _ActionDef('suspension',         'discipline',   'Suspend',           'Simamisha',            Icons.block_rounded),
  _ActionDef('leave_approval',     'leave',        'Approve Leave',     'Idhini Likizo',        Icons.beach_access_rounded),
  _ActionDef('leave_rejection',    'leave',        'Reject Leave',      'Kataa Likizo',         Icons.event_busy_rounded),
  _ActionDef('performance_review', 'performance',  'Perf. Review',      'Tathmini',             Icons.bar_chart_rounded),
  _ActionDef('pip',                'performance',  'Impr. Plan',        'Mpango',               Icons.edit_note_rounded),
  _ActionDef('certificate',        'document',     'Certificate',       'Cheti',                Icons.workspace_premium_rounded),
  _ActionDef('contract_renewal',   'document',     'Renew Contract',    'Fanya Upya',           Icons.description_rounded),
];

// Actions that also update the employee record
const _kEmployeeUpdateActions = {
  'promote', 'transfer', 'terminate', 'rehire', 'salary_review', 'suspension', 'contract_renewal',
};

class AddHrActionSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final int employeeId;
  final Employee employee;
  final VoidCallback onSaved;
  final String? initialAction;
  final String? initialCategory;

  const AddHrActionSheet({
    super.key,
    required this.token,
    required this.businessId,
    required this.employeeId,
    required this.employee,
    required this.onSaved,
    this.initialAction,
    this.initialCategory,
  });

  @override
  State<AddHrActionSheet> createState() => _AddHrActionSheetState();
}

class _AddHrActionSheetState extends State<AddHrActionSheet> {
  _ActionDef? _selected;

  // Shared
  final _descCtrl = TextEditingController();
  DateTime _actionDate = DateTime.now();
  DateTime? _effectiveDate;
  bool _saving = false;

  // Action-specific controllers
  late final TextEditingController _positionCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _bonusAmtCtrl;
  String _contractType = 'permanent';
  int _rating = 0; // 1–5 for performance_review
  String _certType = 'service'; // for certificate

  static const _contractTypes = ['permanent', 'contract', 'part_time'];

  @override
  void initState() {
    super.initState();
    // Pre-fill from current employee data
    _positionCtrl   = TextEditingController(text: widget.employee.position ?? '');
    _departmentCtrl = TextEditingController(text: widget.employee.department ?? '');
    _salaryCtrl     = TextEditingController(
        text: widget.employee.grossSalary > 0
            ? widget.employee.grossSalary.toStringAsFixed(0)
            : '');
    _bonusAmtCtrl   = TextEditingController();
    _contractType   = widget.employee.contractType ?? 'permanent';

    if (widget.initialAction != null) {
      try {
        _selected = _kActions.firstWhere((a) => a.type == widget.initialAction);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _positionCtrl.dispose();
    _departmentCtrl.dispose();
    _salaryCtrl.dispose();
    _bonusAmtCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  String _successMessage(String type, bool sw) {
    switch (type) {
      case 'promote':           return sw ? 'Ukuzi wa cheo umehifadhiwa'       : 'Promotion recorded';
      case 'transfer':          return sw ? 'Uhamishaji umehifadhiwa'           : 'Transfer recorded';
      case 'terminate':         return sw ? 'Mkataba umemalizika'               : 'Employment terminated';
      case 'rehire':            return sw ? 'Mfanyakazi ameajiriwa tena'        : 'Employee rehired';
      case 'salary_review':     return sw ? 'Mshahara umesasishwa'             : 'Salary updated';
      case 'bonus':             return sw ? 'Bonasi imehifadhiwa'              : 'Bonus recorded';
      case 'warning':           return sw ? 'Onyo limehifadhiwa'               : 'Warning recorded';
      case 'final_warning':     return sw ? 'Onyo la mwisho limehifadhiwa'     : 'Final warning recorded';
      case 'suspension':        return sw ? 'Kusimamishwa kumehifadhiwa'        : 'Suspension recorded';
      case 'leave_approval':    return sw ? 'Likizo imeidhinishwa'             : 'Leave approved';
      case 'leave_rejection':   return sw ? 'Likizo imekataliwa'               : 'Leave rejected';
      case 'performance_review': return sw ? 'Tathmini imehifadhiwa'           : 'Review recorded';
      case 'pip':               return sw ? 'Mpango wa Kuboresha umewekwa'     : 'Improvement plan created';
      case 'certificate':       return sw ? 'Cheti kimehifadhiwa'              : 'Certificate recorded';
      case 'contract_renewal':  return sw ? 'Mkataba umefanywa upya'           : 'Contract renewed';
      default:                  return sw ? 'Imehifadhiwa'                     : 'Saved';
    }
  }

  Future<void> _save(bool sw) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (_selected == null) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Chagua aina ya hatua' : 'Select an action type')));
      return;
    }

    // Action-specific validation
    final type = _selected!.type;
    if ((type == 'promote' || type == 'rehire') &&
        _positionCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Weka nafasi mpya' : 'Enter new position')));
      return;
    }
    if (type == 'transfer' && _departmentCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Weka idara mpya' : 'Enter new department')));
      return;
    }
    if ((type == 'salary_review') &&
        (double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0) <= 0) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Weka mshahara mpya' : 'Enter new salary')));
      return;
    }
    if (type == 'bonus') {
      final amt = double.tryParse(_bonusAmtCtrl.text.replaceAll(',', '')) ?? 0;
      if (amt <= 0) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Weka kiasi cha bonasi' : 'Enter bonus amount')));
        return;
      }
      if (_descCtrl.text.trim().isEmpty) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw
                ? 'Weka maelezo ya bonasi'
                : 'Enter bonus description')));
        return;
      }
    }
    if (type == 'suspension' && _effectiveDate != null) {
      if (!_effectiveDate!.isAfter(_actionDate)) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw
                ? 'Tarehe ya kurudi lazima iwe baada ya tarehe ya kusimamishwa'
                : 'Return date must be after suspension date')));
        return;
      }
    }
    if (type == 'pip') {
      if (_effectiveDate == null) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw
                ? 'Weka tarehe ya mwisho ya mpango'
                : 'Enter plan end date')));
        return;
      }
      final diff = _effectiveDate!.difference(_actionDate).inDays;
      if (diff < 30) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw
                ? 'Mpango wa Kuboresha lazima uwe wa siku 30 au zaidi'
                : 'Improvement Plan must be at least 30 days')));
        return;
      }
    }
    if (type == 'leave_approval' && _effectiveDate != null) {
      if (_effectiveDate!.isBefore(_actionDate)) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw
                ? 'Tarehe ya mwisho lazima iwe baada ya tarehe ya kuanza'
                : 'Leave end must be after leave start')));
        return;
      }
    }
    if (type == 'performance_review' && _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(sw ? 'Chagua tathmini (nyota)' : 'Select a rating')));
      return;
    }

    // Confirmation dialog for destructive actions
    if (type == 'terminate') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            sw ? 'Thibitisha Kumaliza Mkataba' : 'Confirm Termination',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            sw
                ? 'Una uhakika wa kumaliza mkataba wa mfanyakazi huyu? Hatua hii itaweka akaunti kuwa si hai.'
                : 'Are you sure you want to terminate this employee? This will set their account to inactive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(sw ? 'Thibitisha' : 'Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);

    // Build metadata for the HR action record
    final meta = <String, dynamic>{};
    if (type == 'promote' || type == 'rehire') {
      meta['new_position'] = _positionCtrl.text.trim();
      if (_departmentCtrl.text.trim().isNotEmpty) {
        meta['new_department'] = _departmentCtrl.text.trim();
      }
      final newSal = double.tryParse(_salaryCtrl.text.replaceAll(',', ''));
      if (newSal != null && newSal > 0) meta['new_salary'] = newSal;
      meta['old_position'] = widget.employee.position ?? '';
      meta['old_salary']   = widget.employee.grossSalary;
    } else if (type == 'transfer') {
      meta['new_department'] = _departmentCtrl.text.trim();
      meta['old_department'] = widget.employee.department ?? '';
    } else if (type == 'salary_review') {
      final newSal = double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0;
      meta['new_salary'] = newSal;
      meta['old_salary'] = widget.employee.grossSalary;
    } else if (type == 'bonus') {
      final amt = double.tryParse(_bonusAmtCtrl.text.replaceAll(',', ''));
      if (amt != null) meta['bonus_amount'] = amt;
    } else if (type == 'contract_renewal') {
      meta['contract_type'] = _contractType;
    } else if (type == 'performance_review') {
      meta['rating'] = _rating;
    } else if (type == 'certificate') {
      meta['certificate_type'] = _certType;
    }

    final hrBody = <String, dynamic>{
      'business_id':    widget.businessId,
      'action_type':    type,
      'category':       _selected!.category,
      'action_date':    _fmtDate(_actionDate),
      if (_effectiveDate != null) 'effective_date': _fmtDate(_effectiveDate!),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      if (meta.isNotEmpty) 'metadata': meta,
    };

    try {
      // 1. Record HR action
      final hrRes = await TeamService.addHrAction(
          widget.token, widget.employeeId, hrBody);
      if (!hrRes.success) {
        if (!mounted) return;
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
            content: Text(hrRes.message ?? (sw ? 'Imeshindikana' : 'Failed'))));
        return;
      }

      // 2. Apply employee record update (where relevant)
      if (_kEmployeeUpdateActions.contains(type) && widget.employee.id != null) {
        final empBody = <String, dynamic>{
          'user_business_id': widget.businessId,
        };
        switch (type) {
          case 'promote':
            empBody['position']    = _positionCtrl.text.trim();
            empBody['department']  = _departmentCtrl.text.trim();
            final s = double.tryParse(_salaryCtrl.text.replaceAll(',', ''));
            if (s != null && s > 0) empBody['gross_salary'] = s;
          case 'transfer':
            empBody['department'] = _departmentCtrl.text.trim();
          case 'terminate':
            empBody['is_active'] = false;
          case 'rehire':
            empBody['is_active']  = true;
            empBody['position']   = _positionCtrl.text.trim();
            final s = double.tryParse(_salaryCtrl.text.replaceAll(',', ''));
            if (s != null && s > 0) empBody['gross_salary'] = s;
          case 'salary_review':
            final s = double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0;
            empBody['gross_salary'] = s;
          case 'suspension':
            empBody['is_active'] = false;
          case 'contract_renewal':
            empBody['contract_type'] = _contractType;
            if (_effectiveDate != null) {
              empBody['start_date'] = _fmtDate(_effectiveDate!);
            }
        }
        // Fire-and-forget: HR action already saved; best-effort employee update
        await TeamService.updateEmployee(
            widget.token, widget.employee.id!, empBody);
      }

      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(_successMessage(type, sw))));
      widget.onSaved();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Field helpers ─────────────────────────────────────────────────────────

  Future<void> _pickDate(bool effective, bool sw) async {
    final initial = effective ? (_effectiveDate ?? DateTime.now()) : _actionDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (effective) {
          _effectiveDate = picked;
        } else {
          _actionDate = picked;
        }
      });
    }
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon,
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
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded,
              size: 20, color: _kSecondary),
          filled: true,
          fillColor: _kBackground,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(
          value != null ? _fmtDate(value) : '—',
          style: TextStyle(
              color: value != null ? _kPrimary : Colors.grey.shade400,
              fontSize: 14),
        ),
      ),
    );
  }

  Widget _descField(bool sw, {bool required = false}) {
    return TextField(
      controller: _descCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: required
            ? (sw ? 'Sababu' : 'Reason')
            : (sw ? 'Maelezo (hiari)' : 'Description (optional)'),
        prefixIcon:
            const Icon(Icons.notes_rounded, size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _contractDropdown(bool sw) {
    String label(String t) {
      switch (t) {
        case 'permanent': return sw ? 'Kudumu' : 'Permanent';
        case 'contract':  return sw ? 'Mkataba' : 'Contract';
        case 'part_time': return sw ? 'Sehemu ya Wakati' : 'Part-time';
        default:          return t;
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: _contractType,
      decoration: InputDecoration(
        labelText: sw ? 'Aina ya Mkataba' : 'Contract Type',
        prefixIcon: const Icon(Icons.description_rounded,
            size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _contractTypes
          .map((t) => DropdownMenuItem(value: t, child: Text(label(t))))
          .toList(),
      onChanged: (v) => setState(() => _contractType = v ?? 'permanent'),
    );
  }

  Widget _ratingSelector(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Tathmini (1–5)' : 'Rating (1–5)',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = star),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  _rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 32,
                  color: _rating >= star ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            );
          }),
        ),
        if (_rating > 0) ...[
          const SizedBox(height: 4),
          Text(
            [
              '',
              sw ? 'Mbaya (1)' : 'Poor (1)',
              sw ? 'Inabidi Kuboresha (2)' : 'Needs Improvement (2)',
              sw ? 'Wastani (3)' : 'Average (3)',
              sw ? 'Nzuri (4)' : 'Good (4)',
              sw ? 'Bora Sana (5)' : 'Excellent (5)',
            ][_rating],
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
        ],
      ],
    );
  }

  Widget _certTypeDropdown(bool sw) {
    final options = <String, String>{
      'service':      sw ? 'Cheti cha Huduma'       : 'Certificate of Service',
      'appreciation': sw ? 'Barua ya Shukrani'       : 'Letter of Appreciation',
      'training':     sw ? 'Kukamilisha Mafunzo'     : 'Training Completion',
      'award':        sw ? 'Tuzo'                    : 'Award',
      'other':        sw ? 'Nyingine'               : 'Other',
    };
    return DropdownButtonFormField<String>(
      initialValue: _certType,
      decoration: InputDecoration(
        labelText: sw ? 'Aina ya Cheti' : 'Certificate Type',
        prefixIcon: const Icon(Icons.workspace_premium_rounded,
            size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _certType = v ?? 'service'),
    );
  }

  Widget _warningBanner(String message, Color color, {IconData icon = Icons.warning_amber_rounded}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  // ── Action-specific field sets ─────────────────────────────────────────────

  List<Widget> _actionFields(bool sw) {
    final type = _selected?.type ?? '';
    const gap = SizedBox(height: 10);

    switch (type) {
      case 'promote':
        return [
          _textField(_positionCtrl, sw ? 'Nafasi Mpya' : 'New Position',
              Icons.work_rounded),
          gap,
          _textField(_departmentCtrl, sw ? 'Idara Mpya (hiari)' : 'New Department (optional)',
              Icons.business_rounded),
          gap,
          _textField(_salaryCtrl,
              sw ? 'Mshahara Mpya (TZS)' : 'New Salary (TZS)',
              Icons.payments_rounded,
              keyboardType: TextInputType.number),
          gap,
          _dateField(sw ? 'Tarehe ya Kukuza' : 'Promotion Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw),
        ];

      case 'transfer':
        return [
          _textField(_departmentCtrl, sw ? 'Idara Mpya' : 'New Department',
              Icons.business_rounded),
          gap,
          _dateField(sw ? 'Tarehe ya Uhamishaji' : 'Transfer Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw),
        ];

      case 'terminate':
        return [
          _warningBanner(
            sw
                ? 'Hatua hii itafunga akaunti ya mfanyakazi. Hakikisha umechukua hatua sahihi za kisheria.'
                : 'This will deactivate the employee. Ensure proper legal offboarding steps are followed.',
            Colors.red,
            icon: Icons.dangerous_rounded,
          ),
          gap,
          _dateField(sw ? 'Tarehe ya Kumaliza' : 'Termination Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw, required: true),
        ];

      case 'rehire':
        return [
          _textField(_positionCtrl, sw ? 'Nafasi' : 'Position',
              Icons.work_rounded),
          gap,
          _textField(_salaryCtrl,
              sw ? 'Mshahara (TZS)' : 'Salary (TZS)',
              Icons.payments_rounded,
              keyboardType: TextInputType.number),
          gap,
          _dateField(sw ? 'Tarehe ya Kuanza' : 'Start Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw),
        ];

      case 'salary_review':
        return [
          _textField(_salaryCtrl,
              sw ? 'Mshahara Mpya (TZS/mwezi)' : 'New Salary (TZS/month)',
              Icons.payments_rounded,
              keyboardType: TextInputType.number),
          gap,
          _dateField(sw ? 'Tarehe ya Mapitio' : 'Review Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _dateField(sw ? 'Tarehe ya Kutumika' : 'Effective Date', _effectiveDate,
              () => _pickDate(true, sw)),
          gap,
          _descField(sw),
        ];

      case 'bonus':
        return [
          _textField(_bonusAmtCtrl,
              sw ? 'Kiasi cha Bonasi (TZS)' : 'Bonus Amount (TZS)',
              Icons.card_giftcard_rounded,
              keyboardType: TextInputType.number),
          gap,
          _dateField(sw ? 'Tarehe' : 'Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw),
        ];

      case 'warning':
        return [
          _dateField(sw ? 'Tarehe ya Onyo' : 'Warning Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw, required: true),
        ];

      case 'final_warning':
        return [
          _warningBanner(
            sw
                ? 'Onyo la Mwisho ni hatua kubwa ya kisheria. Hakikisha umefuata mchakato sahihi wa HR.'
                : 'Final Warning is a serious legal step. Ensure proper HR procedure has been followed.',
            Colors.orange,
          ),
          gap,
          _dateField(sw ? 'Tarehe ya Onyo' : 'Warning Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw, required: true),
        ];

      case 'suspension':
        return [
          _warningBanner(
            sw
                ? 'Kusimamishwa kutafuta mfanyakazi asifanye kazi hadi tarehe ya kurudi.'
                : 'Suspension will deactivate the employee until the return date.',
            Colors.orange,
          ),
          gap,
          _dateField(sw ? 'Tarehe ya Kusimamishwa' : 'Suspension Date',
              _actionDate, () => _pickDate(false, sw)),
          gap,
          _dateField(sw ? 'Tarehe ya Kurudi' : 'Return Date', _effectiveDate,
              () => _pickDate(true, sw)),
          gap,
          _descField(sw, required: true),
        ];

      case 'leave_approval':
        final days = (_effectiveDate != null)
            ? _effectiveDate!.difference(_actionDate).inDays + 1
            : null;
        return [
          _dateField(sw ? 'Tarehe ya Kuanza Likizo' : 'Leave Start', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _dateField(sw ? 'Tarehe ya Kumaliza Likizo' : 'Leave End',
              _effectiveDate, () => _pickDate(true, sw)),
          if (days != null && days > 0) ...[
            gap,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sw ? 'Siku za likizo: $days' : 'Leave duration: $days days',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
          gap,
          _descField(sw),
        ];

      case 'leave_rejection':
        return [
          _dateField(sw ? 'Tarehe' : 'Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw, required: true),
        ];

      case 'performance_review':
        return [
          _dateField(sw ? 'Tarehe ya Tathmini' : 'Review Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _ratingSelector(sw),
          gap,
          _descField(sw),
        ];

      case 'pip':
        return [
          _dateField(sw ? 'Tarehe ya Kuanza' : 'Start Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _dateField(sw ? 'Tarehe ya Mwisho' : 'End Date', _effectiveDate,
              () => _pickDate(true, sw)),
          gap,
          _descField(sw),
        ];

      case 'certificate':
        return [
          _dateField(sw ? 'Tarehe' : 'Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _certTypeDropdown(sw),
          gap,
          _descField(sw),
        ];

      case 'contract_renewal':
        return [
          _contractDropdown(sw),
          gap,
          _dateField(sw ? 'Tarehe ya Kuanza' : 'New Start Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _dateField(sw ? 'Tarehe ya Kumalizika (hiari)' : 'End Date (optional)',
              _effectiveDate, () => _pickDate(true, sw)),
          gap,
          _descField(sw),
        ];

      default:
        return [
          _dateField(sw ? 'Tarehe' : 'Date', _actionDate,
              () => _pickDate(false, sw)),
          gap,
          _descField(sw),
        ];
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final preSelected = widget.initialAction != null && _selected != null;

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

            if (preSelected) ...[
              // Focused header when opened from pill
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(_selected!.icon, size: 20, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sw ? _selected!.labelSw : _selected!.labelEn,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary)),
                      Text(sw ? 'Rekodi hatua' : 'Record action',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ],
              ),
            ] else ...[
              // Full picker when no pre-selection
              Text(sw ? 'Hatua ya HR' : 'HR Action',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              const SizedBox(height: 16),
              Text(sw ? 'Aina ya Hatua' : 'Action Type',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary)),
              const SizedBox(height: 8),
              ..._buildCategoryPicker(sw),
            ],

            const SizedBox(height: 20),

            // Action-specific fields
            ..._actionFields(sw),

            const SizedBox(height: 16),

            // Save
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
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryPicker(bool sw) {
    final categories = <String, List<_ActionDef>>{};
    for (final a in _kActions) {
      categories.putIfAbsent(a.category, () => []).add(a);
    }
    final catLabel = {
      'employment':   sw ? 'Ajira'    : 'Employment',
      'compensation': sw ? 'Malipo'   : 'Compensation',
      'discipline':   sw ? 'Nidhamu'  : 'Discipline',
      'leave':        sw ? 'Likizo'   : 'Leave',
      'performance':  sw ? 'Utendaji' : 'Performance',
      'document':     sw ? 'Hati'     : 'Documents',
    };

    return categories.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(catLabel[entry.key] ?? entry.key,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: entry.value.map((a) {
              final sel = _selected?.type == a.type;
              return GestureDetector(
                onTap: () => setState(() {
                  _selected = a;
                  _rating = 0;
                  _effectiveDate = null;
                  _descCtrl.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _kPrimary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon,
                          size: 14,
                          color: sel ? Colors.white : _kSecondary),
                      const SizedBox(width: 6),
                      Text(sw ? a.labelSw : a.labelEn,
                          style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.white : _kPrimary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }).toList();
  }
}

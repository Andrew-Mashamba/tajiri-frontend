// lib/team/pages/employee_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/compensation_service.dart';
import '../services/team_service.dart';
import '../widgets/add_hr_action_sheet.dart';
import '../widgets/compensation_sheet.dart';
import '../models/work_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';
import 'job_description_page.dart';
import 'employee_tasks_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class _ActionDef {
  final String type;
  final String category;
  final String labelEn;
  final String labelSw;
  final IconData icon;
  const _ActionDef(this.type, this.category, this.labelEn, this.labelSw, this.icon);
}

const _kActions = <_ActionDef>[
  _ActionDef('promote', 'employment', 'Promotion', 'Kukuza Cheo', Icons.trending_up_rounded),
  _ActionDef('transfer', 'employment', 'Transfer', 'Uhamishaji', Icons.swap_horiz_rounded),
  _ActionDef('rehire', 'employment', 'Rehire', 'Kuajiri Tena', Icons.person_add_alt_1_rounded),
  _ActionDef('terminate', 'employment', 'Terminate', 'Maliza Mkataba', Icons.exit_to_app_rounded),
  _ActionDef('salary_review', 'compensation', 'Salary Review', 'Pitia Mshahara', Icons.payments_rounded),
  _ActionDef('bonus', 'compensation', 'Bonus', 'Bonasi', Icons.card_giftcard_rounded),
  _ActionDef('warning', 'discipline', 'Warning', 'Onyo', Icons.warning_amber_rounded),
  _ActionDef('final_warning', 'discipline', 'Final Warning', 'Onyo la Mwisho', Icons.report_rounded),
  _ActionDef('suspension', 'discipline', 'Suspend', 'Simamisha', Icons.block_rounded),
  _ActionDef('leave_approval', 'leave', 'Approve Leave', 'Idhini Likizo', Icons.beach_access_rounded),
  _ActionDef('leave_rejection', 'leave', 'Reject Leave', 'Kataa Likizo', Icons.event_busy_rounded),
  _ActionDef('performance_review', 'performance', 'Perf. Review', 'Tathmini', Icons.bar_chart_rounded),
  _ActionDef('pip', 'performance', 'Impr. Plan', 'Mpango', Icons.edit_note_rounded),
  _ActionDef('certificate', 'document', 'Certificate', 'Cheti', Icons.workspace_premium_rounded),
  _ActionDef('contract_renewal', 'document', 'Renew Contract', 'Fanya Upya', Icons.description_rounded),
];

class EmployeeDetailPage extends StatefulWidget {
  final int employeeId;
  final String token;
  final int businessId;
  final VoidCallback? onChanged;

  const EmployeeDetailPage({
    super.key,
    required this.employeeId,
    required this.token,
    required this.businessId,
    this.onChanged,
  });

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  Employee? _employee;
  bool _loading = true;
  String? _error;
  List<HrAction> _hrActions = [];
  JobDescription? _jobDescription;
  List<Kpi> _kpis = [];
  final Map<int, KpiEntry?> _latestKpiEntry = {};
  List<WorkTask> _recentTasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        TeamService.getEmployee(widget.token, widget.employeeId),
        TeamService.getHrActions(widget.token, widget.employeeId),
        WorkService.getJobDescription(widget.token, widget.employeeId),
        WorkService.getKpis(widget.token, widget.employeeId),
        WorkService.getEmployeeTasks(widget.token, widget.employeeId),
      ]);
      if (!mounted) return;
      final empRes = results[0] as dynamic;
      final actRes = results[1] as dynamic;
      final jdRes = results[2] as WorkResult<JobDescription>;
      final kpiRes = results[3] as WorkListResult<Kpi>;
      final taskRes = results[4] as WorkListResult<WorkTask>;
      setState(() {
        _loading = false;
        if (empRes.success) { _employee = empRes.data; }
        else { _error = empRes.message ?? 'Failed to load'; }
        if (actRes.success) { _hrActions = actRes.data as List<HrAction>; }
        _jobDescription = jdRes.data;
        _kpis = kpiRes.data;
        _recentTasks = taskRes.data.take(3).toList();
      });
      for (final kpi in _kpis) {
        if (kpi.id != null) _loadLatestEntry(kpi.id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadLatestEntry(int kpiId) async {
    final res = await WorkService.getKpiEntries(widget.token, kpiId);
    if (!mounted) return;
    setState(() => _latestKpiEntry[kpiId] = res.data.isNotEmpty ? res.data.first : null);
  }

  void _openEdit(bool sw) {
    if (_employee == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CompensationSheet(
        token: widget.token,
        businessId: widget.businessId,
        employee: _employee,
        onSaved: () { _load(); widget.onChanged?.call(); },
      ),
    );
  }

  Future<void> _confirmRemove(bool sw) async {
    final emp = _employee;
    if (emp == null || emp.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ondoa Mwanatimu' : 'Remove Team Member',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw
            ? 'Ondoa ${emp.name} kutoka kwenye biashara?'
            : 'Remove ${emp.name} from the business?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Ondoa' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final res = await TeamService.removeEmployee(widget.token, emp.id!);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Ameondolewa' : 'Removed')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) { widget.onChanged?.call(); nav.pop(); }
  }

  void _openActionSheet(_ActionDef action, bool sw) {
    final emp = _employee;
    if (emp == null || emp.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddHrActionSheet(
        token: widget.token,
        businessId: widget.businessId,
        employeeId: emp.id!,
        employee: emp,
        initialAction: action.type,
        initialCategory: action.category,
        onSaved: _load,
      ),
    );
  }

  Future<void> _confirmDeleteAction(HrAction action, bool sw) async {
    if (action.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Rekodi' : 'Delete Record',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw ? 'Futa rekodi hii ya HR?' : 'Delete this HR record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await TeamService.deleteHrAction(widget.token, action.id!);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Imefutwa' : 'Deleted')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) _load();
  }

  // ── Helpers ──

  String _fmtTzs(double amount) {
    final nf = NumberFormat('#,###', 'en');
    return 'TZS ${nf.format(amount.round())}';
  }

  String _contractLabel(String type, bool sw) {
    switch (type) {
      case 'permanent': return sw ? 'Kudumu' : 'Permanent';
      case 'contract':  return sw ? 'Mkataba' : 'Contract';
      case 'part_time': return sw ? 'Sehemu ya Wakati' : 'Part-time';
      default:          return type;
    }
  }

  String _actionLabel(_ActionDef a, bool sw) => sw ? a.labelSw : a.labelEn;

  String _historyLabel(String type, bool sw) {
    try {
      return _actionLabel(_kActions.firstWhere((a) => a.type == type), sw);
    } catch (_) {
      return type;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'employment':   return Icons.work_history_rounded;
      case 'compensation': return Icons.payments_rounded;
      case 'discipline':   return Icons.warning_amber_rounded;
      case 'leave':        return Icons.beach_access_rounded;
      case 'performance':  return Icons.trending_up_rounded;
      case 'document':     return Icons.description_rounded;
      default:             return Icons.history_rounded;
    }
  }

  Color _badgeColor(String actionType) {
    switch (actionType) {
      case 'promote':
      case 'rehire':            return Colors.green;
      case 'transfer':          return Colors.blue;
      case 'salary_review':
      case 'contract_renewal':  return const Color(0xFF1565C0);
      case 'bonus':
      case 'certificate':       return const Color(0xFFF57F17);
      case 'terminate':
      case 'warning':
      case 'final_warning':
      case 'leave_rejection':   return Colors.red;
      case 'suspension':
      case 'pip':               return Colors.orange;
      case 'leave_approval':    return Colors.teal;
      case 'performance_review': return Colors.indigo;
      default:                  return Colors.grey;
    }
  }

  String _metaDetail(HrAction a, bool sw) {
    final m = a.metadata;
    if (m == null) return '';
    final fmt = NumberFormat('#,###', 'en');
    switch (a.actionType) {
      case 'promote':
      case 'rehire':
        final oldPos = m['old_position']?.toString() ?? '';
        final newPos = m['new_position']?.toString() ?? '';
        final oldSalRaw = m['old_salary'];
        final newSalRaw = m['new_salary'];
        final parts = <String>[];
        if (oldPos.isNotEmpty && newPos.isNotEmpty && oldPos != newPos) {
          parts.add('$oldPos → $newPos');
        }
        if (oldSalRaw != null && newSalRaw != null) {
          final oldAmt = (oldSalRaw is num)
              ? oldSalRaw.toDouble()
              : double.tryParse(oldSalRaw.toString()) ?? 0;
          final newAmt = (newSalRaw is num)
              ? newSalRaw.toDouble()
              : double.tryParse(newSalRaw.toString()) ?? 0;
          if (oldAmt != newAmt) {
            parts.add('TZS ${fmt.format(oldAmt.round())} → TZS ${fmt.format(newAmt.round())}');
          }
        }
        return parts.join(' • ');
      case 'transfer':
        final oldDept = m['old_department']?.toString() ?? '';
        final newDept = m['new_department']?.toString() ?? '';
        if (oldDept.isNotEmpty && newDept.isNotEmpty) return '$oldDept → $newDept';
        return newDept;
      case 'salary_review':
        final oldSalRaw = m['old_salary'];
        final newSalRaw = m['new_salary'];
        if (oldSalRaw != null && newSalRaw != null) {
          final oldAmt = (oldSalRaw is num)
              ? oldSalRaw.toDouble()
              : double.tryParse(oldSalRaw.toString()) ?? 0;
          final newAmt = (newSalRaw is num)
              ? newSalRaw.toDouble()
              : double.tryParse(newSalRaw.toString()) ?? 0;
          return 'TZS ${fmt.format(oldAmt.round())} → TZS ${fmt.format(newAmt.round())}';
        }
        return '';
      case 'bonus':
        final amt = m['bonus_amount'];
        if (amt != null) {
          final d = (amt is num) ? amt.toDouble() : double.tryParse(amt.toString()) ?? 0;
          return 'TZS ${fmt.format(d.round())}';
        }
        return '';
      case 'performance_review':
        final r = m['rating'];
        if (r != null) return '★ $r / 5';
        return '';
      case 'certificate':
        final ct = m['certificate_type']?.toString() ?? '';
        final labels = {
          'service':      sw ? 'Cheti cha Huduma'    : 'Certificate of Service',
          'appreciation': sw ? 'Barua ya Shukrani'   : 'Letter of Appreciation',
          'training':     sw ? 'Kukamilisha Mafunzo' : 'Training Completion',
          'award':        sw ? 'Tuzo'                : 'Award',
          'other':        sw ? 'Nyingine'            : 'Other',
        };
        return labels[ct] ?? ct;
      case 'contract_renewal':
        final ctype = m['contract_type']?.toString() ?? '';
        switch (ctype) {
          case 'permanent': return sw ? 'Kudumu'            : 'Permanent';
          case 'contract':  return sw ? 'Mkataba'           : 'Contract';
          case 'part_time': return sw ? 'Sehemu ya Wakati'  : 'Part-time';
          default: return ctype;
        }
      default:
        return '';
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _deductionRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Text('- ${_fmtTzs(amount)}',
              style: const TextStyle(fontSize: 13, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary));
  }

  Widget _workProfileCard(Employee emp, bool sw) {
    final hasJd = _jobDescription != null && _jobDescription!.roleSummary.isNotEmpty;
    int onTrack = 0, belowTarget = 0;
    for (final kpi in _kpis) {
      if (kpi.id == null) continue;
      final entry = _latestKpiEntry[kpi.id];
      if (entry == null) continue;
      if (entry.actualValue >= kpi.targetValue) { onTrack++; }
      else { belowTarget++; }
    }
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel(sw ? 'Wasifu wa Kazi' : 'Work Profile'),
          const SizedBox(height: 8),
          if (hasJd) ...[
            Text(_jobDescription!.roleSummary,
                style: const TextStyle(fontSize: 13, color: _kPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
          ] else ...[
            Text(sw ? 'Haijawekwa' : 'Not set',
                style: const TextStyle(
                    fontSize: 13, color: _kSecondary, fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
          ],
          Row(children: [
            if (_kpis.isNotEmpty) ...[
              if (onTrack > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('$onTrack ${sw ? 'kwenye lengo' : 'on track'}',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                ),
              if (belowTarget > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('$belowTarget ${sw ? 'chini ya lengo' : 'below target'}',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                ),
              if (onTrack == 0 && belowTarget == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${_kpis.length} KPI${_kpis.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 11, color: _kPrimary)),
                ),
              const SizedBox(width: 4),
            ],
            const Spacer(),
            OutlinedButton(
              onPressed: () {
                if (emp.id == null) return;
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => JobDescriptionPage(
                          employeeId: emp.id!,
                          businessId: widget.businessId,
                          employeeName: emp.name,
                          ownerName: emp.name,
                          token: widget.token,
                        ))).then((_) => _load());
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12)),
              child: Text(sw ? 'Tazama / Hariri' : 'View / Edit'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _tasksCard(Employee emp, bool sw) {
    final pending = _recentTasks.where((t) => t.status == 'pending').length;
    final inProg = _recentTasks.where((t) => t.status == 'in_progress').length;
    final done = _recentTasks.where((t) => t.status == 'done').length;
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _sectionLabel(sw ? 'Kazi' : 'Tasks')),
            TextButton(
              onPressed: () {
                if (emp.id == null) return;
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EmployeeTasksPage(
                          employeeId: emp.id!,
                          businessId: widget.businessId,
                          employeeName: emp.name,
                          token: widget.token,
                        ))).then((_) => _load());
              },
              style: TextButton.styleFrom(
                  foregroundColor: _kPrimary,
                  textStyle: const TextStyle(fontSize: 12)),
              child: Text(sw ? 'Tazama Zote / Gawanya' : 'See All / Assign'),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _chip('${sw ? 'Inasubiri' : 'Pending'} ($pending)'),
            _chip('${sw ? 'Inaendelea' : 'In Progress'} ($inProg)'),
            _chip('${sw ? 'Imekamilika' : 'Done'} ($done)'),
          ]),
        ]),
      ),
    );
  }

  // ── HR action pill button ──
  Widget _actionPill(_ActionDef action, bool sw) {
    return GestureDetector(
      onTap: () => _openActionSheet(action, sw),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kBackground,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 13, color: _kSecondary),
            const SizedBox(width: 5),
            Text(_actionLabel(action, sw),
                style: const TextStyle(fontSize: 12, color: _kPrimary)),
          ],
        ),
      ),
    );
  }

  // ── HR action history tile ──
  Widget _historyTile(HrAction a, bool sw) {
    final dateStr = DateFormat('dd MMM yyyy').format(a.actionDate);
    final color = _badgeColor(a.actionType);
    final meta = _metaDetail(a, sw);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(_categoryIcon(a.category), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(_historyLabel(a.actionType, sw),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(dateStr,
                          style: TextStyle(fontSize: 10, color: color)),
                    ),
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (a.description != null && a.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon:
                const Icon(Icons.close_rounded, size: 15, color: Colors.red),
            onPressed: () => _confirmDeleteAction(a, sw),
          ),
        ],
      ),
    );
  }

  Widget? _disciplineAlertCard(bool sw) {
    final disciplineCount = _hrActions
        .where((a) =>
            a.actionType == 'warning' || a.actionType == 'final_warning')
        .length;
    if (disciplineCount < 2) return null;
    final hasFinal = _hrActions.any((a) => a.actionType == 'final_warning');
    final msg = hasFinal
        ? (sw
            ? 'Mfanyakazi huyu ana Onyo la Mwisho. Fikiria hatua zaidi kama ni lazima.'
            : 'This employee has a Final Warning on record. Consider next steps if issues continue.')
        : (sw
            ? 'Mfanyakazi huyu ana maonyo $disciplineCount. Kama tatizo linaendelea, toa Onyo la Mwisho.'
            : 'This employee has $disciplineCount warnings. If issues persist, consider a Final Warning.');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 12, color: Colors.orange.shade800)),
          ),
        ],
      ),
    );
  }

  Widget? _statusBanner(Employee emp, bool sw) {
    if (!emp.isActive) {
      // Check if suspended (has a suspension action with a return date)
      final suspensions = _hrActions
          .where((a) => a.actionType == 'suspension')
          .toList()
        ..sort((a, b) => b.actionDate.compareTo(a.actionDate));
      if (suspensions.isNotEmpty && suspensions.first.effectiveDate != null) {
        final returnDate = suspensions.first.effectiveDate!;
        final returnStr = DateFormat('dd MMM yyyy').format(returnDate);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.block_rounded,
                  color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw
                      ? 'Amesimamishwa — Anarudi: $returnStr'
                      : 'Suspended — Return date: $returnStr',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
    }
    // Check for active PIP (most recent PIP with future end date)
    final pips = _hrActions
        .where((a) => a.actionType == 'pip')
        .toList()
      ..sort((a, b) => b.actionDate.compareTo(a.actionDate));
    if (pips.isNotEmpty && pips.first.effectiveDate != null) {
      final endDate = pips.first.effectiveDate!;
      if (endDate.isAfter(DateTime.now())) {
        final daysLeft = endDate.difference(DateTime.now()).inDays;
        final endStr = DateFormat('dd MMM yyyy').format(endDate);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepOrange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  color: Colors.deepOrange.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw
                      ? 'PIP Inaendelea — Inaisha: $endStr ($daysLeft siku zilizobaki)'
                      : 'Improvement Plan Active — Ends: $endStr ($daysLeft days remaining)',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.deepOrange.shade800,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final emp = _employee;
    final statusBanner = emp != null ? _statusBanner(emp, sw) : null;
    final disciplineBanner = _disciplineAlertCard(sw);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
            emp?.name ?? (sw ? 'Mwanatimu' : 'Team Member'),
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (emp != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: _kPrimary),
              onPressed: () => _openEdit(sw),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _confirmRemove(sw),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white),
                          child: Text(sw ? 'Jaribu Tena' : 'Retry')),
                    ],
                  ),
                )
              : emp == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // ── Avatar card ──
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Text(
                                      emp.name.isNotEmpty
                                          ? emp.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: _kPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(emp.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _kPrimary)),
                                  if (emp.position != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(emp.position!,
                                          style: const TextStyle(
                                              fontSize: 14, color: _kSecondary)),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      if (emp.department != null)
                                        _chip(emp.department!),
                                      if (emp.contractType != null)
                                        _chip(_contractLabel(emp.contractType!, sw)),
                                      _chip(
                                        emp.isActive
                                            ? (sw ? 'Hai' : 'Active')
                                            : (sw ? 'Hayupo' : 'Inactive'),
                                        color: emp.isActive
                                            ? Colors.green.shade50
                                            : Colors.grey.shade100,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Status and discipline banners ──
                          if (statusBanner != null) statusBanner,
                          if (disciplineBanner != null) disciplineBanner,

                          // ── Details card ──
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel(sw ? 'Maelezo' : 'Details'),
                                  const SizedBox(height: 8),
                                  if (emp.phone != null)
                                    _infoRow(Icons.phone_rounded,
                                        sw ? 'Simu' : 'Phone', emp.phone!),
                                  if (emp.bankName != null)
                                    _infoRow(Icons.account_balance_rounded,
                                        sw ? 'Benki' : 'Bank', emp.bankName!),
                                  if (emp.bankAccount != null)
                                    _infoRow(Icons.credit_card_rounded,
                                        sw ? 'Akaunti' : 'Account',
                                        emp.bankAccount!),
                                  if (emp.startDate != null)
                                    _infoRow(
                                        Icons.calendar_today_rounded,
                                        sw ? 'Ilianza' : 'Start',
                                        '${emp.startDate!.year}-${emp.startDate!.month.toString().padLeft(2, '0')}-${emp.startDate!.day.toString().padLeft(2, '0')}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Compensation card ──
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel(sw ? 'Malipo' : 'Compensation'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(sw ? 'Mshahara Jumla' : 'Gross Salary',
                                          style: const TextStyle(
                                              fontSize: 13, color: _kPrimary)),
                                      Text(_fmtTzs(emp.grossSalary),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _kPrimary)),
                                    ],
                                  ),
                                  if (emp.applyPAYE) ...[
                                    const SizedBox(height: 4),
                                    _deductionRow('PAYE',
                                        CompensationService.computePAYE(
                                            emp.grossSalary)),
                                  ],
                                  if (emp.applyNSSF) ...[
                                    const SizedBox(height: 4),
                                    _deductionRow('NSSF',
                                        CompensationService.computeNSSF(
                                            emp.grossSalary)),
                                  ],
                                  if (emp.applyNHIF) ...[
                                    const SizedBox(height: 4),
                                    _deductionRow('NHIF',
                                        CompensationService.computeNHIF(
                                            emp.grossSalary)),
                                  ],
                                  for (final a in emp.allowances) ...[
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('+ ${a.name}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: _kSecondary)),
                                          Text(_fmtTzs(a.amount),
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: _kPrimary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(sw ? 'Mshahara Halisi' : 'Net Pay',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: _kPrimary)),
                                      Text(
                                        _fmtTzs(
                                            CompensationService.computeNetPay(
                                          grossSalary: emp.grossSalary,
                                          allowances: emp.allowances,
                                          applyPAYE: emp.applyPAYE,
                                          applyNSSF: emp.applyNSSF,
                                          applyNHIF: emp.applyNHIF,
                                        )),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Work Profile card ──
                          _workProfileCard(emp, sw),
                          const SizedBox(height: 12),

                          // ── Tasks card ──
                          _tasksCard(emp, sw),
                          const SizedBox(height: 12),

                          // ── HR Actions pill section ──
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel(sw ? 'Hatua za HR' : 'HR Actions'),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _kActions
                                        .map((a) => _actionPill(a, sw))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Action history ──
                          if (_hrActions.isNotEmpty)
                            Card(
                              color: _kCardBg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel(
                                        sw ? 'Historia' : 'Action History'),
                                    const SizedBox(height: 12),
                                    ..._hrActions.map((a) => _historyTile(a, sw)),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }
}

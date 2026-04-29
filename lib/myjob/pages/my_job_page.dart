// lib/myjob/pages/my_job_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';
import '../../team/services/work_service.dart' show WorkResult, WorkListResult;
import 'my_job_description_page.dart';
import 'my_tasks_page.dart';
import 'my_kpis_page.dart';
import 'my_payslips_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyJobPage extends StatefulWidget {
  final String token;

  const MyJobPage({super.key, required this.token});

  @override
  State<MyJobPage> createState() => _MyJobPageState();
}

class _MyJobPageState extends State<MyJobPage> {
  JobDescription? _jd;
  List<WorkTask> _todayStanding = [];
  List<WorkTask> _todayAdhoc = [];
  List<Kpi> _kpis = [];
  final Map<int, List<KpiEntry>> _kpiEntries = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        MyJobService.getMyJobDescription(widget.token),
        MyJobService.getMyTasks(widget.token),
        MyJobService.getMyKpis(widget.token),
      ]);
      if (!mounted) return;
      final jdRes = results[0] as WorkResult<JobDescription>;
      final tasksRes = results[1] as MyTasksResult;
      final kpiRes = results[2] as WorkListResult<Kpi>;
      setState(() {
        _loading = false;
        _jd = jdRes.data;
        _todayStanding = tasksRes.standingTasks;
        _todayAdhoc = tasksRes.adhocTasks;
        _kpis = kpiRes.data;
      });
      for (final kpi in _kpis.take(3)) {
        if (kpi.id != null) _loadEntries(kpi.id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadEntries(int kpiId) async {
    try {
      final res = await MyJobService.getMyKpiEntries(widget.token, kpiId);
      if (!mounted) return;
      setState(() => _kpiEntries[kpiId] = res.data);
    } catch (_) {}
  }

  int get _pendingCount =>
      _todayStanding.where((t) => !t.isDone).length +
      _todayAdhoc.where((t) => !t.isDone).length;

  int get _totalToday => _todayStanding.length + _todayAdhoc.length;

  int get _doneCount => _totalToday - _pendingCount;

  double get _completionPct => _totalToday == 0 ? 0 : _doneCount / _totalToday;

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary, foregroundColor: Colors.white),
                      child: Text(sw ? 'Jaribu Tena' : 'Retry')),
                ]))
              : _jd == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.work_outline_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                              sw ? 'Meneja wako hajaweka wasifu wako wa kazi bado.'
                                 : "Your manager hasn't set up your job profile yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                        ]),
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MyJobDescriptionPage(
                                      token: widget.token,
                                      jd: _jd!,
                                    ))),
                            child: Card(
                              color: _kCard, elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.badge_outlined,
                                        color: _kPrimary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sw ? 'Nafasi Yangu' : 'My Role',
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w600,
                                              color: _kPrimary)),
                                      const SizedBox(height: 4),
                                      if (_jd!.roleSummary.isNotEmpty)
                                        Text(_jd!.roleSummary,
                                            style: const TextStyle(
                                                fontSize: 12, color: _kSecondary),
                                            maxLines: 2, overflow: TextOverflow.ellipsis),
                                      if (_jd!.reportingTo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                            '${sw ? 'Anarip. kwa' : 'Reports to'}: ${_jd!.reportingTo}',
                                            style: const TextStyle(
                                                fontSize: 11, color: _kSecondary)),
                                      ],
                                    ],
                                  )),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: _kSecondary, size: 18),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _navCard(
                            icon: Icons.check_circle_outline_rounded,
                            title: sw ? 'Kazi za Leo' : "Today's Tasks",
                            subtitle: _totalToday == 0
                                ? (sw ? 'Hakuna kazi leo' : 'No tasks today')
                                : (sw
                                    ? 'Kazi $_doneCount kati ya $_totalToday zimekamilika leo'
                                    : '$_doneCount of $_totalToday tasks done today'),
                            trailing: _totalToday > 0
                                ? SizedBox(
                                    width: 36, height: 36,
                                    child: CircularProgressIndicator(
                                      value: _completionPct,
                                      strokeWidth: 3,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MyTasksPage(token: widget.token))),
                          ),
                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MyKpisPage(token: widget.token))),
                            child: Card(
                              color: _kCard, elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.bar_chart_rounded,
                                          color: _kPrimary, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(sw ? 'Viashiria Vyangu (KPI)' : 'My KPIs',
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w600,
                                            color: _kPrimary))),
                                    if (_kpis.isNotEmpty) _chip('${_kpis.length}'),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: _kSecondary, size: 18),
                                  ]),
                                  if (_kpis.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(sw ? 'Hakuna KPI bado' : 'No KPI targets yet',
                                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    ..._kpis.take(3).map((kpi) {
                                      final entries = _kpiEntries[kpi.id] ?? [];
                                      final last = entries.isNotEmpty ? entries.first : null;
                                      final progress = last != null
                                          ? (last.actualValue / kpi.targetValue).clamp(0.0, 1.0)
                                          : 0.0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                          Row(children: [
                                            Expanded(child: Text(kpi.name,
                                                style: const TextStyle(
                                                    fontSize: 12, color: _kPrimary),
                                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                                            Text(kpi.reviewPeriod,
                                                style: const TextStyle(
                                                    fontSize: 10, color: _kSecondary)),
                                          ]),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation(
                                                progress >= 1.0 ? Colors.green : _kPrimary),
                                            minHeight: 3,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ]),
                                      );
                                    }),
                                  ],
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _navCard(
                            icon: Icons.receipt_long_rounded,
                            title: sw
                                ? 'Stakabadhi za Mishahara'
                                : 'My Payslips',
                            subtitle: sw
                                ? 'Angalia stakabadhi zako za mishahara'
                                : 'View your monthly payslips',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MyPayslipsPage(
                                        token: widget.token))),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int maxSubtitleLines = 2,
    Widget? trailing,
  }) {
    return Card(
      color: _kCard, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _kPrimary, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: maxSubtitleLines, overflow: TextOverflow.ellipsis),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
      );
}

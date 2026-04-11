// lib/dawasco/pages/supply_schedule_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';
import '../widgets/supply_status_indicator.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kGreen = Color(0xFF4CAF50);

class SupplySchedulePage extends StatefulWidget {
  final String? wardId;
  const SupplySchedulePage({super.key, this.wardId});
  @override
  State<SupplySchedulePage> createState() => _SupplySchedulePageState();
}

class _SupplySchedulePageState extends State<SupplySchedulePage> {
  List<SupplySchedule> _schedules = [];
  SupplyStatus? _status;
  bool _loading = true;
  bool _reporting = false;
  String? _error;

  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final _daysSw = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        DawascoService.getSupplySchedule(wardId: widget.wardId),
        if (widget.wardId != null) DawascoService.getSupplyStatus(wardId: widget.wardId),
      ]);
      if (!mounted) return;
      final scheduleR = results[0] as PaginatedResult<SupplySchedule>;
      if (scheduleR.success) _schedules = scheduleR.items;

      if (results.length > 1) {
        final statusR = results[1] as SingleResult<SupplyStatus>;
        if (statusR.success) _status = statusR.data;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  Future<void> _reportStatus(bool isAvailable) async {
    if (widget.wardId == null) return;
    setState(() => _reporting = true);
    try {
      final result = await DawascoService.reportSupplyStatus(widget.wardId!, isAvailable);
      if (!mounted) return;
      setState(() => _reporting = false);
      if (result.success) {
        setState(() => _status = result.data);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_sw ? 'Taarifa imetumwa!' : 'Status reported!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.message ?? (_sw ? 'Imeshindwa' : 'Failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _reporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Ratiba ya Maji' : 'Water Schedule',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: _kSecondary, fontSize: 13),
                      maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text(sw ? 'Jaribu tena' : 'Retry',
                      style: const TextStyle(color: _kPrimary))),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    // Current status
                    if (_status != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _status!.isAvailable ? _kGreen.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          SupplyStatusIndicator(isAvailable: _status!.isAvailable, isSwahili: sw),
                          const Spacer(),
                          Text('${_status!.reportsCount} ${sw ? 'ripoti' : 'reports'}',
                              style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Report buttons
                    Text(sw ? 'Ripoti hali ya maji sasa' : 'Report current water status',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(
                        onPressed: _reporting ? null : () => _reportStatus(true),
                        icon: const Icon(Icons.check_circle_rounded, size: 18, color: _kGreen),
                        label: Text(sw ? 'Maji Yapo' : 'Water ON',
                            style: const TextStyle(fontSize: 13, color: _kGreen)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ))),
                      const SizedBox(width: 10),
                      Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(
                        onPressed: _reporting ? null : () => _reportStatus(false),
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.red),
                        label: Text(sw ? 'Maji Hayapo' : 'Water OFF',
                            style: const TextStyle(fontSize: 13, color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ))),
                    ]),
                    const SizedBox(height: 24),

                    // Weekly schedule
                    Text(sw ? 'Ratiba ya Wiki' : 'Weekly Schedule',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 10),

                    if (_schedules.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(sw ? 'Hakuna ratiba iliyopatikana' : 'No schedule available',
                            style: const TextStyle(color: _kSecondary, fontSize: 13))),
                      )
                    else
                      ..._days.asMap().entries.map((entry) {
                        final dayIdx = entry.key;
                        final dayEn = entry.value;
                        final daySw = _daysSw[dayIdx];
                        final daySchedules = _schedules.where((s) =>
                            s.dayOfWeek.toLowerCase() == dayEn.toLowerCase()).toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            SizedBox(
                              width: 80,
                              child: Text(sw ? daySw : dayEn,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              child: daySchedules.isEmpty
                                  ? Text(sw ? 'Hakuna ratiba' : 'No schedule',
                                      style: TextStyle(fontSize: 12, color: _kPrimary.withValues(alpha: 0.3)))
                                  : Wrap(spacing: 6, runSpacing: 4, children: daySchedules.map((s) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _kPrimary.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${s.startHour.toString().padLeft(2, '0')}:00 - ${s.endHour.toString().padLeft(2, '0')}:00',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList()),
                            ),
                          ]),
                        );
                      }),
                    const SizedBox(height: 32),
                  ]),
                ),
    );
  }
}

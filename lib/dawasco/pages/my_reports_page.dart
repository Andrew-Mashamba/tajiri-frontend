// lib/dawasco/pages/my_reports_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';
import '../widgets/issue_status_timeline.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  List<WaterIssue> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await DawascoService.getMyReports();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _reports = result.items;
        } else {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  String _typeLabel(String type, bool sw) {
    switch (type) {
      case 'leak': return sw ? 'Uvujaji' : 'Leak';
      case 'sewerage': return sw ? 'Maji taka' : 'Sewerage';
      case 'quality': return sw ? 'Ubora wa maji' : 'Water Quality';
      case 'pressure': return sw ? 'Shinikizo' : 'Pressure';
      default: return type;
    }
  }

  String _severityLabel(String severity, bool sw) {
    switch (severity) {
      case 'low': return sw ? 'Ndogo' : 'Low';
      case 'medium': return sw ? 'Wastani' : 'Medium';
      case 'high': return sw ? 'Kubwa' : 'High';
      default: return severity;
    }
  }

  void _showDetail(WaterIssue issue) {
    final sw = _sw;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('${_typeLabel(issue.type, sw)} - ${_severityLabel(issue.severity, sw)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (issue.location != null)
              Text('${sw ? 'Mahali' : 'Location'}: ${issue.location}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            if (issue.description != null) ...[
              const SizedBox(height: 6),
              Text(issue.description!,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 5, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Text('${sw ? 'Iliripotiwa' : 'Reported'}: ${issue.reportedAt.day}/${issue.reportedAt.month}/${issue.reportedAt.year}',
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
            const SizedBox(height: 20),
            IssueStatusTimeline(currentStatus: issue.status, isSwahili: sw),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Ripoti Zangu' : 'My Reports',
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
              : _reports.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.assignment_rounded, size: 48, color: _kPrimary.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text(sw ? 'Hakuna ripoti bado' : 'No reports yet',
                          style: const TextStyle(color: _kSecondary, fontSize: 14)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _kPrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _reports[i];
                          final typeIcons = {
                            'leak': Icons.water_damage_rounded,
                            'sewerage': Icons.plumbing_rounded,
                            'quality': Icons.science_rounded,
                            'pressure': Icons.speed_rounded,
                          };
                          final statusColor = {
                            'reported': Colors.orange,
                            'acknowledged': Colors.blue,
                            'dispatched': Colors.purple,
                            'fixed': const Color(0xFF4CAF50),
                          };

                          return GestureDetector(
                            onTap: () => _showDetail(r),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: _kPrimary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(typeIcons[r.type] ?? Icons.report_rounded, size: 20, color: _kPrimary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(_typeLabel(r.type, sw),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (r.location != null)
                                        Text(r.location!,
                                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ])),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (statusColor[r.status] ?? Colors.grey).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(r.status.toUpperCase(),
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                              color: statusColor[r.status] ?? Colors.grey)),
                                    ),
                                  ]),
                                  const SizedBox(height: 12),
                                  IssueStatusTimeline(currentStatus: r.status, isSwahili: sw),
                                  const SizedBox(height: 8),
                                  Text('${r.reportedAt.day}/${r.reportedAt.month}/${r.reportedAt.year}',
                                      style: const TextStyle(fontSize: 10, color: _kSecondary)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

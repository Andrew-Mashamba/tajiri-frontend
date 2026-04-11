// lib/police/pages/my_reports_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/police_models.dart';
import '../services/police_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  List<CrimeReport> _reports = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final result = await PoliceService.getMyReports();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _reports = result.items;
    });
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia ripoti'
                : 'Failed to load reports')),
      ));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'investigating':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _statusLabel(String status) {
    if (_isSwahili) {
      switch (status) {
        case 'investigating':
          return 'Inachunguzwa';
        case 'resolved':
          return 'Imesuluhishwa';
        default:
          return 'Imepokelewa';
      }
    }
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Ripoti Zangu' : 'My Reports',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadReports,
              color: _kPrimary,
              child: _reports.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(children: [
                          const Icon(Icons.folder_open_rounded,
                              size: 48, color: _kSecondary),
                          const SizedBox(height: 12),
                          Text(
                            _isSwahili
                                ? 'Huna ripoti bado'
                                : 'No reports yet',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                          ),
                        ]),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReportCard(
                        report: _reports[i],
                        isSwahili: _isSwahili,
                        statusColor: _statusColor(_reports[i].status),
                        statusLabel: _statusLabel(_reports[i].status),
                      ),
                    ),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final CrimeReport report;
  final bool isSwahili;
  final Color statusColor;
  final String statusLabel;

  const _ReportCard({
    required this.report,
    required this.isSwahili,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.incidentType[0].toUpperCase() +
                      report.incidentType.substring(1),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.description,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (report.caseNumber != null) ...[
            const SizedBox(height: 6),
            Text(
              '${isSwahili ? 'Kesi' : 'Case'}: ${report.caseNumber}',
              style: const TextStyle(
                  fontSize: 12,
                  color: _kPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            report.createdAt.toString().substring(0, 16),
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
        ],
      ),
    );
  }
}

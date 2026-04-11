// lib/career/pages/applications_page.dart
import 'package:flutter/material.dart';
import '../models/career_models.dart';
import '../services/career_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ApplicationsPage extends StatefulWidget {
  final int userId;
  const ApplicationsPage({super.key, required this.userId});
  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  List<JobApplication> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await CareerService().getMyApplications();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _applications = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Maombi Yangu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _applications.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_rounded, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna maombi', style: TextStyle(color: _kSecondary)),
                  Text('No applications yet', style: TextStyle(color: _kSecondary, fontSize: 12)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applications.length,
                  itemBuilder: (_, i) {
                    final a = _applications[i];
                    final statusColor = Color(a.status.colorValue);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.jobTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(a.company, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(a.status.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                          ),
                          const Spacer(),
                          Text('${a.appliedAt.day}/${a.appliedAt.month}/${a.appliedAt.year}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }
}

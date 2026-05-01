import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/engagement.dart';
import '../services/engagement_service.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// F8 #24 — Public engagement profile reachable by /e/{id}.
/// No auth required; shareable via deep-link. Shows non-sensitive details only.
class PublicEngagementProfilePage extends StatefulWidget {
  final int engagementId;
  const PublicEngagementProfilePage({super.key, required this.engagementId});

  @override
  State<PublicEngagementProfilePage> createState() => _PublicEngagementProfilePageState();
}

class _PublicEngagementProfilePageState extends State<PublicEngagementProfilePage> {
  Engagement? _engagement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await EngagementService.getPublic(id: widget.engagementId);
    if (!mounted) return;
    if (res.success && res.engagement != null) {
      setState(() {
        _engagement = res.engagement;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res.message ?? 'Not found';
      });
    }
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Maelezo ya Mkataba' : 'Engagement Details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _kSecondary),
                      ),
                    ),
                  )
                : _engagement == null
                    ? Center(
                        child: Text(
                          isSw ? 'Mkataba haujapatikana' : 'Engagement not found',
                          style: const TextStyle(color: _kSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(isSw),
                              const SizedBox(height: 20),
                              _buildDetailsSection(isSw),
                              const SizedBox(height: 20),
                              if (_engagement!.milestones.isNotEmpty) ...[
                                _buildMilestonesSection(isSw),
                                const SizedBox(height: 20),
                              ],
                              _buildDescriptionSection(isSw),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildHeader(bool isSw) {
    final e = _engagement!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          _headerRow(
            isSw ? 'Mteja' : 'Customer',
            e.customerName ?? (isSw ? 'Haijulikani' : 'Unknown'),
          ),
          const SizedBox(height: 8),
          _headerRow(
            isSw ? 'Mshirika' : 'Partner',
            e.partnerName ?? (isSw ? 'Haijulikani' : 'Unknown'),
          ),
          const SizedBox(height: 8),
          _headerRow(
            isSw ? 'Aina' : 'Type',
            isSw ? e.contractType.labelSwahili : e.contractType.label,
          ),
          const SizedBox(height: 8),
          _headerRow(
            isSw ? 'Hali' : 'Status',
            isSw ? e.status.labelSwahili : e.status.label,
          ),
        ],
      ),
    );
  }

  Widget _headerRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
      ],
    );
  }

  Widget _buildDetailsSection(bool isSw) {
    final e = _engagement!;
    final dateFmt = DateFormat('dd MMM yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Maelezo' : 'Details',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          _detailRow(Icons.calendar_today_rounded, isSw ? 'Tarehe ya Kuanza' : 'Start Date', dateFmt.format(e.startDate)),
          if (e.endDate != null) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.calendar_today_rounded, isSw ? 'Tarehe ya Mwisho' : 'End Date', dateFmt.format(e.endDate!)),
          ],
          const SizedBox(height: 8),
          _detailRow(
            Icons.schedule_rounded,
            isSw ? 'Muda Uliotolewa' : 'Time Tracked',
            '${e.totalBilledMinutes ~/ 60}h ${e.totalBilledMinutes % 60}m',
          ),
          if (e.skillCategory != null && e.skillCategory!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.category_rounded, isSw ? 'Kategoria' : 'Category', e.skillCategory!),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
      ],
    );
  }

  Widget _buildMilestonesSection(bool isSw) {
    final e = _engagement!;
    final completed = e.milestones.where((m) => m.status == MilestoneStatus.approved || m.status == MilestoneStatus.released).length;
    final total = e.milestones.length;
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Hatua' : 'Milestones',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSw ? '$completed kati ya $total zimekamilika' : '$completed of $total completed',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          ...e.milestones.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  m.status == MilestoneStatus.approved || m.status == MilestoneStatus.released
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: m.status == MilestoneStatus.approved || m.status == MilestoneStatus.released
                      ? const Color(0xFF4CAF50)
                      : _kSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.title,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
                Text(
                  isSw ? m.status.labelSwahili : m.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: m.status == MilestoneStatus.disputed
                        ? const Color(0xFFF44336)
                        : _kSecondary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isSw) {
    final brief = _engagement!.scopeBrief;
    if (brief.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Maelezo' : 'Description',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            brief,
            style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

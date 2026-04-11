// lib/dc/pages/dc_home_page.dart
import 'package:flutter/material.dart';
import '../models/dc_models.dart';
import '../widgets/dc_card.dart';
import '../widgets/emergency_banner.dart';
import 'dc_projects_page.dart';
import 'dc_report_page.dart';
import 'dc_departments_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DcHomePage extends StatelessWidget {
  final int userId;
  final int districtId;
  final District? district;
  final DistrictCommissioner? dc;
  final List<EmergencyAlert> alerts;

  const DcHomePage({
    super.key,
    required this.userId,
    required this.districtId,
    this.district,
    this.dc,
    this.alerts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final activeAlerts = alerts.where((a) => a.active).toList();

    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Emergency banner ──
            if (activeAlerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EmergencyBanner(alert: activeAlerts.first),
              ),

            // ── DC Card ──
            if (dc != null) DcCard(dc: dc!),
            const SizedBox(height: 16),

            // ── Stats row ──
            if (district != null) _buildStatsRow(),
            const SizedBox(height: 20),

            // ── Quick actions ──
            _buildQuickActions(context),
          ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatBox(
          label: 'Watu',
          value: _formatNumber(district!.population),
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Kata',
          value: '${district!.wardCount}',
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Shule',
          value: '${district!.schools}',
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Hospitali',
          value: '${district!.healthFacilities}',
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionTile(
          icon: Icons.report_rounded,
          label: 'Ripoti',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DcReportPage(districtId: districtId),
            ),
          ),
        ),
        _ActionTile(
          icon: Icons.construction_rounded,
          label: 'Miradi',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DcProjectsPage(districtId: districtId),
            ),
          ),
        ),
        _ActionTile(
          icon: Icons.bar_chart_rounded,
          label: 'Takwimu',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Takwimu zinakuja hivi karibuni / Statistics coming soon')),
            );
          },
        ),
        _ActionTile(
          icon: Icons.account_tree_rounded,
          label: 'Idara',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DcDepartmentsPage(districtId: districtId),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

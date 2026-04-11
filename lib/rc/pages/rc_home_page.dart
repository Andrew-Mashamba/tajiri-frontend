// lib/rc/pages/rc_home_page.dart
import 'package:flutter/material.dart';
import '../models/rc_models.dart';
import '../widgets/rc_card.dart';
import '../widgets/mega_project_card.dart';
import '../services/rc_service.dart';
import 'rc_mega_projects_page.dart';
import 'rc_investments_page.dart';
import 'rc_report_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class RcHomePage extends StatefulWidget {
  final int userId;
  final int regionId;
  final Region? region;
  final RegionalCommissioner? rc;

  const RcHomePage({
    super.key,
    required this.userId,
    required this.regionId,
    this.region,
    this.rc,
  });

  @override
  State<RcHomePage> createState() => _RcHomePageState();
}

class _RcHomePageState extends State<RcHomePage> {
  List<MegaProject> _projects = [];
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final result = await RcService().getMegaProjects(widget.regionId);
      if (mounted) {
        setState(() {
          _projects = result.items;
          _loadingProjects = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        color: _kPrimary,
        onRefresh: () async => _loadProjects(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── RC Card ──
            if (widget.rc != null) RcCard(rc: widget.rc!),
            const SizedBox(height: 16),

            // ── Region stats ──
            if (widget.region != null) _buildStatsRow(),
            const SizedBox(height: 20),

            // ── Quick actions ──
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // ── Mega Projects ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Miradi Mikubwa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RcMegaProjectsPage(regionId: widget.regionId),
                    ),
                  ),
                  child: const Text(
                    'Yote',
                    style: TextStyle(color: _kSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingProjects)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kPrimary,
                  ),
                ),
              )
            else if (_projects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Hakuna miradi kwa sasa',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kSecondary, fontSize: 13),
                ),
              )
            else
              ..._projects
                  .take(3)
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MegaProjectCard(project: p),
                      )),
          ],
        ),
    );
  }

  Widget _buildStatsRow() {
    final r = widget.region!;
    return Row(
      children: [
        _Stat(label: 'Wilaya', value: '${r.districtCount}'),
        const SizedBox(width: 12),
        _Stat(label: 'Watu', value: _fmt(r.population)),
        const SizedBox(width: 12),
        _Stat(label: 'Km\u00B2', value: _fmt(r.area.toInt())),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Action(
          icon: Icons.construction_rounded,
          label: 'Miradi',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RcMegaProjectsPage(regionId: widget.regionId),
            ),
          ),
        ),
        _Action(
          icon: Icons.trending_up_rounded,
          label: 'Uwekezaji',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RcInvestmentsPage(regionId: widget.regionId),
            ),
          ),
        ),
        _Action(
          icon: Icons.report_rounded,
          label: 'Ripoti',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RcReportPage(regionId: widget.regionId),
            ),
          ),
        ),
        _Action(
          icon: Icons.bar_chart_rounded,
          label: 'Takwimu',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Takwimu zinakuja hivi karibuni / Statistics coming soon')),
            );
          },
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

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
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 44) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}

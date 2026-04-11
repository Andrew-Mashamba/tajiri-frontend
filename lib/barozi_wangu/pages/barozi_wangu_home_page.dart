// lib/barozi_wangu/pages/barozi_wangu_home_page.dart
import 'package:flutter/material.dart';
import '../models/barozi_wangu_models.dart';
import '../widgets/councillor_card.dart';
import '../widgets/issue_status_timeline.dart';
import 'issue_report_page.dart';
import 'promise_tracker_page.dart';
import 'projects_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BaroziWanguHomePage extends StatelessWidget {
  final int userId;
  final int wardId;
  final Councillor? councillor;
  final List<WardIssue> issues;

  const BaroziWanguHomePage({
    super.key,
    required this.userId,
    required this.wardId,
    this.councillor,
    this.issues = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Councillor card ──
            if (councillor != null)
              CouncillorCard(councillor: councillor!)
            else
              _buildNoCouncillor(),
            const SizedBox(height: 20),

            // ── Quick actions ──
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // ── Recent issues ──
            const Text(
              'Matatizo ya Hivi Karibuni / Recent Issues',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (issues.isEmpty)
              _buildEmpty('Hakuna matatizo yaliyoripotiwa')
            else
              ...issues.take(5).map(_buildIssueItem),
          ],
    );
  }

  Widget _buildNoCouncillor() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: _kSecondary),
          SizedBox(height: 12),
          Text(
            'Diwani wako hajapatikana / Councillor not found',
            style: TextStyle(color: _kSecondary, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionChip(
          icon: Icons.report_rounded,
          label: 'Ripoti Tatizo',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueReportPage(wardId: wardId),
            ),
          ),
        ),
        _ActionChip(
          icon: Icons.checklist_rounded,
          label: 'Ahadi',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PromiseTrackerPage(
                councillorId: councillor?.id ?? 0,
              ),
            ),
          ),
        ),
        _ActionChip(
          icon: Icons.construction_rounded,
          label: 'Miradi',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectsPage(wardId: wardId),
            ),
          ),
        ),
        _ActionChip(
          icon: Icons.forum_rounded,
          label: 'Jukwaa',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jukwaa la mtaa linakuja hivi karibuni / Community forum coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIssueItem(WardIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IssueStatusDot(status: issue.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.statusLabel,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: _kSecondary, fontSize: 13),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
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
        padding: const EdgeInsets.symmetric(vertical: 16),
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

// lib/ofisi_mtaa/pages/ofisi_mtaa_home_page.dart
import 'package:flutter/material.dart';
import '../models/ofisi_mtaa_models.dart';
import '../widgets/official_card.dart';
import 'service_catalog_page.dart';
import 'my_applications_page.dart';
import 'book_appointment_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class OfisiMtaaHomePage extends StatelessWidget {
  final int userId;
  final int mtaaId;
  final List<MtaaOfficial> officials;
  final List<CommunityNotice> notices;

  const OfisiMtaaHomePage({
    super.key,
    required this.userId,
    required this.mtaaId,
    this.officials = const [],
    this.notices = const [],
  });

  @override
  Widget build(BuildContext context) {
    final mwenyekiti =
        officials.where((o) => o.role == 'mwenyekiti').firstOrNull;
    final mtendaji = officials.where((o) => o.role == 'mtendaji').firstOrNull;

    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Officials ──
            if (mwenyekiti != null || mtendaji != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mwenyekiti != null)
                      OfficialCard(official: mwenyekiti),
                    if (mwenyekiti != null && mtendaji != null)
                      const Divider(height: 24),
                    if (mtendaji != null) OfficialCard(official: mtendaji),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Quick actions ──
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // ── Community Notices ──
            const Text(
              'Matangazo ya Mtaa / Community Notices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (notices.isEmpty)
              _buildEmpty('Hakuna matangazo kwa sasa / No notices at the moment')
            else
              ...notices.take(5).map(_buildNoticeItem),
          ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickAction(
          icon: Icons.description_rounded,
          label: 'Huduma',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceCatalogPage(mtaaId: mtaaId),
            ),
          ),
        ),
        _QuickAction(
          icon: Icons.calendar_month_rounded,
          label: 'Panga Miadi',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookAppointmentPage(
                mtaaId: mtaaId,
                officials: officials,
              ),
            ),
          ),
        ),
        _QuickAction(
          icon: Icons.assignment_rounded,
          label: 'Maombi',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MyApplicationsPage(),
            ),
          ),
        ),
        _QuickAction(
          icon: Icons.report_problem_rounded,
          label: 'Ripoti',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ripoti inakuja hivi karibuni / Report feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoticeItem(CommunityNotice notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            notice.type == 'alert'
                ? Icons.warning_rounded
                : notice.type == 'meeting'
                    ? Icons.groups_rounded
                    : Icons.campaign_rounded,
            color: _kPrimary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
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
                  notice.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
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

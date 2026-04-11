// lib/kanisa_langu/pages/kanisa_langu_home_page.dart
import 'package:flutter/material.dart';
import '../models/kanisa_langu_models.dart';
import '../services/kanisa_langu_service.dart';
import '../widgets/announcement_card.dart';
import 'church_events_page.dart';
import 'church_members_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class KanisaLanguHomePage extends StatefulWidget {
  final int userId;
  const KanisaLanguHomePage({super.key, required this.userId});
  @override
  State<KanisaLanguHomePage> createState() => _KanisaLanguHomePageState();
}

class _KanisaLanguHomePageState extends State<KanisaLanguHomePage> {
  ChurchProfile? _church;
  List<ChurchAnnouncement> _announcements = [];
  List<ChurchEvent> _upcomingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final churchR = await KanisaLanguService.getMyChurch();
    if (mounted && churchR.success && churchR.data != null) {
      _church = churchR.data;
      final results = await Future.wait([
        KanisaLanguService.getAnnouncements(_church!.id),
        KanisaLanguService.getEvents(_church!.id),
      ]);
      final annR = results[0] as PaginatedResult<ChurchAnnouncement>;
      final evtR = results[1] as PaginatedResult<ChurchEvent>;
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (annR.success) _announcements = annR.items;
          if (evtR.success) _upcomingEvents = evtR.items;
        });
      }
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : _church == null
            ? _buildNoChurch()
            : RefreshIndicator(onRefresh: _load, color: _kPrimary, child: _buildContent());
  }

  Widget _buildNoChurch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.church_rounded, size: 56, color: _kPrimary),
            const SizedBox(height: 16),
            const Text('Bado hujajiunga na kanisa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('You have not joined a church yet',
                style: TextStyle(fontSize: 13, color: _kSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tafuta Kanisa / Find Church',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = _church!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Church header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.church_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(c.denomination,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              if (c.pastorName != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 6),
                    Text('Mchungaji / Pastor: ${c.pastorName}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 6),
                  Text('Wanachama / Members: ${c.memberCount}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
              if (c.serviceTimes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(c.serviceTimes.join(' | '),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Row(
          children: [
            _QuickAction(icon: Icons.event_rounded, label: 'Matukio\nEvents',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChurchEventsPage(churchId: c.id)))),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.people_rounded, label: 'Wanachama\nMembers',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChurchMembersPage(churchId: c.id)))),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.volunteer_activism_rounded, label: 'Toa\nGive',
                onTap: () => Navigator.pushNamed(context, '/home')),
          ],
        ),
        const SizedBox(height: 20),

        // Announcements
        const Text('Matangazo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 4),
        const Text('Announcements',
            style: TextStyle(fontSize: 12, color: _kSecondary)),
        const SizedBox(height: 10),
        if (_announcements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('Hakuna matangazo mapya\nNo new announcements',
                style: TextStyle(color: _kSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          )
        else
          ..._announcements.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnnouncementCard(announcement: a),
              )),
        const SizedBox(height: 16),

        // Upcoming events
        if (_upcomingEvents.isNotEmpty) ...[
          const Text('Matukio Yajayo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Upcoming Events',
              style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          ..._upcomingEvents.take(3).map((e) => _EventRow(event: e)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: _kPrimary),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final ChurchEvent event;
  const _EventRow({required this.event});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_rounded, size: 22, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${event.date}${event.time != null ? ' ${event.time}' : ''}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ),
            ),
            Text('${event.rsvpCount}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.people_rounded, size: 14, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}

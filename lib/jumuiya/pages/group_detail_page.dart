// lib/jumuiya/pages/group_detail_page.dart
import 'package:flutter/material.dart';
import '../models/jumuiya_models.dart';
import '../services/jumuiya_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GroupDetailPage extends StatefulWidget {
  final JumuiyaGroup group;
  const GroupDetailPage({super.key, required this.group});
  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<JumuiyaMember> _members = [];
  List<JumuiyaMeeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      JumuiyaService.getMembers(widget.group.id),
      JumuiyaService.getMeetings(widget.group.id),
    ]);
    if (mounted) {
      final memR = results[0] as PaginatedResult<JumuiyaMember>;
      final mtgR = results[1] as PaginatedResult<JumuiyaMeeting>;
      setState(() {
        _isLoading = false;
        if (memR.success) _members = memR.items;
        if (mtgR.success) _meetings = mtgR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (g.churchName != null)
              Text(g.churchName!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Wanachama / Members'),
            Tab(text: 'Mikutano / Meetings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (g.description != null)
                        Text(g.description!,
                            style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                      if (g.meetingDay != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 16, color: _kSecondary),
                            const SizedBox(width: 6),
                            Text('${g.meetingDay} ${g.meetingTime ?? ''}',
                                style: const TextStyle(fontSize: 13, color: _kPrimary)),
                          ],
                        ),
                      ],
                      if (g.leaderName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 16, color: _kSecondary),
                            const SizedBox(width: 6),
                            Text('Kiongozi / Leader: ${g.leaderName}',
                                style: const TextStyle(fontSize: 13, color: _kPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [_buildMembers(), _buildMeetings()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMembers() {
    if (_members.isEmpty) {
      return const Center(child: Text('Hakuna wanachama / No members', style: TextStyle(color: _kSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = _members[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person_rounded, size: 20, color: _kSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (m.role != null)
                      Text(m.role!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                ),
              ),
              Text('${m.attendancePercent}%',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetings() {
    if (_meetings.isEmpty) {
      return const Center(child: Text('Hakuna mikutano / No meetings', style: TextStyle(color: _kSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _meetings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final mt = _meetings[i];
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
                  const Icon(Icons.event_rounded, size: 18, color: _kPrimary),
                  const SizedBox(width: 8),
                  Text(mt.date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const Spacer(),
                  Text('${mt.attendeeCount} waliohudhuria / attended',
                      style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ),
              if (mt.topic != null) ...[
                const SizedBox(height: 6),
                Text(mt.topic!, style: const TextStyle(fontSize: 13, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (mt.scriptureRef != null) ...[
                const SizedBox(height: 4),
                Text(mt.scriptureRef!,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _kSecondary)),
              ],
            ],
          ),
        );
      },
    );
  }
}

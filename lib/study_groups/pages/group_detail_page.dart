// lib/study_groups/pages/group_detail_page.dart
import 'package:flutter/material.dart';
import '../models/study_groups_models.dart';
import '../services/study_groups_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GroupDetailPage extends StatefulWidget {
  final StudyGroup group;
  final int userId;
  const GroupDetailPage({super.key, required this.group, required this.userId});
  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final StudyGroupsService _service = StudyGroupsService();
  List<StudyGroupMember> _members = [];
  List<GroupStudySession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_service.getMembers(widget.group.id), _service.getSessions(widget.group.id)]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final mRes = results[0] as StudyListResult<StudyGroupMember>;
        final sRes = results[1] as StudyListResult<GroupStudySession>;
        if (mRes.success) _members = mRes.items;
        if (sRes.success) _sessions = sRes.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: Text(widget.group.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Stats
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _stat('Wanachama', '${widget.group.memberCount}/${widget.group.maxMembers}'),
                  _stat('Streak', '${widget.group.streak} siku'),
                  _stat('Vikao', '${widget.group.totalSessions}'),
                ]),
              ),
              const SizedBox(height: 16),
              if (widget.group.description != null) ...[
                Text(widget.group.description!, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.4)),
                const SizedBox(height: 16),
              ],
              // Members
              const Text('Wanachama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              ..._members.map((m) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _kPrimary.withValues(alpha: 0.1),
                  backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                  child: m.avatarUrl == null ? Text(m.name.isNotEmpty ? m.name[0] : '?', style: const TextStyle(color: _kPrimary)) : null,
                ),
                title: Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(m.role.displayName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                trailing: Text('${m.contributionScore}pts', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: 16),
              // Sessions
              const Text('Vikao Vijavyo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
              const Text('Upcoming Sessions', style: TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 8),
              if (_sessions.where((s) => !s.isPast).isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('Hakuna vikao vijavyo / No upcoming sessions', style: TextStyle(color: _kSecondary)))
              else
                ..._sessions.where((s) => !s.isPast).map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.topic, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: _kSecondary), const SizedBox(width: 4),
                      Text('${s.scheduledAt.day}/${s.scheduledAt.month} · ${s.durationMinutes}min', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      if (s.location != null) ...[const SizedBox(width: 12), const Icon(Icons.location_on_rounded, size: 14, color: _kSecondary), const SizedBox(width: 4),
                        Expanded(child: Text(s.location!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis))],
                    ]),
                  ]),
                )),
            ]),
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
    ]);
  }
}

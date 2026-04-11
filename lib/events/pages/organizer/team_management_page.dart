// lib/events/pages/organizer/team_management_page.dart
import 'package:flutter/material.dart';
import '../../models/event_analytics.dart';
import '../../models/event_enums.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TeamManagementPage extends StatefulWidget {
  final int eventId;

  const TeamManagementPage({super.key, required this.eventId});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  final _service = EventOrganizerService();
  late EventStrings _strings;
  List<TeamMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = await _service.getTeam(eventId: widget.eventId);
    if (!mounted) return;
    setState(() { _members = members; _loading = false; });
  }

  Future<void> _removeMember(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $name from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await _service.removeTeamMember(eventId: widget.eventId, userId: userId);
    if (!mounted) return;
    if (result.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to remove member')));
    }
  }

  void _showAddMemberDialog() {
    final userIdCtrl = TextEditingController();
    TeamRole selectedRole = TeamRole.volunteer;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Team Member', style: TextStyle(color: _kPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TeamRole>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: TeamRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.subtitle))).toList(),
                onChanged: (v) => setSt(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final userId = int.tryParse(userIdCtrl.text.trim());
                if (userId == null) return;
                Navigator.pop(ctx);
                final result = await _service.addTeamMember(
                  eventId: widget.eventId,
                  userId: userId,
                  role: selectedRole,
                );
                if (!mounted) return;
                if (result.success) {
                  _load();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to add member')));
                }
              },
              child: const Text('Add', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.teamManagement, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: _showAddMemberDialog, tooltip: 'Add member'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _load,
              child: _members.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 300, child: Center(child: Text(_strings.noTeamMembersYet, style: const TextStyle(color: _kSecondary)))),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _MemberCard(
                        member: _members[i],
                        onRemove: () => _removeMember(_members[i].userId, _members[i].fullName),
                      ),
                    ),
            ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onRemove;

  const _MemberCard({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final role = TeamRole.fromApi(member.role);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEEEEEE),
            backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
            child: member.avatarUrl == null ? const Icon(Icons.person_rounded, color: _kSecondary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(20)),
                  child: Text(role.subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 20), onPressed: onRemove),
        ],
      ),
    );
  }
}

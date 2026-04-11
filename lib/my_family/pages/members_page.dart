// lib/my_family/pages/members_page.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';
import '../widgets/member_avatar.dart';
import 'add_member_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MembersPage extends StatefulWidget {
  final int userId;
  const MembersPage({super.key, required this.userId});
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final MyFamilyService _service = MyFamilyService();
  List<FamilyMember> _members = [];
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final result = await _service.getMembers(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _members = result.items;
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadMembers();
  }

  Future<void> _deleteMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ondoa Mwanafamilia'),
        content: Text(
          'Una uhakika unataka kumondoa ${member.name} kwenye familia yako?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana', style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ndio, Ondoa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _service.removeMember(member.id);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mwanafamilia ameondolewa')),
          );
          _loadMembers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result.message ?? 'Imeshindwa kuondoa')),
          );
        }
      }
    }
  }

  // Group members by relationship type for display
  Map<String, List<FamilyMember>> _groupByRelationship() {
    final groups = <String, List<FamilyMember>>{};
    for (final m in _members) {
      final key = m.relationship.displayName;
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(m);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Wanafamilia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView
                  ? Icons.list_rounded
                  : Icons.grid_view_rounded,
              color: _kPrimary,
            ),
            onPressed: () =>
                setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _nav(AddMemberPage(userId: widget.userId)),
        backgroundColor: _kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _members.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  color: _kPrimary,
                  child: _isGridView
                      ? _buildGridView()
                      : _buildListView(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom_rounded,
                size: 64, color: _kPrimary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text(
              'Bado hauna wanafamilia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ongeza wanafamilia wako ili kusimamia pamoja',
              style: TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  _nav(AddMemberPage(userId: widget.userId)),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Ongeza Mwanafamilia'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _MemberCard(
          member: member,
          onTap: () => _nav(AddMemberPage(
            userId: widget.userId,
            existingMember: member,
          )),
          onDelete: () => _deleteMember(member),
        );
      },
    );
  }

  Widget _buildListView() {
    final groups = _groupByRelationship();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kSecondary,
              ),
            ),
          ),
          ...entry.value.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemberListTile(
                  member: member,
                  onTap: () => _nav(AddMemberPage(
                    userId: widget.userId,
                    existingMember: member,
                  )),
                  onDelete: () => _deleteMember(member),
                ),
              )),
        ],
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MemberAvatar(
                member: member,
                size: 64,
                showLabel: false,
                showRelationship: false,
              ),
              const SizedBox(height: 10),
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                member.relationship.displayName,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
              if (member.age != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Miaka ${member.age}',
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (member.isLinked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded,
                              size: 10, color: Color(0xFF4CAF50)),
                          SizedBox(width: 2),
                          Text(
                            'TAJIRI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline_rounded,
                        size: 16,
                        color: _kSecondary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemberListTile({
    required this.member,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MemberAvatarSmall(member: member, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          member.relationship.displayName,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                        if (member.age != null) ...[
                          const Text(' - ',
                              style: TextStyle(
                                  fontSize: 11, color: _kSecondary)),
                          Text(
                            'Miaka ${member.age}',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (member.isLinked)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TAJIRI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded,
                    size: 18,
                    color: _kSecondary.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

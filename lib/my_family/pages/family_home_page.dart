// lib/my_family/pages/family_home_page.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';
import '../widgets/member_avatar.dart';
import '../widgets/event_card.dart';
import 'members_page.dart';
import 'add_member_page.dart';
import 'family_calendar_page.dart';
import 'shared_lists_page.dart';
import 'health_records_page.dart';
import 'emergency_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class FamilyHomePage extends StatefulWidget {
  final int userId;
  const FamilyHomePage({super.key, required this.userId});
  @override
  State<FamilyHomePage> createState() => _FamilyHomePageState();
}

class _FamilyHomePageState extends State<FamilyHomePage> {
  final MyFamilyService _service = MyFamilyService();

  List<FamilyMember> _members = [];
  List<FamilyEvent> _upcomingEvents = [];
  List<Chore> _activeChores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final results = await Future.wait([
      _service.getMembers(widget.userId),
      _service.getEvents(widget.userId, now.month, now.year),
      _service.getChores(widget.userId),
    ]);
    if (mounted) {
      final membersResult = results[0] as FamilyListResult<FamilyMember>;
      final eventsResult = results[1] as FamilyListResult<FamilyEvent>;
      final choresResult = results[2] as FamilyListResult<Chore>;
      setState(() {
        _isLoading = false;
        if (membersResult.success) _members = membersResult.items;
        if (eventsResult.success) {
          _upcomingEvents = eventsResult.items
              .where((e) => !e.isPast || e.isToday)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        }
        if (choresResult.success) {
          _activeChores =
              choresResult.items.where((c) => !c.isDone).toList();
        }
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    return RefreshIndicator(
        onRefresh: _loadData,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ─── Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.family_restroom_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'My Family',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your entire family in one place.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeaderStat(
                          value: '${_members.length}',
                          label: 'Members'),
                      const SizedBox(width: 20),
                      _HeaderStat(
                          value: '${_upcomingEvents.length}',
                          label: 'Upcoming Events'),
                      const SizedBox(width: 20),
                      _HeaderStat(
                          value: '${_activeChores.length}',
                          label: 'Active Chores'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Family Members Row ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Family Members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _nav(MembersPage(userId: widget.userId)),
                  child: const Text(
                    'All',
                    style: TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: _members.isEmpty
                  ? Center(
                      child: GestureDetector(
                        onTap: () => _nav(
                            AddMemberPage(userId: widget.userId)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_rounded,
                                  size: 20, color: _kPrimary),
                              SizedBox(width: 8),
                              Text(
                                'Add Family Member',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _members.length + 1, // +1 for add button
                      separatorBuilder: (c, i) =>
                          const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        if (index == _members.length) {
                          return GestureDetector(
                            onTap: () => _nav(
                                AddMemberPage(userId: widget.userId)),
                            child: SizedBox(
                              width: 72,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _kPrimary
                                          .withValues(alpha: 0.06),
                                      border: Border.all(
                                        color: _kPrimary
                                            .withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: _kPrimary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return MemberAvatar(
                          member: _members[index],
                          onTap: () => _nav(AddMemberPage(
                            userId: widget.userId,
                            existingMember: _members[index],
                          )),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // ─── Quick Actions ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.person_add_rounded,
                    label: 'Add\nMember',
                    onTap: () =>
                        _nav(AddMemberPage(userId: widget.userId)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: 'Family\nCalendar',
                    onTap: () => _nav(FamilyCalendarPage(
                        userId: widget.userId, members: _members)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.checklist_rounded,
                    label: 'Shared\nLists',
                    onTap: () => _nav(SharedListsPage(
                        userId: widget.userId, members: _members)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.health_and_safety_rounded,
                    label: 'Family\nHealth',
                    onTap: () => _nav(HealthRecordsPage(
                        userId: widget.userId, members: _members)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.emergency_rounded,
                    label: 'Emergency',
                    onTap: () => _nav(EmergencyPage(
                        userId: widget.userId, members: _members)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Upcoming Events ─────────────────────────────
            if (_upcomingEvents.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _nav(FamilyCalendarPage(
                        userId: widget.userId, members: _members)),
                    child: const Text(
                      'All',
                      style: TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._upcomingEvents.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EventCard(event: e),
                  )),
              const SizedBox(height: 12),
            ],

            // ─── Active Chores ───────────────────────────────
            if (_activeChores.isNotEmpty) ...[
              const Text(
                'House Chores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ..._activeChores.take(5).map((chore) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ChoreRow(
                      chore: chore,
                      onDone: () async {
                        final result =
                            await _service.markChoreDone(chore.id);
                        if (result.success && mounted) _loadData();
                      },
                    ),
                  )),
              const SizedBox(height: 12),
            ],

            // ─── Cross-Module Links ──────────────────────────
            const Text(
              'Family on Tajiri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _CrossModuleLink(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Family Budget',
              description:
                  'Plan spending and savings for your family together',
              module: 'Budget',
              onTap: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            _CrossModuleLink(
              icon: Icons.chat_rounded,
              label: 'Family Group Chat',
              description:
                  'Chat with your family in one group',
              module: 'Messages',
              onTap: () {
                Navigator.pushNamed(context, '/messages');
              },
            ),
            _CrossModuleLink(
              icon: Icons.shield_rounded,
              label: 'Family Insurance',
              description:
                  'Protect your family with health and life insurance',
              module: 'Insurance',
              onTap: () {
                Navigator.pushNamed(context, '/insurance');
              },
            ),
            _CrossModuleLink(
              icon: Icons.medical_services_rounded,
              label: 'Family Doctor',
              description:
                  'Health consultations for the whole family',
              module: 'Doctor',
              onTap: () {
                Navigator.pushNamed(context, '/doctor');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
  }
}

// ─── Private Widgets ───────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: _kPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoreRow extends StatelessWidget {
  final Chore chore;
  final VoidCallback onDone;
  const _ChoreRow({required this.chore, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: onDone,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: chore.isOverdue
                        ? Colors.red
                        : _kPrimary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: chore.isDone
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: _kPrimary)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chore.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chore.assignedMemberName != null)
                    Text(
                      chore.assignedMemberName!,
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                ],
              ),
            ),
            if (chore.points > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${chore.points} pt',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
            if (chore.isOverdue)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _CrossModuleLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String module;
  final VoidCallback onTap;
  const _CrossModuleLink({
    required this.icon,
    required this.label,
    required this.description,
    required this.module,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          )),
                      Text(
                        description,
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    module,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

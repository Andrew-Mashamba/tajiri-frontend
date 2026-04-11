// lib/events/pages/committee_page.dart
import 'package:flutter/material.dart';
import '../models/committee.dart';
import '../models/event_strings.dart';
import '../services/committee_service.dart';
import '../widgets/person_picker_sheet.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CommitteePage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const CommitteePage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<CommitteePage> createState() => _CommitteePageState();
}

class _CommitteePageState extends State<CommitteePage>
    with SingleTickerProviderStateMixin {
  final _service = CommitteeService();
  late EventStrings _strings;
  late TabController _tabs;

  List<EventCommittee> _committees = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await _service.getCommittees(eventId: widget.eventId);
    if (!mounted) return;
    setState(() { _committees = result; _loading = false; });
  }

  EventCommittee? get _main =>
      _committees.where((c) => c.isMainCommittee).firstOrNull;

  List<EventCommittee> get _subs =>
      _committees.where((c) => c.isSubCommittee).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.isSwahili ? 'Kamati' : 'Committee',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.eventName,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: _strings.isSwahili ? 'Wanachama' : 'Members'),
            Tab(text: _strings.isSwahili ? 'Mikutano' : 'Meetings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _MembersTab(
                      main: _main,
                      subs: _subs,
                      strings: _strings,
                      eventId: widget.eventId,
                      service: _service,
                      onRefresh: _load,
                    ),
                    _MeetingsTab(
                      committees: _committees,
                      strings: _strings,
                      service: _service,
                    ),
                  ],
                ),
    );
  }
}

// ── Members Tab ──────────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  final EventCommittee? main;
  final List<EventCommittee> subs;
  final EventStrings strings;
  final int eventId;
  final CommitteeService service;
  final VoidCallback onRefresh;

  const _MembersTab({
    required this.main, required this.subs, required this.strings,
    required this.eventId, required this.service, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (main == null && subs.isEmpty) {
      return Center(
        child: Text(
          strings.isSwahili ? 'Hakuna kamati bado' : 'No committee yet',
          style: const TextStyle(color: _kSecondary),
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (main != null) ...[
            _CommitteeCard(
              committee: main!,
              strings: strings,
              service: service,
              onRefresh: onRefresh,
            ),
            const SizedBox(height: 20),
          ],
          if (subs.isNotEmpty) ...[
            _SectionLabel(strings.isSwahili ? 'Kamati Ndogo' : 'Sub-committees'),
            const SizedBox(height: 12),
            ...subs.map((s) => _SubCommitteeTile(
              committee: s,
              strings: strings,
              service: service,
              onRefresh: onRefresh,
            )),
          ],
        ],
      ),
    );
  }
}

class _CommitteeCard extends StatelessWidget {
  final EventCommittee committee;
  final EventStrings strings;
  final CommitteeService service;
  final VoidCallback onRefresh;

  const _CommitteeCard({
    required this.committee, required this.strings,
    required this.service, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(committee.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
                _AddMemberButton(
                  committeeId: committee.id,
                  service: service,
                  onAdded: onRefresh,
                  strings: strings,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ...committee.members.map((m) => _MemberTile(member: m)),
          if (committee.members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.isSwahili ? 'Hakuna wanachama bado' : 'No members yet',
                style: const TextStyle(color: _kSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CommitteeMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8E8E8),
            backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
            child: member.avatarUrl == null
                ? Text(member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))
                : null,
          ),
          if (member.isOnline)
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 9, height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(member.fullName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(member.role.displayName,
          style: const TextStyle(fontSize: 11, color: _kSecondary)),
    );
  }
}

class _SubCommitteeTile extends StatelessWidget {
  final EventCommittee committee;
  final EventStrings strings;
  final CommitteeService service;
  final VoidCallback onRefresh;

  const _SubCommitteeTile({
    required this.committee, required this.strings,
    required this.service, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMemberSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.group_rounded, size: 20, color: _kSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(committee.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text('${committee.members.length} ${strings.isSwahili ? "wanachama" : "members"}',
                      style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  void _showMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SubCommitteeMemberSheet(
        committee: committee, strings: strings,
        service: service, onRefresh: onRefresh,
      ),
    );
  }
}

class _SubCommitteeMemberSheet extends StatelessWidget {
  final EventCommittee committee;
  final EventStrings strings;
  final CommitteeService service;
  final VoidCallback onRefresh;

  const _SubCommitteeMemberSheet({
    required this.committee, required this.strings,
    required this.service, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(committee.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
                _AddMemberButton(
                  committeeId: committee.id,
                  service: service,
                  onAdded: onRefresh,
                  strings: strings,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (committee.members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  strings.isSwahili ? 'Hakuna wanachama bado' : 'No members yet',
                  style: const TextStyle(color: _kSecondary),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: committee.members.length,
                itemBuilder: (_, i) => _MemberTile(member: committee.members[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddMemberButton extends StatefulWidget {
  final int committeeId;
  final CommitteeService service;
  final VoidCallback onAdded;
  final EventStrings strings;

  const _AddMemberButton({
    required this.committeeId, required this.service,
    required this.onAdded, required this.strings,
  });

  @override
  State<_AddMemberButton> createState() => _AddMemberButtonState();
}

class _AddMemberButtonState extends State<_AddMemberButton> {
  PickedPerson? _pickedPerson;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: _kPrimary),
      tooltip: widget.strings.isSwahili ? 'Ongeza Mwanachama' : 'Add Member',
      onPressed: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    CommitteeRole role = CommitteeRole.mjumbe;
    // Reset picker state for each new dialog
    setState(() => _pickedPerson = null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _kBg,
          title: Text(
            widget.strings.isSwahili ? 'Ongeza Mwanachama' : 'Add Member',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Person picker button
              GestureDetector(
                onTap: () async {
                  final picked = await showPersonPickerSheet(
                    ctx,
                    title: widget.strings.isSwahili ? 'Chagua Mwanachama' : 'Select Member',
                    allowExternal: false,
                  );
                  if (picked != null) {
                    setSt(() => _pickedPerson = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      if (_pickedPerson != null) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8E8E8),
                          backgroundImage: _pickedPerson!.avatarUrl != null
                              ? NetworkImage(_pickedPerson!.avatarUrl!)
                              : null,
                          child: _pickedPerson!.avatarUrl == null
                              ? Text(
                                  _pickedPerson!.name.isNotEmpty
                                      ? _pickedPerson!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12, color: _kPrimary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pickedPerson!.name,
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.person_search_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.strings.isSwahili ? 'Chagua mwanachama...' : 'Pick a member...',
                            style: const TextStyle(fontSize: 13, color: _kSecondary),
                          ),
                        ),
                      ],
                      const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CommitteeRole>(
                initialValue: role,
                decoration: InputDecoration(
                  labelText: widget.strings.isSwahili ? 'Jukumu' : 'Role',
                  border: const OutlineInputBorder(),
                ),
                items: CommitteeRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                    .toList(),
                onChanged: (v) => setSt(() => role = v ?? CommitteeRole.mjumbe),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(widget.strings.back, style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: _pickedPerson?.userId == null
                  ? null
                  : () async {
                      final uid = _pickedPerson!.userId!;
                      Navigator.pop(ctx);
                      await widget.service.addMember(
                        committeeId: widget.committeeId,
                        userId: uid,
                        role: role,
                      );
                      widget.onAdded();
                    },
              child: Text(widget.strings.isSwahili ? 'Ongeza' : 'Add',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meetings Tab ─────────────────────────────────────────────────────────────

class _MeetingsTab extends StatefulWidget {
  final List<EventCommittee> committees;
  final EventStrings strings;
  final CommitteeService service;

  const _MeetingsTab({required this.committees, required this.strings, required this.service});

  @override
  State<_MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<_MeetingsTab> {
  Map<int, List<Meeting>> _meetingsByCommittee = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _loading = true);
    final map = <int, List<Meeting>>{};
    for (final c in widget.committees) {
      map[c.id] = await widget.service.getMeetings(committeeId: c.id);
    }
    if (!mounted) return;
    setState(() { _meetingsByCommittee = map; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    final allMeetings = _meetingsByCommittee.values.expand((l) => l).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadMeetings,
      child: allMeetings.isEmpty
          ? Center(
              child: Text(
                widget.strings.isSwahili ? 'Hakuna mikutano bado' : 'No meetings yet',
                style: const TextStyle(color: _kSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allMeetings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _MeetingTile(meeting: allMeetings[i], strings: widget.strings),
            ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final Meeting meeting;
  final EventStrings strings;

  const _MeetingTile({required this.meeting, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meeting.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: _kSecondary),
              const SizedBox(width: 4),
              Text(strings.formatDateShort(meeting.date),
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
              if (meeting.location != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_rounded, size: 12, color: _kSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(meeting.location!,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          if (meeting.agenda != null) ...[
            const SizedBox(height: 6),
            Text(meeting.agenda!,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kSecondary, letterSpacing: 0.5));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: _kSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Jaribu tena' : 'Try again')),
        ],
      ),
    );
  }
}

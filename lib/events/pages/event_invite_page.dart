// lib/events/pages/event_invite_page.dart
import 'package:flutter/material.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../widgets/person_picker_sheet.dart';
import '../../services/people_search_service.dart';
import '../../models/people_search_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventInvitePage extends StatefulWidget {
  final int eventId;
  final int userId;

  const EventInvitePage({super.key, required this.eventId, required this.userId});

  @override
  State<EventInvitePage> createState() => _EventInvitePageState();
}

class _EventInvitePageState extends State<EventInvitePage> {
  final _eventService = EventService();
  final _searchService = PeopleSearchService();
  final _searchCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  List<PersonSearchResult> _results = [];
  final Set<int> _selected = {};
  bool _searching = false;
  bool _sending = false;
  bool _sendingPhone = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
    _searchUsers('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _query) return;
    _query = q;
    _searchUsers(q);
  }

  Future<void> _searchUsers(String q) async {
    setState(() => _searching = true);
    final result = await _searchService.search(
      userId: widget.userId,
      query: q.isNotEmpty ? q : null,
      perPage: 30,
    );
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result.success) {
        _results = result.response?.people ?? [];
      }
    });
  }

  void _toggleSelect(int userId) {
    setState(() {
      if (_selected.contains(userId)) {
        _selected.remove(userId);
      } else {
        _selected.add(userId);
      }
    });
  }

  Future<void> _sendInvites() async {
    if (_selected.isEmpty) return;
    setState(() => _sending = true);
    final result = await _eventService.inviteFriends(
      eventId: widget.eventId,
      userIds: _selected.toList(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      setState(() => _selected.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Mialiko imetumwa!' : 'Invitations sent!'),
          backgroundColor: _kPrimary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (Localizations.localeOf(context).languageCode == 'sw' ? 'Imeshindwa kutuma mialiko' : 'Failed to send invitations')),
          backgroundColor: _kPrimary,
        ),
      );
    }
  }

  Future<void> _sendSms() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() => _sendingPhone = true);
    final result = await _eventService.inviteByPhone(
      eventId: widget.eventId,
      phoneNumbers: [phone],
    );
    if (!mounted) return;
    setState(() => _sendingPhone = false);
    if (result.success) {
      _phoneCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'SMS imetumwa!' : 'SMS sent!'),
          backgroundColor: _kPrimary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (Localizations.localeOf(context).languageCode == 'sw' ? 'Imeshindwa kutuma SMS' : 'Failed to send SMS')),
          backgroundColor: _kPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');
    final hasSelection = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 14, color: _kPrimary),
            decoration: InputDecoration(
              hintText: strings.search,
              hintStyle: const TextStyle(color: _kSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: _kSecondary),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ),

        // User list
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : _results.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_search_rounded, size: 48, color: _kSecondary),
                        const SizedBox(height: 10),
                        Text(strings.noResults,
                            style: const TextStyle(color: _kSecondary, fontSize: 14)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final person = _results[i];
                        final isSelected = _selected.contains(person.id);
                        return _UserRow(
                          person: person,
                          selected: isSelected,
                          onToggle: () => _toggleSelect(person.id),
                        );
                      },
                    ),
        ),

        // Phone invite section
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.isSwahili ? 'Alika kwa SMS' : 'Invite via SMS',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                ),
                // Pick a non-TAJIRI person to pre-fill the phone field
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showPersonPickerSheet(
                      context,
                      title: strings.isSwahili ? 'Chagua Mtu' : 'Select Person',
                      allowExternal: true,
                    );
                    if (picked != null && picked.phone != null && picked.phone!.isNotEmpty) {
                      _phoneCtrl.text = picked.phone!;
                    }
                  },
                  icon: const Icon(Icons.person_search_rounded, size: 16),
                  label: Text(strings.isSwahili ? 'Chagua' : 'Pick',
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: _kSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                  decoration: InputDecoration(
                    hintText: strings.isSwahili ? 'Nambari ya simu...' : 'Phone number...',
                    hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: _kSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _sendingPhone ? null : _sendSms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _sendingPhone
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(strings.isSwahili ? 'Tuma' : 'Send',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),

        // Send invites button
        if (hasSelection)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendInvites,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          '${strings.invite} (${_selected.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _UserRow extends StatelessWidget {
  final PersonSearchResult person;
  final bool selected;
  final VoidCallback onToggle;

  const _UserRow({required this.person, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = person.profilePhotoPath;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    person.firstName.isNotEmpty ? person.firstName[0] : '?',
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              person.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
            ),
            if (person.username != null)
              Text('@${person.username}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
            if (person.mutualFriendsCount > 0)
              Text(
                Localizations.localeOf(context).languageCode == 'sw'
                    ? '${person.mutualFriendsCount} marafiki wa pamoja'
                    : '${person.mutualFriendsCount} mutual friends',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
          ])),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? _kPrimary : Colors.transparent,
              border: Border.all(color: selected ? _kPrimary : const Color(0xFFCCCCCC), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ]),
      ),
    );
  }
}

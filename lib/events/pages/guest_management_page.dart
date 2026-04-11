// lib/events/pages/guest_management_page.dart
import 'package:flutter/material.dart';
import '../models/guest.dart';
import '../models/event_strings.dart';
import '../services/guest_service.dart';
import '../widgets/person_picker_sheet.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GuestManagementPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const GuestManagementPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<GuestManagementPage> createState() => _GuestManagementPageState();
}

class _GuestManagementPageState extends State<GuestManagementPage>
    with SingleTickerProviderStateMixin {
  final _service = GuestService();
  late EventStrings _strings;
  late TabController _tabs;

  GuestSummary? _summary;
  Map<String, List<EventGuest>> _guestsByTab = {};
  bool _loading = true;
  String? _error;

  static const _tabKeys = ['all', 'vip', 'family', 'regular'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
    final summaryResult = await _service.getSummary(eventId: widget.eventId);
    final allResult = await _service.getGuests(eventId: widget.eventId);
    if (!mounted) return;

    if (!allResult.success) {
      setState(() { _error = allResult.message; _loading = false; });
      return;
    }

    final allGuests = allResult.items;
    setState(() {
      _summary = summaryResult.success ? summaryResult.data : null;
      _guestsByTab = {
        'all': allGuests,
        'vip': allGuests.where((g) => g.category == GuestCategory.vip).toList(),
        'family': allGuests.where((g) => g.category == GuestCategory.family).toList(),
        'regular': allGuests.where((g) => g.category == GuestCategory.regular).toList(),
      };
      _loading = false;
    });
  }

  String _tabLabel(String key) {
    switch (key) {
      case 'all': return _strings.all;
      case 'vip': return 'VIP';
      case 'family': return _strings.isSwahili ? 'Ndugu' : 'Family';
      case 'regular': return _strings.isSwahili ? 'Kawaida' : 'Regular';
      default: return key;
    }
  }

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
            Text(_strings.isSwahili ? 'Usimamizi wa Wageni' : 'Guest Management',
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabKeys.map((k) {
            final count = _guestsByTab[k]?.length ?? 0;
            return Tab(text: '${_tabLabel(k)}${count > 0 && !_loading ? " ($count)" : ""}');
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(_strings.isSwahili ? 'Ongeza Mgeni' : 'Add Guest'),
        onPressed: _showAddGuestDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    if (_summary != null) _SummaryBar(summary: _summary!, strings: _strings),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: _tabKeys.map((k) => _GuestTab(
                          guests: _guestsByTab[k] ?? [],
                          strings: _strings,
                          service: _service,
                          onRefresh: _load,
                        )).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showAddGuestDialog() {
    PickedPerson? pickedPerson;
    GuestCategory category = GuestCategory.regular;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _kBg,
          title: Text(
            _strings.isSwahili ? 'Ongeza Mgeni' : 'Add Guest',
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
                    title: _strings.isSwahili ? 'Chagua Mgeni' : 'Select Guest',
                    allowExternal: true,
                  );
                  if (picked != null) {
                    setSt(() => pickedPerson = picked);
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
                      if (pickedPerson != null) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8E8E8),
                          backgroundImage: pickedPerson!.avatarUrl != null
                              ? NetworkImage(pickedPerson!.avatarUrl!)
                              : null,
                          child: pickedPerson!.avatarUrl == null
                              ? Text(
                                  pickedPerson!.name.isNotEmpty
                                      ? pickedPerson!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12, color: _kPrimary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickedPerson!.name,
                                style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (pickedPerson!.phone != null)
                                Text(
                                  pickedPerson!.phone!,
                                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                                ),
                              if (!pickedPerson!.isTajiriUser)
                                Text(
                                  _strings.isSwahili ? 'Mgeni wa nje' : 'External guest',
                                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                                ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.person_search_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _strings.isSwahili
                                ? 'Chagua mgeni (TAJIRI au wa nje)...'
                                : 'Pick guest (TAJIRI or external)...',
                            style: const TextStyle(fontSize: 13, color: _kSecondary),
                          ),
                        ),
                      ],
                      const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<GuestCategory>(
                initialValue: category,
                decoration: InputDecoration(
                  labelText: _strings.isSwahili ? 'Kundi la Mgeni' : 'Guest Category',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: GuestCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.displayName, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => category = v ?? GuestCategory.regular),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_strings.back, style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: pickedPerson == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _service.addGuest(
                        eventId: widget.eventId,
                        name: pickedPerson!.name,
                        phone: pickedPerson!.phone,
                        userId: pickedPerson!.userId,
                        category: category,
                      );
                      _load();
                    },
              child: Text(_strings.isSwahili ? 'Ongeza' : 'Add',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final GuestSummary summary;
  final EventStrings strings;
  const _SummaryBar({required this.summary, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BarStat(
            label: strings.isSwahili ? 'Waalika' : 'Invited',
            value: '${summary.totalInvited}',
            icon: Icons.people_rounded,
          ),
          _BarStat(
            label: strings.isSwahili ? 'Watakaokuja' : 'Going',
            value: '${summary.totalGoing}',
            icon: Icons.check_circle_outline_rounded,
          ),
          _BarStat(
            label: strings.isSwahili ? 'Kadi Zilizofika' : 'Cards Delivered',
            value: '${summary.cardsDelivered}',
            icon: Icons.mail_outline_rounded,
          ),
          _BarStat(
            label: strings.isSwahili ? 'Kadi Zinazobaki' : 'Cards Pending',
            value: '${summary.cardsPending}',
            icon: Icons.hourglass_empty_rounded,
          ),
        ],
      ),
    );
  }
}

class _BarStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _BarStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _kSecondary),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 9, color: _kSecondary)),
      ],
    );
  }
}

// ── Guest Tab ─────────────────────────────────────────────────────────────────

class _GuestTab extends StatelessWidget {
  final List<EventGuest> guests;
  final EventStrings strings;
  final GuestService service;
  final VoidCallback onRefresh;

  const _GuestTab({
    required this.guests, required this.strings,
    required this.service, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => onRefresh(),
      child: guests.isEmpty
          ? Center(
              child: Text(
                strings.isSwahili ? 'Hakuna wageni bado' : 'No guests yet',
                style: const TextStyle(color: _kSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: guests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _GuestTile(
                guest: guests[i],
                strings: strings,
                service: service,
                onRefresh: onRefresh,
              ),
            ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  final EventGuest guest;
  final EventStrings strings;
  final GuestService service;
  final VoidCallback onRefresh;

  const _GuestTile({
    required this.guest, required this.strings,
    required this.service, required this.onRefresh,
  });

  Color get _rsvpColor {
    switch (guest.rsvpStatus) {
      case 'going': return const Color(0xFF4CAF50);
      case 'not_going': return const Color(0xFFF44336);
      case 'interested': return const Color(0xFFFF9800);
      default: return _kSecondary;
    }
  }

  String get _rsvpLabel {
    switch (guest.rsvpStatus) {
      case 'going': return strings.going;
      case 'not_going': return strings.notGoing;
      case 'interested': return strings.interested;
      default: return strings.isSwahili ? 'Hajajibu' : 'No Response';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE8E8E8),
          backgroundImage: guest.avatarUrl != null ? NetworkImage(guest.avatarUrl!) : null,
          child: guest.avatarUrl == null
              ? Text(guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(guest.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            _CategoryBadge(category: guest.category),
          ],
        ),
        subtitle: Row(
          children: [
            _StatusDot(color: _rsvpColor),
            const SizedBox(width: 4),
            Text(_rsvpLabel,
                style: TextStyle(fontSize: 11, color: _rsvpColor)),
            const SizedBox(width: 10),
            const Icon(Icons.mail_outline_rounded, size: 12, color: _kSecondary),
            const SizedBox(width: 2),
            Text(guest.cardStatus.displayName,
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
        trailing: _GuestActions(
          guest: guest,
          strings: strings,
          service: service,
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final GuestCategory category;
  const _CategoryBadge({required this.category});

  Color get _color {
    switch (category) {
      case GuestCategory.vip: return const Color(0xFFFFB300);
      case GuestCategory.family: return const Color(0xFF7B61FF);
      default: return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (category == GuestCategory.regular) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.subtitle,
        style: TextStyle(fontSize: 9, color: _color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _GuestActions extends StatelessWidget {
  final EventGuest guest;
  final EventStrings strings;
  final GuestService service;
  final VoidCallback onRefresh;

  const _GuestActions({
    required this.guest, required this.strings,
    required this.service, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: _kSecondary),
      color: _kBg,
      onSelected: (v) => _handleAction(context, v),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'card',
          child: Text(
            strings.isSwahili ? 'Badilisha Hali ya Kadi' : 'Update Card Status',
            style: const TextStyle(fontSize: 13, color: _kPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'seat',
          child: Text(
            strings.isSwahili ? 'Weka Kiti' : 'Assign Seat',
            style: const TextStyle(fontSize: 13, color: _kPrimary),
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'card') _showCardStatusDialog(context);
    if (action == 'seat') _showSeatDialog(context);
  }

  void _showCardStatusDialog(BuildContext context) {
    InvitationStatus status = guest.cardStatus;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _kBg,
          title: Text(
            strings.isSwahili ? 'Hali ya Kadi' : 'Card Status',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: DropdownButtonFormField<InvitationStatus>(
            initialValue: status,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: InvitationStatus.values
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setSt(() => status = v ?? guest.cardStatus),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings.back, style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: () async {
                Navigator.pop(ctx);
                await service.updateCardStatus(guestId: guest.id, status: status);
                onRefresh();
              },
              child: Text(strings.isSwahili ? 'Hifadhi' : 'Save',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeatDialog(BuildContext context) {
    final seatCtrl = TextEditingController(text: guest.seatAssignment ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kBg,
        title: Text(
          strings.isSwahili ? 'Weka Kiti' : 'Assign Seat',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        content: _Field(
          controller: seatCtrl,
          label: strings.isSwahili ? 'Nambari ya Kiti / Meza' : 'Seat / Table Number',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.back, style: const TextStyle(color: _kSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () async {
              final seat = seatCtrl.text.trim();
              if (seat.isEmpty) return;
              Navigator.pop(ctx);
              await service.assignSeat(guestId: guest.id, seatAssignment: seat);
              onRefresh();
            },
            child: Text(strings.isSwahili ? 'Hifadhi' : 'Save',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _Field({required this.controller, required this.label, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
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

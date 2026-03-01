// Phase 4: Scheduled calls — list, create, start. GET/POST/DELETE /api/scheduled-calls, POST .../start.

import 'package:flutter/material.dart';
import '../../services/call_signaling_service.dart';
import '../../services/friend_service.dart';
import '../../widgets/user_avatar.dart';
import 'outgoing_call_flow_screen.dart';

class ScheduledCallsScreen extends StatefulWidget {
  final int currentUserId;
  final String? authToken;

  const ScheduledCallsScreen({
    super.key,
    required this.currentUserId,
    this.authToken,
  });

  @override
  State<ScheduledCallsScreen> createState() => _ScheduledCallsScreenState();
}

class _ScheduledCallsScreenState extends State<ScheduledCallsScreen> {
  final CallSignalingService _signaling = CallSignalingService();
  final FriendService _friendService = FriendService();
  List<ScheduledCallItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final resp = await _signaling.getScheduledCalls(
      scope: 'upcoming',
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (resp.success) {
        _items = resp.data;
      } else {
        _error = resp.message;
      }
    });
  }

  Future<void> _startCall(ScheduledCallItem item) async {
    final resp = await _signaling.startScheduledCall(
      item.id,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    if (!mounted) return;
    if (!resp.success || resp.callId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Failed to start call')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.currentUserId,
          authToken: widget.authToken,
          calleeId: 0,
          calleeName: item.title ?? 'Scheduled call',
          type: item.type,
          existingCallId: resp.callId,
          existingIceServers: resp.iceServers,
        ),
      ),
    );
  }

  Future<void> _showScheduleSheet() async {
    DateTime? scheduledAt = DateTime.now().add(const Duration(hours: 1));
    String type = 'voice';
    List<int> selectedIds = [];
    String title = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Schedule call', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        scheduledAt != null
                            ? scheduledAt!.toLocal().toString().substring(0, 16)
                            : 'Pick date & time',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: scheduledAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (!ctx.mounted) return;
                        if (date != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(scheduledAt ?? DateTime.now()),
                          );
                          if (!ctx.mounted) return;
                          if (time != null) {
                            setModalState(() {
                              scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'voice', label: Text('Voice'), icon: Icon(Icons.call)),
                        ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.videocam)),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) => setModalState(() => type = s.first),
                    ),
                    const SizedBox(height: 16),
                    const Text('Invite', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    FutureBuilder<FriendListResult>(
                      future: _friendService.getFriends(userId: widget.currentUserId, perPage: 50),
                      builder: (ctx, snap) {
                        if (!snap.hasData || !snap.data!.success) {
                          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                        }
                        final friends = snap.data!.friends;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: friends.length,
                            itemBuilder: (ctx, i) {
                              final u = friends[i];
                              final selected = selectedIds.contains(u.id);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: (v) {
                                  setModalState(() {
                                    if (v == true) {
                                      selectedIds.add(u.id);
                                    } else {
                                      selectedIds.remove(u.id);
                                    }
                                  });
                                },
                                title: Text(u.fullName),
                                secondary: UserAvatar(photoUrl: u.profilePhotoUrl, name: u.fullName, radius: 20),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (scheduledAt == null || selectedIds.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Pick time and at least one invitee')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        final resp = await _signaling.createScheduledCall(
                          scheduledAt: scheduledAt!,
                          type: type,
                          inviteeIds: selectedIds,
                          title: title.isEmpty ? null : title,
                          authToken: widget.authToken,
                          userId: widget.currentUserId,
                        );
                        if (!mounted) return;
                        if (resp.success) {
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheduled')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resp.message ?? 'Failed')),
                          );
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled calls'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('No upcoming scheduled calls'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final item = _items[i];
                          final canStart = item.startedCallId == null &&
                              item.scheduledAt != null &&
                              item.scheduledAt!.isBefore(DateTime.now().add(const Duration(minutes: 5)));
                          return Card(
                            child: ListTile(
                              title: Text(item.title ?? '${item.type} call'),
                              subtitle: Text(
                                item.scheduledAt != null
                                    ? item.scheduledAt!.toLocal().toString().substring(0, 16)
                                    : '',
                              ),
                              trailing: item.isCreator && canStart
                                  ? ElevatedButton(
                                      onPressed: () => _startCall(item),
                                      child: const Text('Start'),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

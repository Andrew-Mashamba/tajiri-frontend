// Story 87: Call History. Navigation: Home → Profile → ⋮ menu → Simu.
// Design: DOCS/DESIGN.md — #FAFAFA background, #1A1A1A primary, 48dp min touch targets.
// Uses CallSignalingService.getCallLog (GET /api/calls) when authToken is provided; else CallService.getCallHistory.

import 'package:flutter/material.dart';
import '../../models/call_models.dart';
import '../../services/call_service.dart';
import '../../services/call_signaling_service.dart';
import '../../widgets/user_avatar.dart';
import '../calls/call_history_screen.dart' show OutgoingCallScreen;
import '../calls/outgoing_call_flow_screen.dart';
import '../calls/missed_call_voice_screen.dart';
import '../calls/scheduled_calls_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  final int currentUserId;
  final String? authToken;

  const CallHistoryScreen({super.key, required this.currentUserId, this.authToken});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  final CallSignalingService _signalingService = CallSignalingService();
  late TabController _tabController;

  List<CallLog> _allCalls = [];
  List<CallLog> _missedCalls = [];
  bool _isLoading = true;
  String? _error;

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _iconBg = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCallHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCallHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (widget.authToken != null && widget.authToken!.isNotEmpty) {
      final resp = await _signalingService.getCallLog(
        page: 1,
        perPage: 50,
        authToken: widget.authToken,
        userId: widget.currentUserId,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (resp.success) {
          _allCalls = resp.data.map((e) => _callLogFromEntry(e, widget.currentUserId)).toList();
          _missedCalls = _allCalls.where((c) => c.wasMissed).toList();
        } else {
          _error = resp.message;
        }
      });
      return;
    }

    final allResult = await _callService.getCallHistory(
      userId: widget.currentUserId,
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (allResult.success) {
        _allCalls = allResult.logs;
        _missedCalls = allResult.logs.where((c) => c.wasMissed).toList();
      } else {
        _error = allResult.message;
      }
    });
  }

  static CallLog _callLogFromEntry(CallLogEntry e, int currentUserId) {
    final other = e.otherParty;
    int? otherId;
    CallUser? otherUser;
    if (other != null) {
      otherId = other['id'] is int ? other['id'] as int : (other['id'] is num ? (other['id'] as num).toInt() : null);
      otherUser = CallUser(
        id: otherId ?? 0,
        firstName: other['first_name']?.toString() ?? '',
        lastName: other['last_name']?.toString() ?? '',
        username: other['username']?.toString(),
        profilePhotoPath: other['profile_photo_path']?.toString(),
      );
    }
    final callTime = e.createdAt ?? e.endedAt ?? e.startedAt ?? DateTime.now();
    return CallLog(
      id: e.callId.hashCode,
      userId: currentUserId,
      otherUserId: otherId,
      type: e.type,
      direction: e.direction,
      status: e.status == 'connected' ? 'answered' : (e.status == 'ended' ? 'answered' : e.status),
      duration: e.durationSeconds,
      callTime: callTime,
      callId: e.callId,
      otherUser: otherUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        elevation: 0,
        title: const Text(
          'Simu',
          style: TextStyle(color: _primaryText, fontSize: 18),
        ),
        actions: [
          if (widget.authToken != null && widget.authToken!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduledCallsScreen(
                      currentUserId: widget.currentUserId,
                      authToken: widget.authToken,
                    ),
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryText,
          unselectedLabelColor: _secondaryText,
          indicatorColor: _iconBg,
          tabs: const [
            Tab(text: 'Zote'),
            Tab(text: 'Zilizokosa'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCallList(_allCalls),
                      _buildCallList(_missedCalls),
                    ],
                  ),
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          heroTag: 'calls_fab',
          onPressed: _showDialer,
          backgroundColor: _iconBg,
          child: const Icon(Icons.call, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: _accent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _loadCallHistory,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallList(List<CallLog> calls) {
    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call, size: 64, color: _accent),
            const SizedBox(height: 16),
            Text(
              'Hakuna simu',
              style: TextStyle(color: _secondaryText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: calls.length,
        itemBuilder: (context, index) {
          final call = calls[index];
          return _CallLogTile(
            callLog: call,
            currentUserId: widget.currentUserId,
            onTap: () => _showCallOptions(call),
            onCall: () => _makeCall(call),
          );
        },
      ),
    );
  }

  void _showCallOptions(CallLog call) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: UserAvatar(
                photoUrl: call.otherUser?.avatarUrl,
                name: call.otherUser?.displayName,
                radius: 24,
              ),
              title: Text(
                call.otherUser?.displayName ?? 'Mtumiaji',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: _primaryText),
              ),
              subtitle: Text(
                _formatCallTime(call.callTime),
                style: const TextStyle(color: _secondaryText, fontSize: 12),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 24),
              ),
              title: const Text('Piga simu ya sauti'),
              onTap: () {
                Navigator.pop(context);
                if (call.otherUserId != null) {
                  _initiateCall(
                    call.otherUserId!,
                    'voice',
                    calleeName: call.otherUser?.displayName,
                    calleeAvatarUrl: call.otherUser?.avatarUrl,
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, color: Colors.white, size: 24),
              ),
              title: const Text('Piga simu ya video'),
              onTap: () {
                Navigator.pop(context);
                if (call.otherUserId != null) {
                  _initiateCall(
                    call.otherUserId!,
                    'video',
                    calleeName: call.otherUser?.displayName,
                    calleeAvatarUrl: call.otherUser?.avatarUrl,
                  );
                }
              },
            ),
            if (call.wasMissed && call.callId != null && call.callId!.isNotEmpty) ...[
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 24),
                ),
                title: const Text('Leave voice message'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MissedCallVoiceScreen(
                        callId: call.callId!,
                        currentUserId: widget.currentUserId,
                        authToken: widget.authToken,
                        otherUserName: call.otherUser?.displayName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _makeCall(CallLog call) {
    if (call.otherUserId != null) {
      _initiateCall(
        call.otherUserId!,
        call.type,
        calleeName: call.otherUser?.displayName,
        calleeAvatarUrl: call.otherUser?.avatarUrl,
      );
    }
  }

  Future<void> _initiateCall(int calleeId, String type, {String? calleeName, String? calleeAvatarUrl}) async {
    if (widget.authToken != null && widget.authToken!.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutgoingCallFlowScreen(
              currentUserId: widget.currentUserId,
              authToken: widget.authToken,
              calleeId: calleeId,
              calleeName: calleeName ?? 'User',
              calleeAvatarUrl: calleeAvatarUrl,
              type: type,
            ),
          ),
        );
      }
      return;
    }

    final result = await _callService.initiateCall(
      userId: widget.currentUserId,
      calleeId: calleeId,
      type: type,
    );

    if (result.success && result.call != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutgoingCallScreen(
              currentUserId: widget.currentUserId,
              call: result.call!,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Imeshindwa kupiga simu'),
          ),
        );
      }
    }
  }

  void _showDialer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => _DialerSheet(
        onCall: (userId, type) {
          Navigator.pop(context);
          _initiateCall(userId, type);
        },
      ),
    );
  }

  String _formatCallTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return 'Leo ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Jana ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final days = ['Jpi', 'Jtt', 'Jnn', 'Alh', 'Ijm', 'Jmt', 'Jps'];
      return '${days[time.weekday % 7]} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _CallLogTile extends StatelessWidget {
  final CallLog callLog;
  final int currentUserId;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const _CallLogTile({
    required this.callLog,
    required this.currentUserId,
    required this.onTap,
    required this.onCall,
  });

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final missedColor = callLog.wasMissed ? const Color(0xFFB00020) : _secondaryText;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 56,
      leading: UserAvatar(
        photoUrl: callLog.otherUser?.avatarUrl,
        name: callLog.otherUser?.displayName,
        radius: 24,
      ),
      title: Text(
        callLog.otherUser?.displayName ?? 'Mtumiaji',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          color: callLog.wasMissed ? const Color(0xFFB00020) : _primaryText,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            callLog.isIncoming ? Icons.call_received : Icons.call_made,
            size: 14,
            color: missedColor,
          ),
          const SizedBox(width: 4),
          Icon(
            callLog.type == 'video' ? Icons.videocam : Icons.call,
            size: 14,
            color: _secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(callLog.callTime),
            style: const TextStyle(color: _secondaryText, fontSize: 13),
          ),
          if (callLog.wasAnswered && callLog.duration != null) ...[
            const SizedBox(width: 8),
            Text(
              callLog.durationFormatted,
              style: const TextStyle(color: _secondaryText, fontSize: 13),
            ),
          ],
        ],
      ),
      trailing: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCall,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              callLog.type == 'video' ? Icons.videocam : Icons.call,
              color: _iconBg,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}

class _DialerSheet extends StatefulWidget {
  final void Function(int userId, String type) onCall;

  const _DialerSheet({required this.onCall});

  @override
  State<_DialerSheet> createState() => _DialerSheetState();
}

class _DialerSheetState extends State<_DialerSheet> {
  final _controller = TextEditingController();

  static const Color _primaryText = Color(0xFF1A1A1A);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID ya Mtumiaji',
                border: OutlineInputBorder(),
                hintText: 'Ingiza ID ya mtumiaji',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: _primaryText),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DialerActionButton(
                  icon: Icons.call,
                  label: 'Sauti',
                  onPressed: () {
                    final userId = int.tryParse(_controller.text);
                    if (userId != null) {
                      widget.onCall(userId, 'voice');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingiza ID ya mtumiaji')),
                      );
                    }
                  },
                ),
                _DialerActionButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  onPressed: () {
                    final userId = int.tryParse(_controller.text);
                    if (userId != null) {
                      widget.onCall(userId, 'video');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingiza ID ya mtumiaji')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DialerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _DialerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  static const Color _iconBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: _iconBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Story 87: Call History. Navigation: Home → Profile → ⋮ menu → Simu.
// Design: DOCS/DESIGN.md — #FAFAFA background, #1A1A1A primary, 48dp min touch targets.
// Uses CallSignalingService.getCallLog (GET /api/calls) when authToken is provided; else CallService.getCallHistory.

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/call_models.dart';
import '../../services/call_service.dart';
import '../../services/call_signaling_service.dart';
import '../../services/message_database.dart';
import '../../widgets/user_avatar.dart';
import '../calls/outgoing_call_flow_screen.dart';
import '../calls/missed_call_voice_screen.dart';

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
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
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

    // 1. Load cached call history from SQLite for instant display
    try {
      final cachedRows = await MessageDatabase.instance.getCallHistory();
      if (cachedRows.isNotEmpty && mounted) {
        final cached = cachedRows.map(_rowToCallLog).toList();
        setState(() {
          _allCalls = cached;
          _missedCalls = cached.where((c) => c.wasMissed).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      // SQLite read failed — continue to API
    }

    // 2. Fetch from API in background and update cache
    try {
      List<CallLog> apiFetched = [];

      if (widget.authToken != null && widget.authToken!.isNotEmpty) {
        final resp = await _signalingService.getCallLog(
          page: 1,
          perPage: 50,
          authToken: widget.authToken,
          userId: widget.currentUserId,
        );
        if (!mounted) return;
        if (resp.success) {
          apiFetched = resp.data.map((e) => _callLogFromEntry(e, widget.currentUserId)).toList();
        } else if (_allCalls.isEmpty) {
          setState(() {
            _isLoading = false;
            _error = resp.message;
          });
          return;
        }
      } else {
        final allResult = await _callService.getCallHistory(
          userId: widget.currentUserId,
          perPage: 50,
        );
        if (!mounted) return;
        if (allResult.success) {
          apiFetched = allResult.logs;
        } else if (_allCalls.isEmpty) {
          setState(() {
            _isLoading = false;
            _error = allResult.message;
          });
          return;
        }
      }

      // 3. Cache API results to SQLite
      if (apiFetched.isNotEmpty) {
        final rows = apiFetched.map(_callLogToRow).toList();
        MessageDatabase.instance.upsertCallLogs(rows);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (apiFetched.isNotEmpty) {
          _allCalls = apiFetched;
          _missedCalls = apiFetched.where((c) => c.wasMissed).toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_allCalls.isEmpty) {
          _error = 'Imeshindwa kupakia historia ya simu: $e';
        }
      });
    }
  }

  Map<String, dynamic> _callLogToRow(CallLog log) => {
    'id': log.id,
    'user_id': log.userId,
    'other_user_id': log.otherUserId,
    'call_id': log.callId,
    'type': log.type,
    'direction': log.direction,
    'status': log.status,
    'duration': log.duration,
    'call_time': log.callTime.toIso8601String(),
    'other_user_json': log.otherUser != null ? jsonEncode({
      'id': log.otherUser!.id,
      'first_name': log.otherUser!.firstName,
      'last_name': log.otherUser!.lastName,
      'username': log.otherUser!.username,
      'profile_photo_path': log.otherUser!.profilePhotoPath,
    }) : null,
    'json_data': jsonEncode({
      'id': log.id,
      'user_id': log.userId,
      'other_user_id': log.otherUserId,
      'call_id': log.callId,
      'type': log.type,
      'direction': log.direction,
      'status': log.status,
      'duration': log.duration,
      'call_time': log.callTime.toIso8601String(),
      'other_user': log.otherUser != null ? {
        'id': log.otherUser!.id,
        'first_name': log.otherUser!.firstName,
        'last_name': log.otherUser!.lastName,
        'username': log.otherUser!.username,
        'profile_photo_path': log.otherUser!.profilePhotoPath,
      } : null,
    }),
  };

  CallLog _rowToCallLog(Map<String, dynamic> row) {
    if (row['json_data'] != null) {
      try {
        final json = jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
        return CallLog.fromJson(json);
      } catch (_) {}
    }
    return CallLog.fromJson({
      'id': row['id'],
      'user_id': row['user_id'],
      'other_user_id': row['other_user_id'],
      'call_id': row['call_id'],
      'type': row['type'],
      'direction': row['direction'],
      'status': row['status'],
      'duration': row['duration'],
      'call_time': row['call_time'],
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
        backgroundColor: _background,
        foregroundColor: _primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Simu',
          style: TextStyle(
            color: _primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _buildTabPill(0, 'Zote'),
                const SizedBox(width: 8),
                _buildTabPill(1, 'Zilizokosa'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(
                color: _primaryText,
                strokeWidth: 2,
              ))
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.call_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? _iconBg
              : _iconBg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _iconBg.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: _accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadCallHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _iconBg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: const Text(
                  'Jaribu tena',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _iconBg.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_rounded,
                size: 32,
                color: _accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hakuna simu',
              style: TextStyle(
                color: _accent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      color: _primaryText,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _iconBg.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // User info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    UserAvatar(
                      photoUrl: call.otherUser?.avatarUrl,
                      name: call.otherUser?.displayName,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.otherUser?.displayName ?? 'Mtumiaji',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: _primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCallTime(call.callTime),
                            style: const TextStyle(color: _secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: _iconBg.withValues(alpha: 0.08)),
              // Voice call option
              _buildSheetOption(
                icon: Icons.call_rounded,
                label: 'Piga simu ya sauti',
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
              // Video call option
              _buildSheetOption(
                icon: Icons.videocam_rounded,
                label: 'Piga simu ya video',
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
              // Voice message option (missed calls only)
              if (call.wasMissed && call.callId != null && call.callId!.isNotEmpty) ...[
                Divider(height: 1, color: _iconBg.withValues(alpha: 0.08)),
                _buildSheetOption(
                  icon: Icons.mic_rounded,
                  label: 'Acha ujumbe wa sauti',
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primaryText, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
    if (!mounted) return;
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

  void _showDialer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  static const Color _missedRed = Color(0xFFB00020);

  @override
  Widget build(BuildContext context) {
    final missedColor = callLog.wasMissed ? _missedRed : _secondaryText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(
              photoUrl: callLog.otherUser?.avatarUrl,
              name: callLog.otherUser?.displayName,
              radius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    callLog.otherUser?.displayName ?? 'Mtumiaji',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: callLog.wasMissed ? _missedRed : _primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        callLog.isIncoming
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        size: 14,
                        color: missedColor,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        callLog.type == 'video'
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
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
                ],
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onCall,
                  child: Icon(
                    callLog.type == 'video'
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    color: _primaryText,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _primaryText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ingiza ID ya mtumiaji',
                  hintStyle: TextStyle(
                    color: _primaryText.withValues(alpha: 0.4),
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: _primaryText.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: _primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DialerActionButton(
                    icon: Icons.call_rounded,
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
                    icon: Icons.videocam_rounded,
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _iconBg,
          ),
        ),
      ],
    );
  }
}

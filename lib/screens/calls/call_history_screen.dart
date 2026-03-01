// Outgoing and Incoming call screens. CallHistoryScreen lives in messages/callhistory_screen.dart.
import 'package:flutter/material.dart';
import '../../models/call_models.dart';
import '../../models/friend_models.dart';
import '../../services/call_service.dart';
import '../../services/friend_service.dart';
import '../../widgets/user_avatar.dart';

// ============== OUTGOING CALL SCREEN ==============
class OutgoingCallScreen extends StatefulWidget {
  final int currentUserId;
  final Call call;

  const OutgoingCallScreen({
    super.key,
    required this.currentUserId,
    required this.call,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final CallService _callService = CallService();
  final FriendService _friendService = FriendService();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOff = false;
  String _status = 'Inapiga...';
  bool _callAnswered = false;

  @override
  void initState() {
    super.initState();
    _pollCallStatus();
  }

  void _showAddParticipantSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => FutureBuilder<FriendListResult>(
        future: _friendService.getFriends(userId: widget.currentUserId, perPage: 30),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ));
          }
          final result = snapshot.data!;
          final list = result.success ? result.friends : <UserProfile>[];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add participant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(padding: EdgeInsets.all(24), child: Text('No contacts'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final u = list[index];
                            return ListTile(
                              leading: UserAvatar(photoUrl: u.profilePhotoUrl, name: u.fullName, radius: 24),
                              title: Text(u.fullName),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invitation sent to ${u.fullName}')),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pollCallStatus() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));

      final result = await _callService.getCallStatus(
        widget.call.callId,
        widget.currentUserId,
      );

      if (result.success && result.call != null) {
        final call = result.call!;
        if (call.status == 'answered') {
          setState(() {
            _status = 'Inaendelea...';
            _callAnswered = true;
          });
        } else if (call.status == 'declined') {
          setState(() => _status = 'Imekataliwa');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
          return;
        } else if (call.status == 'ended') {
          if (mounted) Navigator.pop(context);
          return;
        }
      }
    }
  }

  Future<void> _endCall() async {
    await _callService.endCall(
      userId: widget.currentUserId,
      callId: widget.call.callId,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final callee = widget.call.callee;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            if (widget.call.isVideo)
              Expanded(
                flex: 2,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: UserAvatar(
                      photoUrl: callee?.avatarUrl,
                      name: callee?.displayName,
                      radius: 80,
                    ),
                  ),
                ),
              )
            else
              UserAvatar(
                photoUrl: callee?.avatarUrl,
                name: callee?.displayName,
                radius: 60,
              ),
            const SizedBox(height: 24),
            Text(
              callee?.displayName ?? 'Mtumiaji',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            if (widget.call.isVideo)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    label: _isVideoOff ? 'Washa' : 'Zima',
                    onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                  ),
                ],
              ),
            if (widget.call.isVideo && _callAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.person_add, color: Colors.white70, size: 20),
                  label: const Text('Add participant', style: TextStyle(color: Colors.white70)),
                  onPressed: _showAddParticipantSheet,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Sauti' : 'Nyamazisha',
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),
                _buildControlButton(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  label: _isSpeakerOn ? 'Spika' : 'Spika',
                  onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                ),
                _buildControlButton(
                  icon: Icons.dialpad,
                  label: 'Nambari',
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 48),
            FloatingActionButton.large(
              backgroundColor: Colors.red,
              onPressed: _endCall,
              child: const Icon(Icons.call_end, color: Colors.white),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: Colors.white24,
          elevation: 0,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// ============== INCOMING CALL SCREEN ==============
class IncomingCallScreen extends StatelessWidget {
  final int currentUserId;
  final Call call;

  const IncomingCallScreen({
    super.key,
    required this.currentUserId,
    required this.call,
  });

  @override
  Widget build(BuildContext context) {
    final CallService callService = CallService();
    final caller = call.caller;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            UserAvatar(
              photoUrl: caller?.avatarUrl,
              name: caller?.displayName,
              radius: 60,
            ),
            const SizedBox(height: 24),
            Text(
              caller?.displayName ?? 'Mtumiaji',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              call.isVideo ? 'Simu ya video...' : 'Simu ya sauti...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                Column(
                  children: [
                    FloatingActionButton.large(
                      heroTag: 'decline',
                      backgroundColor: Colors.red,
                      onPressed: () async {
                        await callService.declineCall(
                          userId: currentUserId,
                          callId: call.callId,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Kataa', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                // Answer
                Column(
                  children: [
                    FloatingActionButton.large(
                      heroTag: 'answer',
                      backgroundColor: Colors.green,
                      onPressed: () async {
                        final result = await callService.answerCall(
                          userId: currentUserId,
                          callId: call.callId,
                        );
                        if (result.success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OutgoingCallScreen(
                                currentUserId: currentUserId,
                                call: result.call!,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.call, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Jibu', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

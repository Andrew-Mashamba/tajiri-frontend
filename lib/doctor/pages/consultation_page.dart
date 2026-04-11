// lib/doctor/pages/consultation_page.dart
//
// Reuses TAJIRI's existing WebRTC call infrastructure:
//   - CallService / CallSignalingService for REST call lifecycle
//   - CallChannelService for WebSocket signaling (Laravel Reverb)
//   - CallWebRTCService for peer connections, media streams
//   - ActiveCallScreen for video/voice UI (PiP, controls, duration)
//   - MessageService for text chat during consultation
//
import 'package:flutter/material.dart';
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../screens/calls/outgoing_call_flow_screen.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ConsultationPage extends StatefulWidget {
  final int userId;
  final Appointment appointment;
  const ConsultationPage({super.key, required this.userId, required this.appointment});
  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final DoctorService _doctorService = DoctorService();
  final MessageService _messageService = MessageService();

  bool _isStarting = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.appointment.conversationId;
  }

  Future<void> _startVideoCall() async {
    await _startConsultationAndCall('video');
  }

  Future<void> _startAudioCall() async {
    await _startConsultationAndCall('voice');
  }

  Future<void> _startConsultationAndCall(String callType) async {
    setState(() => _isStarting = true);

    // Notify backend that consultation is starting
    final startResult = await _doctorService.startConsultation(widget.appointment.id);
    if (!mounted) return;

    if (!startResult.success) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(startResult.message ?? 'Imeshindwa kuanza mashauriano')),
      );
      return;
    }

    // Get auth token
    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();

    setState(() => _isStarting = false);

    if (!mounted) return;

    // Launch the existing call flow (reuses full WebRTC infrastructure)
    final doctorUserId = widget.appointment.doctor?.userId ?? widget.appointment.doctorId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.userId,
          calleeId: doctorUserId,
          type: callType,
          authToken: authToken,
          calleeName: widget.appointment.doctor != null
              ? 'Dk. ${widget.appointment.doctor!.fullName}'
              : 'Daktari',
          calleeAvatarUrl: widget.appointment.doctor?.profilePhotoUrl,
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    if (_conversationId != null) {
      Navigator.pushNamed(
        context,
        '/chat/$_conversationId',
      );
      return;
    }

    // Create/get DM conversation with doctor
    final doctorUserId = widget.appointment.doctor?.userId ?? widget.appointment.doctorId;
    final result = await _messageService.getPrivateConversation(
      widget.userId,
      doctorUserId,
    );
    if (!mounted) return;

    if (result.success && result.conversation != null) {
      setState(() => _conversationId = '${result.conversation!.id}');
      Navigator.pushNamed(
        context,
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kufungua mazungumzo')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final doc = appt.doctor;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Mashauriano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.emergency_rounded, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dharura? Piga 112. Huduma hii si mbadala wa dharura.',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Doctor info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      doc?.initials ?? '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              doc != null ? 'Dk. ${doc.fullName}' : 'Daktari',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doc?.isVerified == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4CAF50)),
                            ),
                        ],
                      ),
                      if (doc != null)
                        Text(doc.specialty.displayName, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(appt.scheduledAt),
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: appt.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appt.status.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appt.status.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Reason
          if (appt.reason != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sababu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  Text(appt.reason!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  if (appt.symptoms != null && appt.symptoms!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Dalili', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    Text(appt.symptoms!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Communication tools
          const Text('Zana za Mawasiliano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 12),

          // Video call button
          if (doc?.acceptsVideo != false)
            _CommunicationButton(
              icon: Icons.videocam_rounded,
              label: 'Video Call',
              description: 'Mashauriano ya video — ana kwa ana na daktari',
              color: const Color(0xFF4CAF50),
              isLoading: _isStarting,
              onTap: _startVideoCall,
            ),
          const SizedBox(height: 8),

          // Audio call button
          if (doc?.acceptsAudio != false)
            _CommunicationButton(
              icon: Icons.phone_rounded,
              label: 'Piga Simu',
              description: 'Mashauriano ya sauti — piga simu daktari',
              color: Colors.blue,
              isLoading: _isStarting,
              onTap: _startAudioCall,
            ),
          const SizedBox(height: 8),

          // Chat button
          if (doc?.acceptsChat != false)
            _CommunicationButton(
              icon: Icons.chat_rounded,
              label: 'Tuma Ujumbe',
              description: 'Mazungumzo ya maandishi — tuma picha, maandishi',
              color: Colors.deepPurple,
              onTap: _openChat,
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CommunicationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _CommunicationButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color)))
                    : Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                    Text(description, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

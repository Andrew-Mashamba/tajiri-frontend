// lib/lawyer/pages/consultation_page.dart
//
// Reuses TAJIRI's existing WebRTC call infrastructure (same as Doctor module):
//   - OutgoingCallFlowScreen for video/voice calls
//   - MessageService for text chat
//
import 'package:flutter/material.dart';
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../screens/calls/outgoing_call_flow_screen.dart';
import '../models/lawyer_models.dart';
import '../services/lawyer_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ConsultationPage extends StatefulWidget {
  final int userId;
  final LegalConsultation consultation;
  const ConsultationPage({super.key, required this.userId, required this.consultation});
  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final LawyerService _lawyerService = LawyerService();
  final MessageService _messageService = MessageService();

  bool _isStarting = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.consultation.conversationId;
  }

  Future<void> _startVideoCall() async {
    await _startConsultationAndCall('video');
  }

  Future<void> _startAudioCall() async {
    await _startConsultationAndCall('voice');
  }

  Future<void> _startConsultationAndCall(String callType) async {
    setState(() => _isStarting = true);

    final startResult = await _lawyerService.startConsultation(widget.consultation.id);
    if (!mounted) return;

    if (!startResult.success) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(startResult.message ?? 'Imeshindwa kuanza mashauriano')),
      );
      return;
    }

    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();

    setState(() => _isStarting = false);

    if (!mounted) return;

    final lawyerUserId = widget.consultation.lawyer?.userId ?? widget.consultation.lawyerId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.userId,
          calleeId: lawyerUserId,
          type: callType,
          authToken: authToken,
          calleeName: widget.consultation.lawyer != null
              ? 'Wkl. ${widget.consultation.lawyer!.fullName}'
              : 'Wakili',
          calleeAvatarUrl: widget.consultation.lawyer?.profilePhotoUrl,
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    if (_conversationId != null) {
      Navigator.pushNamed(context, '/chat/$_conversationId');
      return;
    }

    final lawyerUserId = widget.consultation.lawyer?.userId ?? widget.consultation.lawyerId;
    final result = await _messageService.getPrivateConversation(
      widget.userId,
      lawyerUserId,
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
    final c = widget.consultation;
    final law = c.lawyer;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Mashauriano ya Kisheria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Disclaimer banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mazungumzo yako na wakili ni ya siri chini ya sheria.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lawyer info card
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
                      law?.initials ?? '?',
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
                              law != null ? 'Wkl. ${law.fullName}' : 'Wakili',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (law?.isVerified == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4CAF50)),
                            ),
                        ],
                      ),
                      if (law != null)
                        Text(law.specialty.displayName, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(c.scheduledAt),
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.status.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.status.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Issue
          if (c.issue != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tatizo la Kisheria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  Text(c.issue!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  if (c.notes != null && c.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Maelezo Zaidi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    Text(c.notes!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Communication tools
          const Text('Zana za Mawasiliano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 12),

          if (law?.acceptsVideo != false)
            _CommunicationButton(
              icon: Icons.videocam_rounded,
              label: 'Video Call',
              description: 'Mashauriano ya video — ana kwa ana na wakili',
              color: const Color(0xFF4CAF50),
              isLoading: _isStarting,
              onTap: _startVideoCall,
            ),
          const SizedBox(height: 8),

          if (law?.acceptsAudio != false)
            _CommunicationButton(
              icon: Icons.phone_rounded,
              label: 'Piga Simu',
              description: 'Mashauriano ya sauti — piga simu wakili',
              color: Colors.blue,
              isLoading: _isStarting,
              onTap: _startAudioCall,
            ),
          const SizedBox(height: 8),

          if (law?.acceptsChat != false)
            _CommunicationButton(
              icon: Icons.chat_rounded,
              label: 'Tuma Ujumbe',
              description: 'Mazungumzo ya maandishi — tuma nyaraka, maandishi',
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

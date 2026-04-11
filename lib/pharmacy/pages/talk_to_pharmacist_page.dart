// lib/pharmacy/pages/talk_to_pharmacist_page.dart
//
// Reuses TAJIRI's messaging + call infrastructure to let patients
// communicate with the platform pharmacist via text, audio, or video.
//
import 'package:flutter/material.dart';
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../screens/calls/outgoing_call_flow_screen.dart';
import '../services/pharmacy_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TalkToPharmacistPage extends StatefulWidget {
  final int userId;
  const TalkToPharmacistPage({super.key, required this.userId});
  @override
  State<TalkToPharmacistPage> createState() => _TalkToPharmacistPageState();
}

class _TalkToPharmacistPageState extends State<TalkToPharmacistPage> {
  final PharmacyService _pharmacyService = PharmacyService();
  final MessageService _messageService = MessageService();

  bool _isLoading = true;
  int? _pharmacistUserId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPharmacist();
  }

  Future<void> _loadPharmacist() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _pharmacyService.getPharmacistUserId();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _pharmacistUserId = result.data;
        } else {
          _error = result.message ?? 'Imeshindwa kupata duka la dawa';
        }
      });
    }
  }

  Future<void> _openChat() async {
    if (_pharmacistUserId == null) return;

    final result = await _messageService.getPrivateConversation(
      widget.userId,
      _pharmacistUserId!,
    );
    if (!mounted) return;

    if (result.success && result.conversation != null) {
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

  Future<void> _startCall(String callType) async {
    if (_pharmacistUserId == null) return;

    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.userId,
          calleeId: _pharmacistUserId!,
          type: callType,
          authToken: authToken,
          calleeName: 'Duka la Dawa Tajiri',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Zungumza na Duka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: _kSecondary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _loadPharmacist, style: FilledButton.styleFrom(backgroundColor: _kPrimary), child: const Text('Jaribu Tena')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pharmacist info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Duka la Dawa Tajiri',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Waambie kuhusu dawa unazohitaji, uliza maswali, au pata msaada.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Communication options
                    const Text('Njia za Mawasiliano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 12),

                    _CommButton(
                      icon: Icons.chat_rounded,
                      label: 'Tuma Ujumbe',
                      description: 'Andika ujumbe — tuma picha za agizo, uliza kuhusu dawa',
                      color: Colors.deepPurple,
                      onTap: _openChat,
                    ),
                    const SizedBox(height: 10),
                    _CommButton(
                      icon: Icons.phone_rounded,
                      label: 'Piga Simu',
                      description: 'Zungumza moja kwa moja na mfamasia',
                      color: Colors.blue,
                      onTap: () => _startCall('voice'),
                    ),
                    const SizedBox(height: 10),
                    _CommButton(
                      icon: Icons.videocam_rounded,
                      label: 'Video Call',
                      description: 'Onyesha agizo lako au dawa kwa video',
                      color: const Color(0xFF4CAF50),
                      onTap: () => _startCall('video'),
                    ),
                    const SizedBox(height: 24),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, size: 18, color: _kPrimary),
                              SizedBox(width: 8),
                              Text('Unaweza Kuuliza Kuhusu:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _TipItem(text: 'Dawa zilizopo na bei zake'),
                          _TipItem(text: 'Mbadala wa dawa (generics)'),
                          _TipItem(text: 'Jinsi ya kutumia dawa'),
                          _TipItem(text: 'Muda wa kusubiri agizo'),
                          _TipItem(text: 'Hali ya agizo lako'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CommButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _CommButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
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
                child: Icon(icon, size: 24, color: color),
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

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _kSecondary))),
        ],
      ),
    );
  }
}

// lib/events/pages/organizer/announcement_page.dart
import 'package:flutter/material.dart';
import '../../models/event_enums.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AnnouncementPage extends StatefulWidget {
  final int eventId;

  const AnnouncementPage({super.key, required this.eventId});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final _service = EventOrganizerService();
  final _msgCtrl = TextEditingController();
  late EventStrings _strings;
  AnnouncementChannel _channel = AnnouncementChannel.push;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Announcement'),
        content: Text('Send to all attendees via ${_channel.apiValue.toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _sending = true);
    final result = await _service.sendAnnouncement(eventId: widget.eventId, message: msg, channel: _channel);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      _msgCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement sent successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to send announcement')));
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
        title: Text(_strings.sendAnnouncement, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _msgCtrl,
                maxLines: 6,
                maxLength: 500,
                style: const TextStyle(color: _kPrimary),
                decoration: InputDecoration(
                  hintText: _strings.announcementHint,
                  hintStyle: const TextStyle(color: _kSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Channel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 12),
              _ChannelSelector(selected: _channel, onSelect: (c) => setState(() => _channel = c)),
              const SizedBox(height: 8),
              _ChannelDescription(channel: _channel),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_strings.sendAnnouncement, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelSelector extends StatelessWidget {
  final AnnouncementChannel selected;
  final ValueChanged<AnnouncementChannel> onSelect;

  const _ChannelSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final channels = [
      (AnnouncementChannel.push, Icons.notifications_rounded, 'Push'),
      (AnnouncementChannel.sms, Icons.sms_rounded, 'SMS'),
      (AnnouncementChannel.whatsapp, Icons.chat_rounded, 'WhatsApp'),
      (AnnouncementChannel.all, Icons.all_inclusive_rounded, 'All'),
    ];

    return Row(
      children: channels.map((c) {
        final active = selected == c.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(c.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? _kPrimary : Colors.black26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.$2, size: 20, color: active ? Colors.white : _kSecondary),
                  const SizedBox(height: 4),
                  Text(c.$3, style: TextStyle(fontSize: 11, color: active ? Colors.white : _kSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChannelDescription extends StatelessWidget {
  final AnnouncementChannel channel;
  const _ChannelDescription({required this.channel});

  String get _desc {
    switch (channel) {
      case AnnouncementChannel.push: return 'Sends a push notification to all attendees with the TAJIRI app installed.';
      case AnnouncementChannel.sms: return 'Sends an SMS to all attendees. Standard rates may apply.';
      case AnnouncementChannel.whatsapp: return 'Sends a WhatsApp message to attendees with WhatsApp.';
      case AnnouncementChannel.all: return 'Sends via all available channels — push, SMS, and WhatsApp.';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
    child: Text(_desc, style: const TextStyle(fontSize: 12, color: _kSecondary)),
  );
}

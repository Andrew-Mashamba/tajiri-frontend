import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_enums.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EventShareSheet extends StatelessWidget {
  final String eventName;
  final String? shareLink;
  final ValueChanged<ShareTarget>? onShare;
  const EventShareSheet({super.key, required this.eventName, this.shareLink, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Shiriki / Share', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(eventName, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareOption(icon: Icons.message_rounded, label: 'WhatsApp', color: const Color(0xFF25D366), onTap: () { onShare?.call(ShareTarget.whatsapp); Navigator.pop(context); }),
              _ShareOption(icon: Icons.sms_rounded, label: 'SMS', color: _kPrimary, onTap: () { onShare?.call(ShareTarget.sms); Navigator.pop(context); }),
              _ShareOption(icon: Icons.copy_rounded, label: 'Nakili', color: _kSecondary, onTap: () {
                if (shareLink != null) Clipboard.setData(ClipboardData(text: shareLink!));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Kiungo kimenakiliwa!' : 'Link copied!')));
                Navigator.pop(context);
              }),
              _ShareOption(icon: Icons.send_rounded, label: 'TAJIRI', color: _kPrimary, onTap: () { onShare?.call(ShareTarget.tajiriDm); Navigator.pop(context); }),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ],
      ),
    );
  }
}

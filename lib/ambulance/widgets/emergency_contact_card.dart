// lib/ambulance/widgets/emergency_contact_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ambulance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback? onRemove;
  final bool isSwahili;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    this.onRemove,
    this.isSwahili = false,
  });

  Future<void> _callContact() async {
    final uri = Uri(scheme: 'tel', path: contact.phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8E8E8),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${contact.relationship} - ${contact.phone}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: _callContact,
              icon: const Icon(Icons.phone_rounded, color: _kPrimary, size: 22),
              tooltip: isSwahili ? 'Piga simu' : 'Call',
            ),
          ),
          if (onRemove != null)
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: _kSecondary, size: 22),
                tooltip: isSwahili ? 'Ondoa' : 'Remove',
              ),
            ),
        ],
      ),
    );
  }
}

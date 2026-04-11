import 'package:flutter/material.dart';

const Color _kSecondary = Color(0xFF666666);

class NoEventsPlaceholder extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  const NoEventsPlaceholder({super.key, required this.message, this.subtitle, this.icon = Icons.event_busy_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kSecondary), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(fontSize: 13, color: Colors.grey.shade400), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

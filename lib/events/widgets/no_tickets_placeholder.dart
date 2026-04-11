import 'package:flutter/material.dart';

const Color _kSecondary = Color(0xFF666666);

class NoTicketsPlaceholder extends StatelessWidget {
  final String? message;
  const NoTicketsPlaceholder({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message ?? 'Huna tiketi bado', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kSecondary)),
            const SizedBox(height: 4),
            Text('No tickets yet', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

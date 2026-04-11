// lib/passport/widgets/passport_card.dart
import 'package:flutter/material.dart';
import '../models/passport_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PassportCardWidget extends StatelessWidget {
  final PassportInfo passport;
  const PassportCardWidget({super.key, required this.passport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('PASIPOTI', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: passport.isExpired ? Colors.red : passport.isExpiring ? Colors.orange : const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(4)),
            child: Text(passport.isExpired ? 'Expired' : '${passport.daysUntilExpiry}d',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(passport.passportNumber,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(passport.holderName,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Text('Exp: ${passport.expiryDate.day}/${passport.expiryDate.month}/${passport.expiryDate.year}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const Spacer(),
          Text('${passport.pages} pages', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ]),
    );
  }
}

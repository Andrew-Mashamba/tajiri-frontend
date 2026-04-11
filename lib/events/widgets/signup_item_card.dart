import 'package:flutter/material.dart';
import '../models/signup_list.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SignupItemCard extends StatelessWidget {
  final SignupItem item;
  final VoidCallback? onClaim;
  final VoidCallback? onUnclaim;
  const SignupItemCard({super.key, required this.item, this.onClaim, this.onUnclaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(item.isClaimed ? Icons.check_circle_rounded : Icons.circle_outlined, size: 22, color: item.isClaimed ? Colors.green : Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontSize: 14, color: _kPrimary, decoration: item.isClaimed ? TextDecoration.lineThrough : null)),
                if (item.claimedBy != null) Text(item.claimedBy!.fullName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
          if (!item.isClaimed && onClaim != null)
            TextButton(onPressed: onClaim, child: const Text('Chukua', style: TextStyle(fontSize: 12, color: _kPrimary))),
          if (item.isClaimed && onUnclaim != null)
            TextButton(onPressed: onUnclaim, child: const Text('Achia', style: TextStyle(fontSize: 12, color: _kSecondary))),
        ],
      ),
    );
  }
}

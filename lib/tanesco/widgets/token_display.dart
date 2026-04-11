// lib/tanesco/widgets/token_display.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TokenDisplay extends StatelessWidget {
  final String token;
  final double units;
  final double amount;
  final String meterNumber;
  final String? selcomReference;

  const TokenDisplay({
    super.key,
    required this.token,
    required this.units,
    required this.amount,
    required this.meterNumber,
    this.selcomReference,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token imenakiliwa / Token copied'), duration: Duration(seconds: 2)));
  }

  void _share() {
    final msg = 'LUKU Token: $token\n'
        'Mita: $meterNumber\n'
        'Units: ${units.toStringAsFixed(1)} kWh\n'
        'Kiasi: TZS ${amount.toStringAsFixed(0)}';
    SharePlus.instance.share(ShareParams(text: msg));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF4CAF50)),
          const SizedBox(height: 12),
          const Text('LUKU Token',
              style: TextStyle(fontSize: 12, color: _kSecondary, letterSpacing: 1)),
          const SizedBox(height: 12),
          // Large token display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatToken(token),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(label: '${units.toStringAsFixed(1)} kWh', icon: Icons.electric_bolt_rounded),
              const SizedBox(width: 12),
              _InfoChip(label: 'TZS ${amount.toStringAsFixed(0)}', icon: Icons.payments_rounded),
            ],
          ),
          if (selcomReference != null) ...[
            const SizedBox(height: 8),
            Text('Ref: $selcomReference',
                style: const TextStyle(fontSize: 10, color: _kSecondary)),
          ],
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Nakili / Copy', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Tuma / Share', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatToken(String t) {
    // Insert space every 4 digits for readability
    final buf = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(t[i]);
    }
    return buf.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _kPrimary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
      ]),
    );
  }
}

// lib/alerts/pages/alert_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/alerts_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AlertDetailPage extends StatelessWidget {
  final EmergencyAlert alert;
  const AlertDetailPage({super.key, required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case 'emergency':
        return Colors.red.shade800;
      case 'warning':
        return Colors.red;
      case 'watch':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(isSwahili ? 'Maelezo' : 'Alert Details',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Severity banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _severityColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: _severityColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _severityColor),
                      ),
                      Text(
                        alert.type[0].toUpperCase() + alert.type.substring(1),
                        style: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(alert.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 12),

          if (alert.region != null) ...[
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: _kSecondary),
              const SizedBox(width: 4),
              Text(alert.region!,
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ]),
            const SizedBox(height: 8),
          ],

          Row(children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: _kSecondary),
            const SizedBox(width: 4),
            Text(
              '${isSwahili ? 'Imetolewa' : 'Issued'}: ${alert.issuedAt.toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
          ]),
          const SizedBox(height: 16),

          Text(alert.description,
              style: const TextStyle(
                  fontSize: 15, color: _kPrimary, height: 1.5)),

          if (alert.instructions != null) ...[
            const SizedBox(height: 20),
            Text(isSwahili ? 'Maelekezo' : 'Instructions',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(alert.instructions!,
                  style: const TextStyle(
                      fontSize: 14, color: _kPrimary, height: 1.5)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

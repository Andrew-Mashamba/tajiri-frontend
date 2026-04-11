// lib/qibla/pages/qibla_map_page.dart
import 'package:flutter/material.dart';
import '../models/qibla_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class QiblaMapPage extends StatelessWidget {
  final QiblaDirection? direction;
  const QiblaMapPage({super.key, this.direction});

  @override
  Widget build(BuildContext context) {
    final dir = direction;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ramani ya Qibla',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Map Placeholder ──────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, size: 64, color: _kSecondary),
                      SizedBox(height: 12),
                      Text(
                        'Ramani ya Qibla',
                        style: TextStyle(
                          color: _kPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mstari kuelekea Makkah',
                        style: TextStyle(color: _kSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Info Card ────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Mahali Pako',
                    dir?.locationName ?? 'Dar es Salaam',
                    Icons.my_location_rounded,
                  ),
                  const Divider(height: 20),
                  _infoRow(
                    'Mwelekeo',
                    '${dir?.bearing.toStringAsFixed(1) ?? "0"}\u00B0',
                    Icons.explore_rounded,
                  ),
                  const Divider(height: 20),
                  _infoRow(
                    'Umbali',
                    '${dir?.distanceKm.toStringAsFixed(0) ?? "0"} km',
                    Icons.straighten_rounded,
                  ),
                  const Divider(height: 20),
                  _infoRow(
                    'Al-Ka\'bah',
                    'Makkah, Saudi Arabia',
                    Icons.mosque_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _kSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

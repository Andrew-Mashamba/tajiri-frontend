// lib/qibla/pages/calibration_page.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CalibrationPage extends StatelessWidget {
  const CalibrationPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Sahihisha Dira',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ─── Figure 8 Illustration ──────────────────
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gesture_rounded,
                  size: 80,
                  color: _kSecondary,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Calibrate Your Compass / Sahihisha Dira Yako',
                style: TextStyle(
                  color: _kPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              const Text(
                'Rotate your phone in a figure-8 pattern several times to calibrate the compass. / '
                'Zungusha simu yako kwa umbo la nambari 8 mara kadhaa.',
                style: TextStyle(color: _kSecondary, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              _buildStep('1', 'Hold phone away from metal / Shika mbali na chuma'),
              const SizedBox(height: 12),
              _buildStep('2', 'Rotate in figure-8 shape 3-4 times / Zungusha mara 3-4'),
              const SizedBox(height: 12),
              _buildStep('3', 'Watch indicator turn green / Angalia kiashiria kuwa kijani'),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done / Nimemaliza'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _kPrimary, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

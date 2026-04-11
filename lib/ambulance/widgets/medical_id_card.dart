// lib/ambulance/widgets/medical_id_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ambulance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kRed = Color(0xFFCC0000);

class MedicalIdCard extends StatelessWidget {
  final MedicalProfile profile;
  final String? userName;
  final bool isSwahili;

  const MedicalIdCard({
    super.key,
    required this.profile,
    this.userName,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.medical_information_rounded, color: _kRed, size: 24),
              const SizedBox(width: 8),
              Text(
                  isSwahili ? 'Kitambulisho cha Afya' : 'Medical ID',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kRed)),
              const Spacer(),
              if (profile.bloodType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(profile.bloodType!,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: _kRed)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          if (userName != null)
            Text(userName!,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          const Divider(height: 20),

          // Allergies
          if (profile.allergies.isNotEmpty) ...[
            Text(isSwahili ? 'Mzio' : 'Allergies',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: profile.allergies.map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Conditions
          if (profile.conditions.isNotEmpty) ...[
            Text(isSwahili ? 'Hali za Afya' : 'Conditions',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 4),
            Text(profile.conditions.join(', '),
                style: const TextStyle(fontSize: 13, color: _kPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
          ],

          // Medications
          if (profile.medications.isNotEmpty) ...[
            Text(isSwahili ? 'Dawa' : 'Medications',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 4),
            Text(profile.medications.join(', '),
                style: const TextStyle(fontSize: 13, color: _kPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],

          // Emergency contacts
          if (profile.emergencyContacts.isNotEmpty) ...[
            const Divider(height: 20),
            Text(isSwahili ? 'Mawasiliano ya Dharura' : 'Emergency Contacts',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 4),
            ...profile.emergencyContacts.take(2).map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: _kSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${c.name} (${c.relationship})',
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(c.phone,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            }),
          ],

          // FEATURE 21: QR Code Medical ID
          const Divider(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  isSwahili ? 'Skani kwa Taarifa za Afya' : 'Scan for Medical Info',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                QrImageView(
                  data: _buildQrData(),
                  version: QrVersions.auto,
                  size: 180,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: _kPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Encode medical data into a compact JSON string for QR code
  String _buildQrData() {
    final data = <String, dynamic>{};
    if (profile.bloodType != null) data['blood'] = profile.bloodType;
    if (profile.allergies.isNotEmpty) data['allergies'] = profile.allergies;
    if (profile.conditions.isNotEmpty) data['conditions'] = profile.conditions;
    if (profile.emergencyContacts.isNotEmpty) {
      data['emergency_phone'] = profile.emergencyContacts.first.phone;
      data['emergency_name'] = profile.emergencyContacts.first.name;
    }
    if (userName != null) data['name'] = userName;
    return jsonEncode(data);
  }
}

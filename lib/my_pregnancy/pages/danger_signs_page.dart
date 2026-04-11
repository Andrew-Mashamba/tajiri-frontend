// lib/my_pregnancy/pages/danger_signs_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/my_pregnancy_models.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DangerSignsPage extends StatefulWidget {
  const DangerSignsPage({super.key});

  @override
  State<DangerSignsPage> createState() => _DangerSignsPageState();
}

class _DangerSignsPageState extends State<DangerSignsPage> {
  bool _isLocating = false;

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  void _callEmergency(BuildContext context) async {
    final uri = Uri.parse('tel:112');
    final sw = _sw;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Imeshindwa kupiga simu. Piga 112 mwenyewe.'
                  : 'Could not make the call. Dial 112 manually.')),
        );
      }
    }
  }

  Future<void> _openNearestHospital() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLocating = false);
        _openMaps();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) setState(() => _isLocating = false);

      final url =
          'https://www.google.com/maps/search/hospital/@${position.latitude},${position.longitude},14z';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _openMaps();
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
      _openMaps();
    }
  }

  void _openMaps() async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/hospital+near+me');
    final sw = _sw;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(sw
                    ? 'Imeshindwa kufungua ramani. Tafuta hospitali ya karibu mwenyewe.'
                    : 'Could not open maps. Search for the nearest hospital manually.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Imeshindwa kufungua ramani. Tafuta hospitali ya karibu mwenyewe.'
                  : 'Could not open maps. Search for the nearest hospital manually.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final dangerSigns = DangerSign.all();

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Dalili za Hatari' : 'Danger Signs',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Emergency call button
          GestureDetector(
            onTap: () => _callEmergency(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    sw
                        ? 'PIGA SIMU YA DHARURA - 112'
                        : 'CALL EMERGENCY - 112',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Warning intro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      sw ? 'Soma na Uelewe' : 'Read and Understand',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sw
                      ? 'Dalili hizi zinahitaji kwenda hospitali MARA MOJA. Usichelewe. Maisha ya mama na mtoto yanategemea kuchukua hatua haraka.'
                      : 'These signs require going to the hospital IMMEDIATELY. Do not delay. The lives of mother and baby depend on quick action.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Danger sign cards
          ...dangerSigns.asMap().entries.map((entry) {
            final index = entry.key;
            final sign = entry.value;
            return _DangerSignCard(
              sign: sign,
              index: index + 1,
              isSwahili: sw,
            );
          }),

          const SizedBox(height: 16),

          // Nearest hospital prompt
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded,
                        size: 20, color: _kPrimary),
                    const SizedBox(width: 8),
                    Text(
                      sw ? 'Hospitali ya Karibu' : 'Nearest Hospital',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sw
                      ? 'Hakikisha unajua hospitali ya karibu nawe yenye huduma za dharura za uzazi. Hifadhi nambari ya simu na anuani.'
                      : 'Make sure you know the nearest hospital with emergency maternity services. Save the phone number and address.',
                  style: const TextStyle(
                      fontSize: 13, color: _kSecondary, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isLocating ? null : _openNearestHospital,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kPrimary),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(_isLocating
                        ? (sw ? 'Inatafuta eneo lako...' : 'Finding your location...')
                        : (sw
                            ? 'Tafuta Hospitali Karibu Nawe'
                            : 'Find Hospitals Near You')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Emergency numbers
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Nambari za Dharura' : 'Emergency Numbers',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _EmergencyNumber(
                    label: sw ? 'Huduma ya Dharura' : 'Emergency Services',
                    number: '112'),
                _EmergencyNumber(
                    label: sw ? 'Ambulensi' : 'Ambulance', number: '114'),
                _EmergencyNumber(
                    label: sw ? 'Zimamoto' : 'Fire Brigade', number: '115'),
                _EmergencyNumber(
                    label: sw ? 'Polisi' : 'Police', number: '112'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DangerSignCard extends StatelessWidget {
  final DangerSign sign;
  final int index;
  final bool isSwahili;

  const _DangerSignCard({
    required this.sign,
    required this.index,
    this.isSwahili = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sign.displayTitle(isSwahili: isSwahili),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sign.displayDescription(isSwahili: isSwahili),
            style: const TextStyle(
                fontSize: 13, color: _kSecondary, height: 1.4),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sign.displayAction(isSwahili: isSwahili),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyNumber extends StatelessWidget {
  final String label;
  final String number;

  const _EmergencyNumber({required this.label, required this.number});

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse('tel:$number');
          final sw = _sw;
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(sw
                    ? 'Imeshindwa kupiga $number'
                    : 'Could not dial $number')),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14, color: _kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/community/pages/emergency_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nambari za Dharura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Emergency Numbers',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.emergency_rounded,
                    size: 40, color: Colors.red.shade400),
                const SizedBox(height: 8),
                Text(
                  'Kama una dharura ya kweli, piga simu moja kwa moja!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In case of real emergency, call directly!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Emergency numbers
          _EmergencyNumberCard(
            icon: Icons.local_police_rounded,
            title: 'Polisi',
            subtitle: 'Police',
            number: '112',
            description: 'Nambari ya dharura ya polisi Tanzania',
            color: Colors.blue,
            onCall: () => _callNumber('112'),
          ),
          const SizedBox(height: 10),
          _EmergencyNumberCard(
            icon: Icons.local_fire_department_rounded,
            title: 'Zimamoto',
            subtitle: 'Fire Brigade',
            number: '114',
            description: 'Nambari ya zimamoto na uokoaji',
            color: Colors.orange,
            onCall: () => _callNumber('114'),
          ),
          const SizedBox(height: 10),
          _EmergencyNumberCard(
            icon: Icons.local_hospital_rounded,
            title: 'Ambulensi',
            subtitle: 'Ambulance',
            number: '114',
            description: 'Huduma za dharura za afya',
            color: Colors.red,
            onCall: () => _callNumber('114'),
          ),
          const SizedBox(height: 10),
          _EmergencyNumberCard(
            icon: Icons.traffic_rounded,
            title: 'Polisi wa Barabara',
            subtitle: 'Traffic Police',
            number: '112',
            description: 'Ajali na dharura za barabarani',
            color: Colors.green,
            onCall: () => _callNumber('112'),
          ),
          const SizedBox(height: 10),
          _EmergencyNumberCard(
            icon: Icons.child_care_rounded,
            title: 'Watoto Hatarini',
            subtitle: 'Child Helpline',
            number: '116',
            description: 'Unyanyasaji wa watoto na dharura',
            color: Colors.purple,
            onCall: () => _callNumber('116'),
          ),
          const SizedBox(height: 10),
          _EmergencyNumberCard(
            icon: Icons.woman_rounded,
            title: 'Unyanyasaji wa Kijinsia',
            subtitle: 'Gender Violence',
            number: '116',
            description: 'Msaada kwa wahanga wa unyanyasaji',
            color: Colors.pink,
            onCall: () => _callNumber('116'),
          ),
          const SizedBox(height: 20),

          // Additional info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: _kSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Muhimu kujua',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '1. Kaa shwari na eleza hali yako kwa utulivu\n'
                  '2. Taja mahali ulipo kwa usahihi\n'
                  '3. Fuata maelekezo ya opereta\n'
                  '4. Usikate simu hadi uambiwe',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EmergencyNumberCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String number;
  final String description;
  final MaterialColor color;
  final VoidCallback onCall;

  const _EmergencyNumberCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.description,
    required this.color,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                Text(
                  description,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCall,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

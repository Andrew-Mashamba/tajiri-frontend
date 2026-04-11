// lib/doctor/pages/consent_page.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Pre-consultation informed consent — required before every appointment.
/// Bilingual (Swahili primary, English clarification).
class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});
  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _consent1 = false; // Nature & limitations
  bool _consent2 = false; // Not emergency substitute
  bool _consent3 = false; // Data storage
  bool _consent4 = false; // Right to in-person referral

  bool get _allConsented => _consent1 && _consent2 && _consent3 && _consent4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Ridhaa ya Mashauriano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tafadhali soma na ukubali masharti yafuatayo kabla ya kuendelea na mashauriano ya mtandaoni.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Consent items
          _ConsentItem(
            value: _consent1,
            onChanged: (v) => setState(() => _consent1 = v ?? false),
            title: 'Asili na Mipaka ya Mashauriano',
            description: 'Naelewa kuwa mashauriano ya mtandaoni yana mipaka na hayawezi kuchukua nafasi ya uchunguzi wa mwili. '
                'Daktari anaweza kushindwa kutambua hali fulani kupitia mtandao.',
            english: 'I understand that teleconsultation has limitations and cannot replace physical examination.',
          ),
          _ConsentItem(
            value: _consent2,
            onChanged: (v) => setState(() => _consent2 = v ?? false),
            title: 'Si Mbadala wa Dharura',
            description: 'Naelewa kuwa huduma hii SI mbadala wa huduma za dharura. Kwa dharura (maumivu makali ya kifua, '
                'kupumua vibaya, kupoteza fahamu), ninapaswa kupiga 112 au kwenda hospitali mara moja.',
            english: 'This is NOT a substitute for emergency care. For emergencies, call 112.',
          ),
          _ConsentItem(
            value: _consent3,
            onChanged: (v) => setState(() => _consent3 = v ?? false),
            title: 'Uhifadhi wa Data',
            description: 'Ninakubali data yangu ya afya (mazungumzo, maelezo ya mashauriano, dawa zilizopewa) '
                'kuhifadhiwa kwa usalama na kutumika tu kwa matibabu yangu. Ninaweza kuomba kufutwa kwa data.',
            english: 'I consent to secure storage of my health data for treatment purposes only.',
          ),
          _ConsentItem(
            value: _consent4,
            onChanged: (v) => setState(() => _consent4 = v ?? false),
            title: 'Haki ya Rufaa',
            description: 'Naelewa nina haki ya kuomba rufaa ya ana kwa ana wakati wowote. '
                'Daktari pia anaweza kunielekezea hospitali ikiwa ataona ni muhimu.',
            english: 'I have the right to request in-person referral at any time.',
          ),
          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dawa za kudhibitiwa (Schedule I-IV) hazitaandikwa kupitia mtandao kwa mujibu wa sheria ya Tanzania.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _allConsented ? () => Navigator.pop(context, true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Ninakubali — Endelea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ghairi', style: TextStyle(color: _kSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String description;
  final String english;

  const _ConsentItem({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.description,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: value ? Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: _kPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.4)),
                const SizedBox(height: 4),
                Text(english, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

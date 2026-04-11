// lib/dawasco/pages/help_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<DawascoOffice> _offices = [];
  List<WaterTanker> _tankers = [];
  bool _loadingOffices = true;
  bool _loadingTankers = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  List<EmergencyContact> _emergencyContacts() {
    final sw = _sw;
    return [
      EmergencyContact(
        name: sw ? 'Bomba Lililopasuka' : 'Burst Main',
        phone: '0222134375',
        description: sw ? 'Ripoti mabomba yaliyopasuka mara moja' : 'Report burst pipes immediately',
      ),
      EmergencyContact(
        name: sw ? 'Uchafuzi wa Maji' : 'Water Contamination',
        phone: '0222131191',
        description: sw ? 'Ripoti maji machafu au yenye harufu' : 'Report dirty or smelly water',
      ),
      EmergencyContact(
        name: sw ? 'Matatizo ya Maji Taka' : 'Sewerage Emergency',
        phone: '0222116103',
        description: sw ? 'Mabomba ya maji taka yaliyovuja' : 'Leaking sewerage pipes',
      ),
    ];
  }

  static const List<IconData> _emergencyIcons = [
    Icons.water_damage_rounded,
    Icons.warning_rounded,
    Icons.plumbing_rounded,
  ];

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        DawascoService.getOffices(),
        DawascoService.getWaterTankers(),
      ]);
      if (!mounted) return;
      final officeR = results[0] as PaginatedResult<DawascoOffice>;
      final tankerR = results[1] as PaginatedResult<WaterTanker>;
      setState(() {
        _loadingOffices = false;
        _loadingTankers = false;
        if (officeR.success) _offices = officeR.items;
        if (tankerR.success) _tankers = tankerR.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingOffices = false; _loadingTankers = false; });
      final sw = _sw;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw ? 'Imeshindwa kupakia data: $e' : 'Failed to load data: $e'),
      ));
    }
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (!mounted) return;
      final sw = _sw;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw ? 'Imeshindwa kupiga simu: $e' : 'Failed to make call: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final contacts = _emergencyContacts();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Msaada & Mawasiliano' : 'Help & Contacts',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Emergency numbers
        Text(sw ? 'Namba za Dharura' : 'Emergency Numbers',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 10),
        ...List.generate(contacts.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _EmergencyCard(
            icon: _emergencyIcons[i],
            contact: contacts[i],
            onCall: _callNumber,
          ),
        )),
        const SizedBox(height: 24),

        // DAWASCO offices
        Text(sw ? 'Ofisi za DAWASCO' : 'DAWASCO Offices',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 10),
        if (_loadingOffices)
          const Padding(padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
        else if (_offices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(sw ? 'Hakuna ofisi zilizopatikana' : 'No offices found',
                style: const TextStyle(color: _kSecondary, fontSize: 13)),
          )
        else
          ..._offices.map((o) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_rounded, size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (o.address != null)
                  Text(o.address!,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                if (o.district != null)
                  Text(o.district!,
                      style: const TextStyle(fontSize: 10, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              if (o.phone != null)
                IconButton(
                  onPressed: () => _callNumber(o.phone!),
                  icon: const Icon(Icons.phone_rounded, size: 20, color: _kPrimary),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
            ]),
          )),
        const SizedBox(height: 24),

        // Water tankers
        Text(sw ? 'Magari ya Maji' : 'Water Tankers',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 10),
        if (_loadingTankers)
          const Padding(padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
        else if (_tankers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(sw ? 'Hakuna magari yaliyopatikana' : 'No tankers found',
                style: const TextStyle(color: _kSecondary, fontSize: 13)),
          )
        else
          ..._tankers.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded, size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (t.district != null)
                  Text(t.district!,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(children: [
                  if (t.capacityLitres != null)
                    Text('${t.capacityLitres!.toStringAsFixed(0)}L',
                        style: const TextStyle(fontSize: 10, color: _kSecondary)),
                  if (t.capacityLitres != null && t.pricePerTrip != null)
                    const Text(' \u2022 ', style: TextStyle(fontSize: 10, color: _kSecondary)),
                  if (t.pricePerTrip != null)
                    Text('TZS ${t.pricePerTrip!.toStringAsFixed(0)}/${sw ? 'safari' : 'trip'}',
                        style: const TextStyle(fontSize: 10, color: _kSecondary)),
                ]),
              ])),
              IconButton(
                onPressed: () => _callNumber(t.phone),
                icon: const Icon(Icons.phone_rounded, size: 20, color: _kPrimary),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ]),
          )),
        const SizedBox(height: 24),

        // FAQ
        Text(sw ? 'Maswali Yanayoulizwa Sana' : 'FAQ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 10),
        _FaqTile(
          q: sw ? 'Jinsi ya kusoma mita yangu?' : 'How to read my meter?',
          a: sw ? 'Soma nambari nyeusi kwenye mita yako. Nambari nyekundu ni desimali na hazihesabiwi.'
              : 'Read the black numbers on your meter. Red numbers are decimals and are not counted.',
        ),
        const SizedBox(height: 8),
        _FaqTile(
          q: sw ? 'Nifanye nini maji yakikatwa?' : 'What to do if water is disconnected?',
          a: sw ? 'Lipa bili zote zilizo malimbikizo kwanza, kisha omba kuunganishwa tena kupitia programu au ofisi ya DAWASCO.'
              : 'Pay all outstanding bills first, then request reconnection through the app or DAWASCO office.',
        ),
        const SizedBox(height: 8),
        _FaqTile(
          q: sw ? 'Jinsi ya kuomba muunganisho mpya?' : 'How to apply for new connection?',
          a: sw ? 'Nenda sehemu ya "Muunganisho Mpya" kwenye programu, jaza fomu na uwasilishe nyaraka zinazohitajika.'
              : 'Go to "New Connection" section in the app, fill the form and submit required documents.',
        ),
        const SizedBox(height: 8),
        _FaqTile(
          q: sw ? 'Bili yangu ni kubwa sana, nifanyeje?' : 'My bill is too high, what should I do?',
          a: sw ? 'Angalia kama kuna uvujaji nyumbani kwako. Ukiona bili si sahihi, wasilisha pingamizi kupitia "Historia ya Bili".'
              : 'Check for leaks at home. If the bill seems incorrect, submit a dispute through "Bill History".',
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final EmergencyContact contact;
  final void Function(String) onCall;
  const _EmergencyCard({required this.icon, required this.contact, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: Colors.red),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (contact.description != null)
            Text(contact.description!, style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        IconButton(
          onPressed: () => onCall(contact.phone),
          icon: const Icon(Icons.phone_rounded, size: 22, color: Colors.red),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ]),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(widget.q,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20, color: _kSecondary),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text(widget.a, style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 10, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }
}

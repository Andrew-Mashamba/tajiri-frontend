// lib/police/pages/police_home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../services/police_service.dart';
import '../widgets/sos_button.dart';
import 'station_finder_page.dart';
import 'report_crime_page.dart';
import 'my_reports_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PoliceHomePage extends StatefulWidget {
  final int userId;
  const PoliceHomePage({super.key, required this.userId});
  @override
  State<PoliceHomePage> createState() => _PoliceHomePageState();
}

class _PoliceHomePageState extends State<PoliceHomePage> {
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Tuma SOS?' : 'Send SOS?'),
        content: Text(_isSwahili
            ? 'Hii itatuma msaada wa dharura kwa mawasiliano yako.'
            : 'This will send an emergency alert to your contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Hapana' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_isSwahili ? 'Tuma SOS' : 'Send SOS'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      // TODO: Replace with actual device GPS coordinates via geolocator
      final result =
          await PoliceService.triggerSos(lat: -6.7924, lng: 39.2083);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(result.success
            ? (_isSwahili ? 'SOS imetumwa!' : 'SOS sent!')
            : (result.message ??
                (_isSwahili ? 'Imeshindwa kutuma' : 'Failed to send'))),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imeshindwa kutuma SOS. Jaribu tena.'
            : 'Failed to send SOS. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // SOS Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _isSwahili ? 'Dharura' : 'Emergency',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SosButton(onPressed: _triggerSos, isSwahili: _isSwahili),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _callEmergency,
                  icon: const Icon(Icons.phone_rounded,
                      size: 18, color: Colors.white),
                  label: Text(_isSwahili ? 'Piga 112' : 'Call 112',
                      style: const TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          Text(
            _isSwahili ? 'Huduma' : 'Services',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionCard(
                icon: Icons.location_on_rounded,
                label: _isSwahili ? 'Kituo Karibu' : 'Nearest Station',
                onTap: () => _nav(const StationFinderPage()),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.edit_note_rounded,
                label: _isSwahili ? 'Ripoti Tukio' : 'Report Crime',
                onTap: () => _nav(const ReportCrimePage()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionCard(
                icon: Icons.folder_rounded,
                label: _isSwahili ? 'Ripoti Zangu' : 'My Reports',
                onTap: () => _nav(const MyReportsPage()),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.phone_in_talk_rounded,
                label: _isSwahili ? 'Piga Polisi' : 'Call Police',
                onTap: _callEmergency,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Emergency Numbers
          Text(
            _isSwahili ? 'Nambari za Dharura' : 'Emergency Numbers',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          _EmergencyNumberTile(
              number: '112',
              label: _isSwahili ? 'Dharura Yote' : 'General Emergency'),
          _EmergencyNumberTile(
              number: '114',
              label: _isSwahili ? 'Polisi' : 'Police'),
          _EmergencyNumberTile(
              number: '199',
              label: _isSwahili ? 'Zimamoto' : 'Fire'),
          _EmergencyNumberTile(
              number: '115',
              label: _isSwahili ? 'Ambulansi' : 'Ambulance'),
          const SizedBox(height: 24),
        ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: _kPrimary, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyNumberTile extends StatelessWidget {
  final String number;
  final String label;
  const _EmergencyNumberTile({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, size: 18, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: number);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

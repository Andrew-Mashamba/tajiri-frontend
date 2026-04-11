// lib/alerts/pages/alerts_home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/alerts_models.dart';
import '../services/alerts_service.dart';
import '../widgets/emergency_alert_card.dart';
import 'family_checkin_page.dart';
import 'alert_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AlertsHomePage extends StatefulWidget {
  final int userId;
  const AlertsHomePage({super.key, required this.userId});
  @override
  State<AlertsHomePage> createState() => _AlertsHomePageState();
}

class _AlertsHomePageState extends State<AlertsHomePage> {
  List<EmergencyAlert> _alerts = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await AlertsService.getAlerts();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) {
        _alerts = r.items;
      }
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili ? 'Imeshindwa kupakia' : 'Failed to load')),
      ));
    }
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _checkIn(String status) async {
    final r = await AlertsService.checkIn(status: status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.success
          ? (_isSwahili ? 'Umejisajili!' : 'Checked in!')
          : (r.message ?? 'Error')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = _alerts.where((a) => a.isActive).toList();

    if (_isLoading) {
      return const Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    return RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Quick check-in
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSwahili ? 'Jiripoti Hali' : 'Check In',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CheckInBtn(
                                label: _isSwahili ? 'Niko Salama' : 'I\'m Safe',
                                color: Colors.green,
                                icon: Icons.check_circle_rounded,
                                onTap: () => _checkIn('safe'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CheckInBtn(
                                label: _isSwahili
                                    ? 'Nahitaji Msaada'
                                    : 'Need Help',
                                color: Colors.red,
                                icon: Icons.sos_rounded,
                                onTap: () => _checkIn('need_help'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Emergency call button
                  GestureDetector(
                    onTap: _callEmergency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            _isSwahili
                                ? 'Piga Dharura 112'
                                : 'Call Emergency 112',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Family check-in button
                  GestureDetector(
                    onTap: () =>
                        _nav(FamilyCheckInPage(userId: widget.userId)),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.family_restroom_rounded,
                              color: _kPrimary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isSwahili
                                  ? 'Angalia Familia'
                                  : 'Family Check-in',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _kPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: _kSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active alerts
                  if (activeAlerts.isNotEmpty) ...[
                    Text(
                      _isSwahili
                          ? 'Tahadhari Zinazoendelea'
                          : 'Active Alerts',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                    const SizedBox(height: 10),
                    ...activeAlerts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EmergencyAlertCard(
                            alert: a,
                            isSwahili: _isSwahili,
                            onTap: () => _nav(AlertDetailPage(alert: a)),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // All alerts
                  Text(
                    _isSwahili ? 'Tahadhari Zote' : 'All Alerts',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 48, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                            _isSwahili
                                ? 'Hakuna tahadhari'
                                : 'No alerts',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                          ),
                        ]),
                      ),
                    )
                  else
                    ..._alerts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EmergencyAlertCard(
                            alert: a,
                            isSwahili: _isSwahili,
                            onTap: () => _nav(AlertDetailPage(alert: a)),
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
    );
  }
}

class _CheckInBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _CheckInBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

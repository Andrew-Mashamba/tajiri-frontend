// lib/neighbourhood_watch/pages/neighbourhood_watch_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/neighbourhood_watch_models.dart';
import '../services/neighbourhood_watch_service.dart';
import '../widgets/alert_card.dart';
import 'report_incident_page.dart';
import 'patrol_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class NeighbourhoodWatchHomePage extends StatefulWidget {
  final int userId;
  const NeighbourhoodWatchHomePage({super.key, required this.userId});
  @override
  State<NeighbourhoodWatchHomePage> createState() =>
      _NeighbourhoodWatchHomePageState();
}

class _NeighbourhoodWatchHomePageState
    extends State<NeighbourhoodWatchHomePage> {
  List<CommunityAlert> _alerts = [];
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
    final r = await NeighbourhoodWatchService.getAlerts();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _alerts = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia tahadhari'
                : 'Failed to load alerts')),
      ));
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _load,
            color: _kPrimary,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  // Quick actions
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.warning_rounded,
                        label:
                            _isSwahili ? 'Ripoti Tukio' : 'Report Incident',
                        onTap: () => _nav(const ReportIncidentPage()),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.shield_rounded,
                        label: _isSwahili ? 'Doria' : 'Patrols',
                        onTap: () => _nav(const PatrolPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Active alerts count
                  if (_alerts.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_alerts.where((a) => a.isActive).length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _isSwahili
                                      ? 'Tahadhari zinazoendelea'
                                      : 'Active alerts',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    _isSwahili ? 'Tahadhari' : 'Alerts',
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
                                ? 'Mtaa uko salama'
                                : 'Neighbourhood is safe',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                          ),
                        ]),
                      ),
                    )
                  else
                    ..._alerts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AlertCard(
                            alert: a,
                            isSwahili: _isSwahili,
                            onConfirm: () async {
                              final result =
                                  await NeighbourhoodWatchService
                                      .confirmAlert(a.id);
                              if (!mounted) return;
                              if (!result.success) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(result.message ??
                                      (_isSwahili
                                          ? 'Imeshindwa kuthibitisha'
                                          : 'Failed to confirm')),
                                ));
                              }
                              _load();
                            },
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Icon(icon, color: _kPrimary, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

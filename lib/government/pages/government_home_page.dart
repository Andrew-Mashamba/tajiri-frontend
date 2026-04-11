// lib/government/pages/government_home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/government_models.dart';
import '../services/government_service.dart';
import '../widgets/govt_service_card.dart';
import 'nida_page.dart';
import 'tra_page.dart';
import 'brela_page.dart';
import 'nssf_page.dart';
import 'nhif_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class GovernmentHomePage extends StatefulWidget {
  final int userId;
  const GovernmentHomePage({super.key, required this.userId});
  @override
  State<GovernmentHomePage> createState() => _GovernmentHomePageState();
}

class _GovernmentHomePageState extends State<GovernmentHomePage> {
  final GovernmentService _service = GovernmentService();

  List<GovtQuery> _recentQueries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final queriesResult = await _service.getMyQueries(userId: widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (queriesResult.success) _recentQueries = queriesResult.items;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.assured_workload_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Huduma za Serikali',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fikia huduma za serikali moja kwa moja kutoka kwenye programu.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.badge_rounded,
                  label: 'NIDA',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NidaPage(userId: widget.userId)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'TRA',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TraPage(userId: widget.userId)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.business_rounded,
                  label: 'BRELA',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BrelaPage(userId: widget.userId)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.shield_rounded,
                  label: 'NSSF',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NssfPage(userId: widget.userId)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.health_and_safety_rounded,
                  label: 'NHIF',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NhifPage(userId: widget.userId)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.landscape_rounded,
                  label: 'e-Ardhi',
                  onTap: () => _openUrl('https://ardhi.go.tz'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Service categories
          const Text(
            'Makundi ya Huduma',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: GovtServiceCategory.values.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _navigateToCategory(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: _kSecondary),
                          const SizedBox(width: 6),
                          Text(
                            cat.displayName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Quick links to portals
          const Text(
            'Viungo vya Haraka',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          GovtServiceCard(
            icon: Icons.badge_rounded,
            title: 'NIDA - Kitambulisho cha Taifa',
            subtitle: 'Uthibitisho wa NIDA, hali ya kitambulisho',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NidaPage(userId: widget.userId))),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.receipt_long_rounded,
            title: 'TRA - Mamlaka ya Mapato',
            subtitle: 'Utafutaji wa TIN, hali ya kodi',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TraPage(userId: widget.userId))),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.business_rounded,
            title: 'BRELA - Usajili wa Biashara',
            subtitle: 'Tafuta na usajili jina la biashara',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BrelaPage(userId: widget.userId))),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.shield_rounded,
            title: 'NSSF - Mfuko wa Hifadhi',
            subtitle: 'Hali ya michango, kihesabu',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NssfPage(userId: widget.userId))),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.health_and_safety_rounded,
            title: 'NHIF - Bima ya Afya',
            subtitle: 'Hali ya uanachama, madai',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NhifPage(userId: widget.userId))),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.school_rounded,
            title: 'NECTA - Matokeo ya Mitihani',
            subtitle: 'Matokeo ya CSEE, ACSEE, QT',
            onTap: () => _openUrl('https://www.necta.go.tz/results'),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.landscape_rounded,
            title: 'e-Ardhi - Ardhi',
            subtitle: 'Umiliki wa ardhi, hati miliki',
            onTap: () => _openUrl('https://ardhi.go.tz'),
          ),
          const SizedBox(height: 8),
          GovtServiceCard(
            icon: Icons.flight_rounded,
            title: 'Pasipoti / Immigration',
            subtitle: 'Ombi la pasipoti, visa, vibali',
            onTap: () => _openUrl('https://www.immigration.go.tz'),
          ),
          const SizedBox(height: 20),

          // Recent queries
          if (_recentQueries.isNotEmpty) ...[
            const Text(
              'Maswali ya Hivi Karibuni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            ..._recentQueries.take(5).map((q) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: q.isSuccess
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          q.isSuccess ? Icons.check_circle_rounded : Icons.pending_rounded,
                          size: 18,
                          color: q.isSuccess ? const Color(0xFF4CAF50) : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.serviceType.toUpperCase(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                            ),
                            Text(
                              q.query,
                              style: const TextStyle(fontSize: 12, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${q.createdAt.day}/${q.createdAt.month}',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _navigateToCategory(GovtServiceCategory category) {
    switch (category) {
      case GovtServiceCategory.identity:
        Navigator.push(context, MaterialPageRoute(builder: (_) => NidaPage(userId: widget.userId)));
      case GovtServiceCategory.tax:
        Navigator.push(context, MaterialPageRoute(builder: (_) => TraPage(userId: widget.userId)));
      case GovtServiceCategory.business:
        Navigator.push(context, MaterialPageRoute(builder: (_) => BrelaPage(userId: widget.userId)));
      case GovtServiceCategory.socialSecurity:
        Navigator.push(context, MaterialPageRoute(builder: (_) => NssfPage(userId: widget.userId)));
      case GovtServiceCategory.health:
        Navigator.push(context, MaterialPageRoute(builder: (_) => NhifPage(userId: widget.userId)));
      case GovtServiceCategory.land:
        _openUrl('https://ardhi.go.tz');
      case GovtServiceCategory.education:
        _openUrl('https://www.necta.go.tz/results');
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

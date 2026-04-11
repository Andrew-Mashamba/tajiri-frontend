// lib/traffic/pages/traffic_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/traffic_models.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_report_card.dart';
import '../widgets/congestion_banner.dart';
import 'submit_report_page.dart';
import 'congestion_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class TrafficHomePage extends StatefulWidget {
  final int userId;
  const TrafficHomePage({super.key, required this.userId});
  @override
  State<TrafficHomePage> createState() => _TrafficHomePageState();
}

class _TrafficHomePageState extends State<TrafficHomePage> {
  List<TrafficReport> _reports = [];
  List<CongestionAlert> _congestion = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      TrafficService.getFeed(),
      TrafficService.getCongestionAlerts(),
    ]);
    if (!mounted) return;
    final reportResult = results[0] as PaginatedResult<TrafficReport>;
    final congResult = results[1] as PaginatedResult<CongestionAlert>;
    setState(() {
      _isLoading = false;
      if (reportResult.success) _reports = reportResult.items;
      if (congResult.success) _congestion = congResult.items;
    });
    if (!reportResult.success && !congResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imeshindwa kupakia data'
            : 'Failed to load data'),
      ));
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  // Congestion alerts
                  if (_congestion.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isSwahili ? 'Msongamano Sasa' : 'Live Congestion',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        GestureDetector(
                          onTap: () => _nav(const CongestionPage()),
                          child: Text(
                            _isSwahili ? 'Zote' : 'See all',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._congestion.take(3).map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: CongestionBanner(
                              alert: a, isSwahili: _isSwahili),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Quick report
                  GestureDetector(
                    onTap: () => _nav(const SubmitReportPage()),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isSwahili
                                  ? 'Ripoti hali ya barabara'
                                  : 'Report traffic situation',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Live feed
                  Text(
                    _isSwahili ? 'Habari za Trafiki' : 'Traffic Feed',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_reports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          _isSwahili
                              ? 'Hakuna ripoti kwa sasa'
                              : 'No reports yet',
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary),
                        ),
                      ),
                    )
                  else
                    ..._reports.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TrafficReportCard(
                            report: r,
                            isSwahili: _isSwahili,
                            onUpvote: () async {
                              final result =
                                  await TrafficService.upvoteReport(r.id);
                              if (!mounted) return;
                              if (!result.success) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(result.message ??
                                      (_isSwahili
                                          ? 'Imeshindwa'
                                          : 'Failed')),
                                ));
                              }
                              _loadData();
                            },
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }
}

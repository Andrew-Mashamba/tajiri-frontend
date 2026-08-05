import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

import '../../../services/local_storage_service.dart';
import '../../ads/campaigns/campaign_manager.dart';

// DESIGN.md — monochrome
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);

/// Lists seller ad campaigns from `GET /shop/ads/campaigns`.
class AdCampaignsScreen extends StatefulWidget {
  const AdCampaignsScreen({super.key});

  @override
  State<AdCampaignsScreen> createState() => _AdCampaignsScreenState();
}

class _AdCampaignsScreenState extends State<AdCampaignsScreen> {
  final CampaignManager _campaigns = CampaignManager();

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = await LocalStorageService.getInstance();
    final uid = storage.getUser()?.userId;
    if (!mounted) return;
    setState(() => _userId = uid);
    await _load();
  }

  Future<void> _load() async {
    final uid = _userId;
    setState(() {
      _loading = true;
      _error = null;
    });
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sign in to view ad campaigns.';
      });
      return;
    }
    try {
      final list = await _campaigns.loadCampaigns(userId: uid);
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _title(Map<String, dynamic> c) {
    final n = c['name'] ?? c['title'] ?? c['campaign_name'];
    if (n != null && n.toString().isNotEmpty) return n.toString();
    final id = c['id'];
    return id != null ? 'Campaign #$id' : 'Campaign';
  }

  String? _subtitle(Map<String, dynamic> c) {
    final status = c['status'] ?? c['state'];
    final budget = c['budget'] ?? c['daily_budget'] ?? c['budget_minor_units'];
    final parts = <String>[];
    if (status != null) parts.add(status.toString());
    if (budget != null) parts.add('Budget: $budget');
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kText),
        title: const Text(
          'Ad campaigns',
          style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: _kMuted),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _load,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kText,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    )
                  : _rows.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text(
                                'No campaigns yet.\nCreate one from seller tools when available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _kMuted, fontSize: 15),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _rows.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final c = _rows[i];
                            final sub = _subtitle(c);
                            return Material(
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                title: Text(
                                  _title(c),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: sub != null
                                    ? Text(
                                        sub,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: _kMuted, fontSize: 13),
                                      )
                                    : null,
                                leading: const HeroIcon(HeroIcons.megaphone, color: _kText),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

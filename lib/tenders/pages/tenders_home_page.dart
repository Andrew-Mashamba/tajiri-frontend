// Tenders (Zabuni) Dashboard -- main entry screen
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';
import '../widgets/tender_card.dart';
import 'browse_tenders_page.dart';
import 'my_applications_page.dart';
import 'institutions_page.dart';
import 'post_tender_page.dart';
import 'tender_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kWarning = Color(0xFFE65100);

class TendersHomePage extends StatefulWidget {
  final int userId;
  const TendersHomePage({super.key, required this.userId});

  @override
  State<TendersHomePage> createState() => _TendersHomePageState();
}

class _TendersHomePageState extends State<TendersHomePage> {
  bool _isLoading = true;
  String? _error;
  TenderStats _stats = const TenderStats();
  List<Tender> _closingSoon = [];
  List<Tender> _newTenders = [];

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        TenderService.getStats(),
        TenderService.getTenders(status: 'active'),
      ]);

      final statsResult = results[0] as TenderResult<TenderStats>;
      final tendersResult = results[1] as TenderListResult;

      if (mounted) {
        setState(() {
          if (statsResult.success && statsResult.data != null) {
            _stats = statsResult.data!;
          }
          if (tendersResult.success) {
            final all = tendersResult.tenders;
            _closingSoon = all.where((t) => t.isClosingSoon).toList()
              ..sort((a, b) => (a.daysRemaining).compareTo(b.daysRemaining));
            _newTenders = all.where((t) => !t.isClosed).toList()
              ..sort((a, b) {
                final aDate = a.publishedDate ?? DateTime(2000);
                final bDate = b.publishedDate ?? DateTime(2000);
                return bDate.compareTo(aDate);
              });
            if (_newTenders.length > 10) _newTenders = _newTenders.sublist(0, 10);
          } else if (tendersResult.error != null) {
            _error = tendersResult.error;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _isSwahili
              ? 'Imeshindwa kuunganisha na seva'
              : 'Failed to connect to server';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBackground,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadData,
                        style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                        child: Text(_isSwahili ? 'Jaribu Tena' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _kPrimary,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      const SizedBox(height: 16),
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      if (_closingSoon.isNotEmpty) ...[
                        _buildSectionHeader(
                          _isSwahili ? 'Zinaisha Hivi Karibuni' : 'Closing Soon',
                          icon: Icons.timer_rounded,
                          iconColor: _kWarning,
                          onSeeAll: () => _navigateTo(const BrowseTendersPage()),
                        ),
                        const SizedBox(height: 8),
                        ..._closingSoon.take(5).map((t) => TenderCard(
                          tender: t,
                          onTap: () => _navigateTo(TenderDetailPage(tenderId: t.tenderId)),
                        )),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionHeader(
                        _isSwahili ? 'Zabuni Mpya' : 'New Tenders',
                        icon: Icons.fiber_new_rounded,
                        onSeeAll: () => _navigateTo(const BrowseTendersPage()),
                      ),
                      const SizedBox(height: 8),
                      if (_newTenders.isEmpty)
                        _buildEmptyState(
                            _isSwahili
                                ? 'Hakuna zabuni mpya kwa sasa'
                                : 'No new tenders at the moment')
                      else
                        ..._newTenders.map((t) => TenderCard(
                          tender: t,
                          onTap: () => _navigateTo(TenderDetailPage(tenderId: t.tenderId)),
                        )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
              _isSwahili ? 'Hai' : 'Active',
              '${_stats.totalActive}',
              Icons.description_rounded),
          const SizedBox(width: 10),
          _buildStatCard(
              _isSwahili ? 'Zinaisha' : 'Closing',
              '${_stats.totalClosingSoon}',
              Icons.timer_rounded,
              highlight: true),
          const SizedBox(width: 10),
          _buildStatCard(
              _isSwahili ? 'Maombi' : 'Applied',
              '${_stats.totalApplications}',
              Icons.send_rounded),
          const SizedBox(width: 10),
          _buildStatCard(
              _isSwahili ? 'Taasisi' : 'Institutions',
              '${_stats.totalInstitutions}',
              Icons.business_rounded),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: highlight ? _kWarning.withValues(alpha: 0.08) : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: highlight ? Border.all(color: _kWarning.withValues(alpha: 0.2)) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: highlight ? _kWarning : _kSecondary),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: highlight ? _kWarning : _kPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: highlight ? _kWarning.withValues(alpha: 0.8) : _kSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildActionButton(
              _isSwahili ? 'Tazama Zabuni' : 'Browse',
              Icons.search_rounded,
              () => _navigateTo(const BrowseTendersPage())),
          const SizedBox(width: 10),
          _buildActionButton(
              _isSwahili ? 'Maombi Yangu' : 'My Applications',
              Icons.folder_open_rounded,
              () => _navigateTo(const MyApplicationsPage())),
          const SizedBox(width: 10),
          _buildActionButton(
              _isSwahili ? 'Taasisi' : 'Institutions',
              Icons.business_rounded,
              () => _navigateTo(const InstitutionsPage())),
          const SizedBox(width: 10),
          _buildActionButton(
              _isSwahili ? 'Chapisha' : 'Post',
              Icons.add_circle_outline_rounded,
              () => _navigateTo(const PostTenderPage())),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, Color? iconColor, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? _kPrimary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                _isSwahili ? 'Tazama zote' : 'See all',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, color: _kSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

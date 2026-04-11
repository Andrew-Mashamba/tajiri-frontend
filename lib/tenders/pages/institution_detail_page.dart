// Single institution detail -- name, info, active tenders, follow
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';
import '../widgets/tender_card.dart';
import 'tender_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InstitutionDetailPage extends StatefulWidget {
  final String slug;
  final Institution? institution;

  const InstitutionDetailPage({super.key, required this.slug, this.institution});

  @override
  State<InstitutionDetailPage> createState() => _InstitutionDetailPageState();
}

class _InstitutionDetailPageState extends State<InstitutionDetailPage> {
  Institution? _institution;
  List<Tender> _tenders = [];
  bool _isLoading = true;
  bool _tendersLoading = true;
  bool _isFollowed = false;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _institution = widget.institution;
    _isFollowed = widget.institution?.isFollowed ?? false;
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      TenderService.getInstitutionDetail(widget.slug),
      TenderService.getTenders(institutionSlug: widget.slug, status: 'active'),
    ]);

    final instResult = results[0] as TenderResult<Institution>;
    final tendersResult = results[1] as TenderListResult;

    if (mounted) {
      setState(() {
        _isLoading = false;
        _tendersLoading = false;
        if (instResult.success && instResult.data != null) {
          _institution = instResult.data;
          _isFollowed = instResult.data!.isFollowed;
        }
        if (tendersResult.success) {
          _tenders = tendersResult.tenders
            ..sort((a, b) => (a.daysRemaining).compareTo(b.daysRemaining));
        }
      });
    }
  }

  Future<void> _toggleFollow() async {
    final wasFollowed = _isFollowed;
    setState(() => _isFollowed = !wasFollowed);

    final result = wasFollowed
        ? await TenderService.unfollowInstitution(widget.slug)
        : await TenderService.followInstitution(widget.slug);

    if (!result.success && mounted) {
      setState(() => _isFollowed = wasFollowed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Imeshindwa'), backgroundColor: const Color(0xFFD32F2F)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inst = _institution;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          inst?.name ?? (_isSwahili ? 'Taasisi' : 'Institution'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
      ),
      body: _isLoading && inst == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (inst != null) ...[
                    // Header card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Initials avatar
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                _initials(inst.name),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            inst.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inst.category.label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStat(
                                _isSwahili ? 'Zabuni Hai' : 'Active Tenders',
                                '${inst.activeTenders}'),
                              Container(
                                width: 1,
                                height: 24,
                                color: const Color(0xFFE0E0E0),
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              _buildStat(
                                _isSwahili ? 'Mwisho Kuchukuliwa' : 'Last Scraped',
                                inst.lastScraped != null
                                    ? _formatDate(inst.lastScraped!)
                                    : (_isSwahili ? 'Haijulikani' : 'Unknown'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Follow button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: _isFollowed
                                ? OutlinedButton(
                                    onPressed: _toggleFollow,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: _kPrimary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      _isSwahili ? 'Unafuatilia' : 'Following',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                    ),
                                  )
                                : FilledButton(
                                    onPressed: _toggleFollow,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      _isSwahili ? 'Fuatilia Taasisi' : 'Follow Institution',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                          ),

                          // Website link
                          if (inst.tenderUrl != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _openUrl(inst.tenderUrl!),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.open_in_new_rounded, size: 14, color: _kSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    inst.domain ?? 'Tovuti',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kSecondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Active tenders
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      _isSwahili ? 'Zabuni Hai (${_tenders.length})' : 'Active Tenders (${_tenders.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ),

                  if (_tendersLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                    )
                  else if (_tenders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          _isSwahili ? 'Hakuna zabuni hai kwa sasa' : 'No active tenders at this time',
                          style: TextStyle(fontSize: 14, color: _kSecondary.withValues(alpha: 0.7)),
                        ),
                      ),
                    )
                  else
                    ..._tenders.map((t) => TenderCard(
                      tender: t,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TenderDetailPage(tenderId: t.tenderId)),
                      ),
                    )),
                ],
              ),
            ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ],
    );
  }

  String _initials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../models/beneficiary_org.dart';
import '../models/food_preferences.dart';
import '../models/food_season.dart';
import '../services/food_service.dart';
import 'beneficiary_profile_page.dart';
import 'cash_donation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SeasonalFeedingPage extends StatefulWidget {
  final int userId;
  final FoodSeason season;
  const SeasonalFeedingPage({super.key, required this.userId, required this.season});

  @override
  State<SeasonalFeedingPage> createState() => _SeasonalFeedingPageState();
}

class _SeasonalFeedingPageState extends State<SeasonalFeedingPage> {
  final FoodService _service = FoodService();
  List<Map<String, dynamic>> _needs = const [];
  FoodPreferences? _prefs;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final res = await _service.getFoodPreferences(userId: widget.userId);
    if (!mounted || !res.success || res.data == null) return;
    setState(() => _prefs = res.data);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final res = await _service.listBeneficiaryNeeds(
      type: widget.season.beneficiaryTypeFilter,
      limit: 100,
    );
    if (!mounted) return;
    if (res.success) {
      setState(() {
        _needs = res.items;
        _loading = false;
      });
    } else {
      setState(() {
        _loadError = res.message ?? 'Imeshindwa kupakia';
        _loading = false;
      });
    }
  }

  Color get _seasonColor {
    switch (widget.season) {
      case FoodSeason.ramadhan:
        return const Color(0xFF2E7D32);
      case FoodSeason.christmas:
        return const Color(0xFFC62828);
      case FoodSeason.easter:
        return const Color(0xFF6A1B9A);
      case FoodSeason.sundayFunguLaKumi:
        return const Color(0xFF1565C0);
      case FoodSeason.none:
        return _kPrimary;
    }
  }

  void _openOrg(int orgId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeneficiaryProfilePage(orgId: orgId, userId: widget.userId),
      ),
    ).then((_) => _load());
  }

  bool get _seasonZakaDefault => widget.season == FoodSeason.ramadhan;
  bool get _seasonFunguDefault =>
      widget.season == FoodSeason.christmas ||
      widget.season == FoodSeason.easter ||
      widget.season == FoodSeason.sundayFunguLaKumi;

  bool get _autoZaka =>
      _prefs?.resolveAutoTagZakat(seasonDefault: _seasonZakaDefault) ??
      _seasonZakaDefault;
  bool get _autoFungu =>
      _prefs?.resolveAutoTagFungu(seasonDefault: _seasonFunguDefault) ??
      _seasonFunguDefault;

  Future<void> _openMoneyPledge(int orgId) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await _service.getBeneficiaryOrg(orgId);
    if (!mounted) return;
    if (!result.success || result.data == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kupakia shirika')),
      );
      return;
    }
    final org = result.data!['org'] as BeneficiaryOrg?;
    if (org == null) return;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => CashDonationPage(
          userId: widget.userId,
          org: org,
          prefillZaka: _autoZaka,
          prefillFungu: _autoFungu,
        ),
      ),
    );
    if (mounted) _load();
  }

  String get _autoTagLabel {
    if (_autoZaka) return 'Itahesabiwa kama Zakat';
    if (_autoFungu) return 'Itahesabiwa kama Fungu la Kumi';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: Text(
          widget.season.titleSwahili,
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _headerCard(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
              )
            else if (_loadError != null)
              _errorBlock()
            else if (_needs.isEmpty)
              _emptyBlock()
            else
              ..._needs.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _needCard(n),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _seasonColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _seasonColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _seasonColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.season.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.season.titleSwahili,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _seasonColor),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.season.subtitleSwahili,
                  style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.3),
                ),
                if (_autoTagLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _seasonColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_rounded, size: 11, color: _seasonColor),
                        const SizedBox(width: 4),
                        Text(
                          _autoTagLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _seasonColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: _kSecondary),
          const SizedBox(height: 12),
          Text(_loadError!, style: const TextStyle(fontSize: 13, color: _kSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Jaribu tena')),
        ],
      ),
    );
  }

  Widget _emptyBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Hakuna mahitaji ya wazi kwa sasa',
            style: TextStyle(fontSize: 13, color: _kSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _needCard(Map<String, dynamic> need) {
    final title = need['title']?.toString() ?? 'Hitaji';
    final desc = need['description']?.toString() ?? '';
    final portionsNeeded = (need['portions_needed'] is num)
        ? (need['portions_needed'] as num).toInt()
        : int.tryParse('${need['portions_needed']}') ?? 0;
    final portionsFulfilled = (need['portions_fulfilled'] is num)
        ? (need['portions_fulfilled'] as num).toInt()
        : int.tryParse('${need['portions_fulfilled']}') ?? 0;
    final progress = portionsNeeded == 0 ? 0.0 : (portionsFulfilled / portionsNeeded).clamp(0.0, 1.0);
    final orgName = need['org_name']?.toString() ?? 'Shirika';
    final orgType = BeneficiaryOrgTypeX.fromString(need['org_type']?.toString());
    final orgWard = need['org_ward']?.toString() ?? '';
    final orgDistrict = need['org_district']?.toString() ?? '';
    final orgPhotoUrl = need['org_photo_url']?.toString();
    final orgId = (need['org_id'] is num)
        ? (need['org_id'] as num).toInt()
        : int.tryParse('${need['org_id']}') ?? 0;

    final photoUrl = (orgPhotoUrl == null || orgPhotoUrl.isEmpty)
        ? ''
        : (orgPhotoUrl.startsWith('http')
            ? (ApiConfig.sanitizeUrl(orgPhotoUrl) ?? '')
            : (ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$orgPhotoUrl') ?? ''));
    final locParts = [orgWard, orgDistrict].where((p) => p.trim().isNotEmpty).toList();
    final location = locParts.join(', ');

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openOrg(orgId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: photoUrl.isEmpty
                          ? Container(
                              color: _seasonColor.withValues(alpha: 0.08),
                              child: Icon(Icons.volunteer_activism_rounded, color: _seasonColor, size: 22),
                            )
                          : CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                color: _seasonColor.withValues(alpha: 0.08),
                                child: Icon(Icons.volunteer_activism_rounded, color: _seasonColor, size: 22),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${orgType.labelSwahili}${location.isEmpty ? '' : ' • $location'}',
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(_seasonColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$portionsFulfilled / $portionsNeeded milo',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openOrg(orgId),
                      icon: const Icon(Icons.restaurant_rounded, size: 15),
                      label: const Text('Toa milo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _seasonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMoneyPledge(orgId),
                      icon: Icon(Icons.payments_rounded, size: 15, color: _seasonColor),
                      label: Text('Toa pesa',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _seasonColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _seasonColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

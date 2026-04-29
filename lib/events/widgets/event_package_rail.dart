import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../pages/partner_product_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);

/// Horizontal rail of partner_products in the events cluster (spec §10 line 955).
/// Shows up to 12 active packages from `tourGuide`/`safariOperator`/`djing`/`mc`/
/// `travelAgent`/`eventPlanning` skills. Hides itself when empty or on error.
class EventPackageRail extends StatefulWidget {
  final int? userId;
  /// When true, the rail adds its own horizontal page padding. Set false when
  /// embedding into a parent that already pads its children.
  final bool padded;
  const EventPackageRail({super.key, this.userId, this.padded = true});

  @override
  State<EventPackageRail> createState() => _EventPackageRailState();
}

class _EventPackageRailState extends State<EventPackageRail> {
  bool _loading = true;
  List<PartnerProduct> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await PartnerProductService.listProducts(
      activeOnly: true,
      limit: 12,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.products
          .where((p) => _eventsCluster(p.skillCategory))
          .toList();
    });
  }

  bool _eventsCluster(SkillCategory? s) {
    if (s == null) return false;
    return s == SkillCategory.tourGuide
        || s == SkillCategory.safariOperator
        || s == SkillCategory.djing
        || s == SkillCategory.mc
        || s == SkillCategory.travelAgent
        || s == SkillCategory.eventPlanning;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();
    final hPad = widget.padded ? 16.0 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
          child: Row(
            children: [
              const Icon(Icons.celebration_rounded, size: 18, color: _kPrimary),
              const SizedBox(width: 6),
              Text(
                _isSwahili ? 'Pakeji za Hafla' : 'Event Packages',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _packageCard(_items[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _packageCard(PartnerProduct p) {
    final cover = p.photos.isNotEmpty ? _resolve(p.photos.first.photoUrl) : '';
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PartnerProductDetailPage(productId: p.id, initial: p),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: cover.isEmpty
                    ? Container(
                        color: _kPrimary.withValues(alpha: 0.06),
                        child: Icon(p.skillCategory?.icon ?? Icons.celebration_rounded,
                            size: 36, color: _kMuted),
                      )
                    : Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _kPrimary.withValues(alpha: 0.06),
                          child: Icon(p.skillCategory?.icon ?? Icons.celebration_rounded,
                              size: 36, color: _kMuted),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.partnerName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: _kMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${NumberFormat('#,##0', 'en_US').format(p.basePriceTzs)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolve(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return ApiConfig.sanitizeUrl(raw) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$raw') ?? '';
  }
}

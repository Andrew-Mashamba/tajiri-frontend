import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/services/partner_product_service.dart';
import 'book_event_package_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Per-vertical detail page for an events-cluster partner_product (spec §10
/// line 951). Mirrors F2's detail layout but routes the CTA to
/// [BookEventPackagePage] (deposit-required date-locked flow) instead of the
/// generic same-day order sheet.
class PartnerProductDetailPage extends StatefulWidget {
  final int productId;
  final PartnerProduct? initial;

  const PartnerProductDetailPage({
    super.key,
    required this.productId,
    this.initial,
  });

  @override
  State<PartnerProductDetailPage> createState() => _PartnerProductDetailPageState();
}

class _PartnerProductDetailPageState extends State<PartnerProductDetailPage> {
  PartnerProduct? _p;
  bool _loading = true;
  String? _error;
  int? _userId;
  int _photoIndex = 0;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _p = widget.initial;
    _loading = widget.initial == null;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = await LocalStorageService.getInstance();
    _userId = storage.getUser()?.userId;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = _p == null;
      _error = null;
    });
    final res = await PartnerProductService.getProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.product != null) {
        _p = res.product;
      } else if (_p == null) {
        _error = res.message ?? 'Imeshindikana kupakua pakeji';
      }
    });
  }

  Future<void> _book() async {
    final p = _p;
    if (p == null) return;
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Tafadhali ingia kwanza' : 'Please sign in first'),
      ));
      return;
    }
    if (_userId == p.partnerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Huwezi kuhifadhi pakeji yako mwenyewe'
            : "You can't book your own package"),
      ));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookEventPackagePage(
          customerUserId: _userId!,
          package: p,
        ),
      ),
    );
  }

  String _fmt(int v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          p?.title ?? (_isSwahili ? 'Pakeji' : 'Package'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading && p == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null && p == null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : p == null
                  ? Center(
                      child: Text(_isSwahili ? 'Hapatikani' : 'Not found',
                          style: const TextStyle(color: _kMuted)),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _carousel(p),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _headerCard(p),
                                const SizedBox(height: 10),
                                _partnerCard(p),
                                const SizedBox(height: 10),
                                if (p.description.isNotEmpty) _descCard(p),
                                if (p.tags.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _tagsCard(p),
                                ],
                                const SizedBox(height: 10),
                                _depositHintCard(p),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: p == null ? null : _bottomBar(p),
    );
  }

  Widget _carousel(PartnerProduct p) {
    final urls = p.photos
        .map((ph) => _resolve(ph.photoUrl))
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) {
      return Container(
        height: 220,
        color: _kPrimary.withValues(alpha: 0.06),
        child: Icon(p.skillCategory?.icon ?? Icons.celebration_rounded,
            size: 64, color: _kMuted),
      );
    }
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (_, i) => Image.network(
              urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: _kPrimary.withValues(alpha: 0.06),
                child: Icon(p.skillCategory?.icon ?? Icons.celebration_rounded,
                    size: 48, color: _kMuted),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final on = i == _photoIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: on ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCard(PartnerProduct p) {
    return _card([
      Row(
        children: [
          Icon(p.skillCategory?.icon ?? Icons.celebration_rounded, size: 18, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              p.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'TZS ${_fmt(p.basePriceTzs)}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kPrimary),
      ),
      if (!p.isActive) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _isSwahili ? 'Pakeji haipatikani' : 'Package unavailable',
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB71C1C)),
          ),
        ),
      ],
    ]);
  }

  Widget _partnerCard(PartnerProduct p) {
    return _card([
      Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _kPrimary.withValues(alpha: 0.06),
            child: Text(
              (p.partnerName ?? '?').characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.partnerName ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text(
                  p.skillCategory?.label ?? p.skillCategoryRaw,
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _descCard(PartnerProduct p) {
    return _card([
      Text(_isSwahili ? 'Maelezo' : 'Description',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 6),
      Text(p.description, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
    ]);
  }

  Widget _tagsCard(PartnerProduct p) {
    return _card([
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: p.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            )).toList(),
      ),
    ]);
  }

  Widget _depositHintCard(PartnerProduct p) {
    final deposit = (p.basePriceTzs / 2).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, size: 18, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSwahili ? 'Hifadhi tarehe na amana 50%' : 'Lock the date with 50% deposit',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSwahili
                      ? 'Amana ya makisio: TZS ${_fmt(deposit)}. Salio kabla ya hafla.'
                      : 'Estimated deposit: TZS ${_fmt(deposit)}. Balance pre-event.',
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(PartnerProduct p) {
    if (!p.isActive) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          child: Text(
            _isSwahili ? 'Pakeji hii haipatikani sasa' : 'This package is unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kMuted),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: ElevatedButton.icon(
          onPressed: _book,
          icon: const Icon(Icons.event_rounded, size: 16),
          label: Text(_isSwahili
              ? 'Hifadhi Tarehe — TZS ${_fmt(p.basePriceTzs)}'
              : 'Lock the Date — TZS ${_fmt(p.basePriceTzs)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  String _resolve(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return ApiConfig.sanitizeUrl(raw) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$raw') ?? '';
  }
}

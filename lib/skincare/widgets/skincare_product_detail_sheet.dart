import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../doctor/models/doctor_models.dart';
import '../../doctor/pages/find_doctor_page.dart';
import '../../shop/buyer/screens/shop_screen.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Bottom sheet: loads full product from API when possible (performance: avoid duplicate list fetches).
Future<void> showSkincareProductDetailSheet(
  BuildContext context, {
  required SkinProduct initial,
  int? userId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _kBackground,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => _SkincareProductDetailBody(
        initial: initial,
        scrollController: scrollController,
        userId: userId,
      ),
    ),
  );
}

class _SkincareProductDetailBody extends StatefulWidget {
  final SkinProduct initial;
  final ScrollController scrollController;
  final int? userId;

  const _SkincareProductDetailBody({
    required this.initial,
    required this.scrollController,
    this.userId,
  });

  @override
  State<_SkincareProductDetailBody> createState() => _SkincareProductDetailBodyState();
}

class _SkincareProductDetailBodyState extends State<_SkincareProductDetailBody> {
  final SkincareService _service = SkincareService();
  SkinProduct? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _product = widget.initial;
    _fetch();
  }

  Future<void> _fetch() async {
    final r = await _service.getProductDetail(widget.initial.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.data != null) {
        _product = r.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = _product ?? widget.initial;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
          ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.contain,
                    memCacheWidth: 600,
                    placeholder: (context, url) => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => const Icon(Icons.face_retouching_natural_rounded, size: 48, color: _kSecondary),
                  ),
                )
              : const Icon(Icons.face_retouching_natural_rounded, size: 48, color: _kSecondary),
        ),
        const SizedBox(height: 16),
        Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kPrimary)),
        if (product.brand != null) Text(product.brand!, style: const TextStyle(fontSize: 14, color: _kSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'TZS ${product.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            if (product.rating > 0) ...[
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
              const SizedBox(width: 2),
              Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Spacer(),
            if (product.isTmdaApproved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Color(0xFF4CAF50)),
                    SizedBox(width: 4),
                    Text('TMDA Imeidhinishwa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Makini: Matokeo ya bidhaa za ngozi yanaweza kuchukua wiki 4–8. Endelea kwa subira.',
          style: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.9), height: 1.4),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kwa nini mapendekezo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                product.concerns.isNotEmpty
                    ? 'Inalingana na wasiwasi ulioweka: ${product.concerns.map((c) => c.displayName).join(", ")}.'
                    : (product.description ??
                        'Inalingana na aina ya ngozi na orodha ya bidhaa kwenye katalogi.'),
                style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.4),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final storage = await LocalStorageService.getInstance();
                final uid = widget.userId ?? storage.getUser()?.userId ?? 0;
                if (uid <= 0 || !context.mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ShopScreen(
                      currentUserId: uid,
                      initialSearchQuery: '${product.category} ${product.brand ?? product.name}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.storefront_rounded, size: 18, color: _kPrimary),
              label: const Text('Duka', style: TextStyle(fontSize: 12, color: _kPrimary)),
            ),
            OutlinedButton.icon(
              onPressed: () => _promptLogSpend(context, product),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: _kPrimary),
              label: const Text('Bajeti', style: TextStyle(fontSize: 12, color: _kPrimary)),
            ),
            OutlinedButton.icon(
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${product.name} (${product.brand ?? ""}) — TZS ${product.price.toStringAsFixed(0)}. Viambato: ${product.ingredients.take(8).join(", ")}',
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18, color: _kPrimary),
              label: const Text('Shiriki', style: TextStyle(fontSize: 12, color: _kPrimary)),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final storage = await LocalStorageService.getInstance();
                final uid = widget.userId ?? storage.getUser()?.userId ?? 0;
                if (uid <= 0 || !context.mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => FindDoctorPage(
                      userId: uid,
                      initialSpecialty: MedicalSpecialty.dermatology,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.medical_services_outlined, size: 18, color: _kPrimary),
              label: const Text('Daktari', style: TextStyle(fontSize: 12, color: _kPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (product.description != null && product.description!.isNotEmpty) ...[
          Text(product.description!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5)),
          const SizedBox(height: 16),
        ],
        if (product.skinTypes.isNotEmpty) ...[
          const Text('Inafaa kwa:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: product.skinTypes.map((t) => Chip(
                  label: Text(t.displayName, style: const TextStyle(fontSize: 11)),
                  avatar: Icon(t.icon, size: 14),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (product.concerns.isNotEmpty) ...[
          const Text('Inasaidia:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: product.concerns.map((c) => Chip(
                  label: Text(c.displayName, style: const TextStyle(fontSize: 11)),
                  avatar: Icon(c.icon, size: 14),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (product.ingredients.isNotEmpty) ...[
          const Text('Viambato:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.ingredients.join(', '),
              style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.5),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _promptLogSpend(BuildContext context, SkinProduct product) async {
    final c = TextEditingController(
      text: product.price > 0 ? product.price.toStringAsFixed(0) : '',
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Matumizi — Urembo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Kiasi (TZS)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.replaceAll(',', ''))),
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
    c.dispose();
    if (amount == null || amount <= 0) return;
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;
    await ExpenditureService.recordExpenditure(
      token: token,
      amount: amount,
      category: 'urembo',
      description: 'Skincare: ${product.name}',
      sourceModule: 'skincare',
      referenceId: '${product.id}',
      envelopeTag: 'urembo',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeingia kwenye matumizi'), backgroundColor: _kPrimary),
      );
    }
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../widgets/cached_media_image.dart';
import '../models/partner_event_showcase.dart';
import '../services/partner_event_showcase_service.dart';

/// Spec F10 #88 — Customer-facing rail showing a partner's past events.
/// Mounted on the partner profile page for events / travel skill_categories.
class RealEventsRail extends StatefulWidget {
  final int partnerUserId;

  const RealEventsRail({super.key, required this.partnerUserId});

  @override
  State<RealEventsRail> createState() => _RealEventsRailState();
}

class _RealEventsRailState extends State<RealEventsRail> {
  bool _loading = true;
  List<PartnerEventShowcase> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await PartnerEventShowcaseService.list(
      partnerUserId: widget.partnerUserId,
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.celebration_outlined,
                  size: 16, color: Color(0xFF666666)),
              const SizedBox(width: 6),
              Text(
                isSw ? 'Hafla halisi' : 'Real events',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${_items.length}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _card(_items[i]),
          ),
        ),
      ],
    );
  }

  Widget _card(PartnerEventShowcase s) {
    final hero = s.photoUrls.isNotEmpty ? s.photoUrls.first : null;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: hero != null
                ? CachedMediaImage(imageUrl: hero, fit: BoxFit.cover)
                : Container(color: const Color(0xFFEEEEEE)),
          ),
          if (s.caption != null && s.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                s.caption!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF666666),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

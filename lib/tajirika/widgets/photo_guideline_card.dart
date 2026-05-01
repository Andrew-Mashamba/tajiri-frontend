import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F1 #5 + #6 — Cluster-specific photo guidelines + reference samples
/// shown above the photo upload step on partner-posting flows. Different
/// cluster, different expectations (food = "natural light, no flash",
/// mafundi = "before/after pair", etc.). Pulls real sample images via
/// SamplePhotoService when available so partners can see the target.
///
/// Mount above any photo-upload widget. Cluster is one of: `food`,
/// `mafundi`, `events`, `housing`, `travel`, `skincare`, `hair_nails`,
/// `fitness`, fallback `default`.
class PhotoGuidelineCard extends StatefulWidget {
  final String cluster;

  const PhotoGuidelineCard({super.key, required this.cluster});

  @override
  State<PhotoGuidelineCard> createState() => _PhotoGuidelineCardState();
}

class _PhotoGuidelineCardState extends State<PhotoGuidelineCard> {
  List<String> _samples = const [];

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  @override
  void didUpdateWidget(covariant PhotoGuidelineCard old) {
    super.didUpdateWidget(old);
    if (old.cluster != widget.cluster) {
      _loadSamples();
    }
  }

  Future<void> _loadSamples() async {
    if (widget.cluster.isEmpty) return;
    final urls = await SamplePhotoService.show(widget.cluster);
    if (!mounted) return;
    setState(() => _samples = urls);
  }

  static const Map<String, _Guideline> _byCluster = {
    'food': _Guideline(
      titleSw: 'Picha za vyakula',
      titleEn: 'Food photos',
      tipsSw: const [
        'Tumia mwanga wa asili — epuka flash.',
        'Picha 4+ kutoka pembe tofauti.',
        'Onyesha sehemu ya chakula iliyoiva.',
      ],
      tipsEn: const [
        'Natural light only — avoid flash.',
        'Add 4+ photos from different angles.',
        'Show the fully-cooked dish.',
      ],
    ),
    'mafundi': _Guideline(
      titleSw: 'Picha za kazi yako',
      titleEn: 'Work photos',
      tipsSw: const [
        'Picha za kabla na baada — onyesha mabadiliko.',
        'Picha 4+ za kazi tofauti.',
        'Hakikisha hakuna taarifa za faragha (jina la mteja, n.k.).',
      ],
      tipsEn: const [
        'Before/after pairs are most convincing.',
        '4+ photos across different jobs.',
        'Strip out customer info (names, addresses).',
      ],
    ),
    'events': _Guideline(
      titleSw: 'Picha za hafla',
      titleEn: 'Event photos',
      tipsSw: const [
        'Hafla 3+ ulizopita.',
        'Onyesha umati, vifaa, maandalizi.',
        'Picha za usiku zinakubalika kwa kazi za usiku.',
      ],
      tipsEn: const [
        '3+ different past events.',
        'Show crowd, equipment, setup.',
        'Night shots OK for night events.',
      ],
    ),
    'housing': _Guideline(
      titleSw: 'Picha za nyumba',
      titleEn: 'Property photos',
      tipsSw: const [
        'Mwanga wa mchana — epuka usiku.',
        'Picha 8+: chumba kila kimoja + nje.',
        'Lens pana au drone hupendekezwa kwa nyumba kubwa.',
      ],
      tipsEn: const [
        'Daytime light only.',
        '8+ photos: every room + exterior.',
        'Wide-angle or drone for large properties.',
      ],
    ),
    'travel': _Guideline(
      titleSw: 'Picha za safari',
      titleEn: 'Trip photos',
      tipsSw: const [
        'Onyesha vituo vyote vikuu vya safari.',
        'Picha za wateja wakishiriki (na ruhusa).',
        'Picha 6+ za marudio tofauti.',
      ],
      tipsEn: const [
        'Show every key stop in the itinerary.',
        'Customer-in-action shots (with consent).',
        '6+ photos across destinations.',
      ],
    ),
    'skincare': _Guideline(
      titleSw: 'Picha za bidhaa',
      titleEn: 'Product photos',
      tipsSw: const [
        'Background nyeupe au plain.',
        'Onyesha viungo / lebo wazi.',
        'Picha ya kabla/baada hupendekezwa.',
      ],
      tipsEn: const [
        'Plain or white background.',
        'Show ingredient labels clearly.',
        'Before/after comparisons are persuasive.',
      ],
    ),
    'hair_nails': _Guideline(
      titleSw: 'Picha za kazi',
      titleEn: 'Style photos',
      tipsSw: const [
        'Picha karibu na uso (close-up).',
        'Mwanga wa asili.',
        'Mtindo 4+ tofauti.',
      ],
      tipsEn: const [
        'Close-up shots of finished styles.',
        'Natural light.',
        '4+ different styles.',
      ],
    ),
    'fitness': _Guideline(
      titleSw: 'Picha za kituo',
      titleEn: 'Studio photos',
      tipsSw: const [
        'Picha za vifaa vyote vya mazoezi.',
        'Onyesha nafasi ya mteja.',
        'Picha za madarasa (kwa ruhusa ya washiriki).',
      ],
      tipsEn: const [
        'All equipment available.',
        'Show the participant area / floor plan.',
        'Class shots (with participant consent).',
      ],
    ),
    'default': _Guideline(
      titleSw: 'Picha bora',
      titleEn: 'Photo tips',
      tipsSw: const [
        'Picha 4+ za ubora.',
        'Mwanga wa asili — epuka flash.',
        'Hakikisha hakuna ukungu (blur).',
      ],
      tipsEn: const [
        '4+ high-quality photos.',
        'Natural light, no flash.',
        'Avoid blurry shots.',
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final g = _byCluster[widget.cluster] ?? _byCluster['default']!;
    final tips = isSw ? g.tipsSw : g.tipsEn;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_outlined, size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw ? g.titleSw : g.titleEn,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFFE65100))),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              )),
          if (_samples.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              isSw ? 'Mfano wa picha bora' : 'Reference samples',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _samples.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _samples[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFEEEEEE),
                      child: const Icon(Icons.broken_image_outlined,
                          color: Color(0xFF999999)),
                    ),
                    loadingBuilder: (ctx, child, p) => p == null
                        ? child
                        : Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFEEEEEE),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Guideline {
  final String titleSw;
  final String titleEn;
  final List<String> tipsSw;
  final List<String> tipsEn;

  const _Guideline({
    required this.titleSw,
    required this.titleEn,
    required this.tipsSw,
    required this.tipsEn,
  });
}

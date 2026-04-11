// lib/tafuta_kanisa/pages/church_profile_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tafuta_kanisa_models.dart';
import '../services/tafuta_kanisa_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ChurchProfilePage extends StatefulWidget {
  final int churchId;
  const ChurchProfilePage({super.key, required this.churchId});
  @override
  State<ChurchProfilePage> createState() => _ChurchProfilePageState();
}

class _ChurchProfilePageState extends State<ChurchProfilePage> {
  ChurchListing? _church;
  List<ChurchReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      TafutaKanisaService.getChurch(widget.churchId),
      TafutaKanisaService.getReviews(widget.churchId),
    ]);
    if (mounted) {
      final chR = results[0] as SingleResult<ChurchListing>;
      final revR = results[1] as PaginatedResult<ChurchReview>;
      setState(() {
        _isLoading = false;
        if (chR.success) _church = chR.data;
        if (revR.success) _reviews = revR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
        actions: [
          if (_church != null)
            IconButton(
              icon: Icon(
                _church!.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 24, color: _kPrimary,
              ),
              onPressed: () async {
                await TafutaKanisaService.toggleSaved(widget.churchId);
                if (mounted) _load();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _church == null
              ? const Center(child: Text('Kanisa halijapatikana / Church not found', style: TextStyle(color: _kSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Text(_church!.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 4),
                    Text(_church!.denomination,
                        style: const TextStyle(fontSize: 14, color: _kSecondary)),
                    const SizedBox(height: 8),

                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                              i < _church!.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 20, color: _kPrimary,
                            )),
                        const SizedBox(width: 6),
                        Text('${_church!.rating.toStringAsFixed(1)} (${_church!.reviewCount})',
                            style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info rows
                    if (_church!.address != null)
                      _InfoRow(icon: Icons.location_on_rounded, text: _church!.address!),
                    if (_church!.pastorName != null)
                      _InfoRow(icon: Icons.person_rounded, text: 'Mchungaji / Pastor: ${_church!.pastorName}'),
                    if (_church!.phone != null)
                      _InfoRow(icon: Icons.phone_rounded, text: _church!.phone!),
                    if (_church!.serviceTimes.isNotEmpty)
                      _InfoRow(icon: Icons.schedule_rounded, text: _church!.serviceTimes.join(' | ')),
                    if (_church!.languages.isNotEmpty)
                      _InfoRow(icon: Icons.language_rounded, text: _church!.languages.join(', ')),
                    if (_church!.serviceStyle != null)
                      _InfoRow(icon: Icons.music_note_rounded, text: _church!.serviceStyle!),

                    if (_church!.distanceKm != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.directions_walk_rounded,
                        text: '${_church!.distanceKm!.toStringAsFixed(1)} km kutoka hapa / from here',
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final lat = _church!.latitude;
                                final lng = _church!.longitude;
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 20),
                              label: const Text('Ramani / Map', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final phone = _church!.phone;
                                if (phone != null && phone.isNotEmpty) {
                                  launchUrl(Uri.parse('tel:$phone'));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nambari ya simu haipatikani / Phone number not available')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.phone_rounded, color: _kPrimary, size: 20),
                              label: const Text('Piga Simu / Call', style: TextStyle(color: _kPrimary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _kPrimary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reviews
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Maoni / Reviews',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                        TextButton(
                          onPressed: _showReviewDialog,
                          child: const Text('Andika / Write', style: TextStyle(color: _kPrimary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_reviews.isEmpty)
                      const Text('Hakuna maoni bado / No reviews yet',
                          style: TextStyle(color: _kSecondary, fontSize: 13))
                    else
                      ..._reviews.map((r) => _ReviewCard(review: r)),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  void _showReviewDialog() {
    int stars = 5;
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Andika Maoni / Write Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                      icon: Icon(i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                          color: _kPrimary, size: 32),
                      onPressed: () => setS(() => stars = i + 1),
                    )),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Maoni yako...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await TafutaKanisaService.submitReview(widget.churchId, {
                      'stars': stars,
                      'text': textCtrl.text.trim(),
                    });
                    if (mounted) _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tuma / Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14, color: _kPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ChurchReview review;
  const _ReviewCard({required this.review});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(review.authorName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const Spacer(),
                ...List.generate(5, (i) => Icon(
                      i < review.stars ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 14, color: _kPrimary,
                    )),
              ],
            ),
            if (review.text != null && review.text!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.text!,
                  style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(review.createdAt,
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
    );
  }
}

// lib/fundi/pages/fundi_profile_page.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/fundi_models.dart';
import '../services/fundi_service.dart';
import 'fundi_booking_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FundiProfilePage extends StatefulWidget {
  final int userId;
  final Fundi fundi;

  const FundiProfilePage({super.key, required this.userId, required this.fundi});

  @override
  State<FundiProfilePage> createState() => _FundiProfilePageState();
}

class _FundiProfilePageState extends State<FundiProfilePage> {
  final FundiService _service = FundiService();
  List<FundiReview> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final result = await _service.getFundiReviews(widget.fundi.id);
    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
        if (result.success) _reviews = result.items;
      });
    }
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  void _bookFundi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FundiBookingPage(userId: widget.userId, fundi: widget.fundi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundi = widget.fundi;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fundi.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _kPrimary.withValues(alpha: 0.08),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: fundi.photoUrl != null
                      ? CachedMediaImage(
                          imageUrl: fundi.photoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            fundi.initials,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fundi.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    if (fundi.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF4CAF50)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  fundi.services.map((s) => s.displayName).join(', '),
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  textAlign: TextAlign.center,
                ),
                if (fundi.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: _kSecondary),
                      const SizedBox(width: 2),
                      Text(fundi.location!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      label: 'Kiwango',
                      value: fundi.rating > 0 ? fundi.rating.toStringAsFixed(1) : '-',
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                    ),
                    _StatItem(
                      label: 'Kazi',
                      value: '${fundi.totalJobs}',
                      icon: Icons.work_outline,
                    ),
                    _StatItem(
                      label: 'Uzoefu',
                      value: '${fundi.experienceYears} yr',
                      icon: Icons.timeline_rounded,
                    ),
                    if (fundi.hourlyRate != null)
                      _StatItem(
                        label: 'Kwa Saa',
                        value: 'TZS ${_fmtPrice(fundi.hourlyRate!)}',
                        icon: Icons.payments_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bio
          if (fundi.bio != null && fundi.bio!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kuhusu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 6),
                  Text(fundi.bio!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Portfolio photos
          if (fundi.portfolioPhotos.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kazi Zangu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: fundi.portfolioPhotos.map((url) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: _kPrimary.withValues(alpha: 0.08),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedMediaImage(
                                imageUrl: url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Reviews
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maoni (${fundi.totalReviews})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                const SizedBox(height: 10),
                if (_isLoadingReviews)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                else if (_reviews.isEmpty)
                  Text('Hakuna maoni bado', style: TextStyle(fontSize: 13, color: Colors.grey.shade400))
                else
                  ..._reviews.take(5).map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (review.userName != null)
                                  Text(
                                    review.userName!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
                                  ),
                              ],
                            ),
                            if (review.comment != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                review.comment!,
                                style: const TextStyle(fontSize: 12, color: _kSecondary),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Book button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: fundi.isAvailable ? _bookFundi : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                fundi.isAvailable ? 'Agiza Fundi' : 'Hapatikani kwa sasa',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor ?? _kSecondary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
      ],
    );
  }
}

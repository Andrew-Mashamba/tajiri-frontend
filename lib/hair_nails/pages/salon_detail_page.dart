// lib/hair_nails/pages/salon_detail_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';
import 'booking_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SalonDetailPage extends StatefulWidget {
  final int userId;
  final Salon salon;
  const SalonDetailPage({super.key, required this.userId, required this.salon});
  @override
  State<SalonDetailPage> createState() => _SalonDetailPageState();
}

class _SalonDetailPageState extends State<SalonDetailPage> {
  final HairNailsService _service = HairNailsService();
  List<SalonReview> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final result = await _service.getSalonReviews(widget.salon.id);
    if (mounted) {
      setState(() {
        _loadingReviews = false;
        if (result.success) _reviews = result.items;
      });
    }
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // Header image
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: _kPrimary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: salon.imageUrl != null
                    ? Image.network(salon.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _kPrimary.withValues(alpha: 0.1)))
                    : Container(
                        color: _kPrimary.withValues(alpha: 0.08),
                        child: const Center(child: Icon(Icons.content_cut_rounded, size: 60, color: _kSecondary)),
                      ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(salon.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ),
                        if (salon.isVerified) const Icon(Icons.verified_rounded, size: 22, color: _kPrimary),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (salon.isHomeBased) _badge('Mama Salon', Icons.home_rounded),
                        if (salon.isMobile) _badge('Mtaalamu Anakuja', Icons.directions_walk_rounded),
                        if (salon.isWalkIn) _badge('Walk-in', Icons.door_front_door_outlined),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rating + reviews
                    Row(
                      children: [
                        if (salon.rating > 0) ...[
                          ...List.generate(5, (i) => Icon(
                                i < salon.rating.floor() ? Icons.star_rounded : (i < salon.rating ? Icons.star_half_rounded : Icons.star_border_rounded),
                                size: 18,
                                color: Colors.amber,
                              )),
                          const SizedBox(width: 6),
                          Text('${salon.rating.toStringAsFixed(1)} (${salon.totalReviews} tathmini)', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Address
                    if (salon.address != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: _kSecondary),
                          const SizedBox(width: 4),
                          Expanded(child: Text(salon.address!, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),

                    // Phone
                    if (salon.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: _kSecondary),
                          const SizedBox(width: 4),
                          Text(salon.phone!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                    ],

                    // Opening hours
                    if (salon.openingHours != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: _kSecondary),
                          const SizedBox(width: 4),
                          Text(salon.openingHours!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                    ],

                    // Description
                    if (salon.description != null) ...[
                      const SizedBox(height: 12),
                      Text(salon.description!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4)),
                    ],
                    const SizedBox(height: 20),

                    // Photo portfolio
                    if (salon.photos.isNotEmpty) ...[
                      const Text('Picha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: salon.photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(salon.photos[i], width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: _kPrimary.withValues(alpha: 0.06))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Service menu
                    const Text('Huduma na Bei', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 10),
                    if (salon.services.isEmpty)
                      const Text('Hakuna huduma zilizoorodheshwa', style: TextStyle(fontSize: 13, color: _kSecondary))
                    else
                      ...salon.services.map((s) => _serviceItem(s)),
                    const SizedBox(height: 20),

                    // Staff
                    if (salon.staff.isNotEmpty) ...[
                      const Text('Wafanyakazi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: salon.staff.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final staff = salon.staff[i];
                            return Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                                  backgroundImage: staff.photoUrl != null ? NetworkImage(staff.photoUrl!) : null,
                                  child: staff.photoUrl == null ? const Icon(Icons.person_rounded, color: _kSecondary) : null,
                                ),
                                const SizedBox(height: 4),
                                Text(staff.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (staff.specialty != null)
                                  Text(staff.specialty!, style: const TextStyle(fontSize: 9, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Reviews
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tathmini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                        Text('${salon.totalReviews}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loadingReviews)
                      const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                    else if (_reviews.isEmpty)
                      const Text('Bado hakuna tathmini', style: TextStyle(fontSize: 13, color: _kSecondary))
                    else
                      ..._reviews.take(5).map((r) => _reviewItem(r)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Book button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(userId: widget.userId, salon: salon)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Weka Miadi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kPrimary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _serviceItem(SalonService service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(userId: widget.userId, salon: widget.salon, preselectedService: service)));
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                  child: Icon(
                    service.category == ServiceCategory.hair ? Icons.content_cut_rounded : service.category == ServiceCategory.nails ? Icons.back_hand_rounded : Icons.face_rounded,
                    size: 18,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (service.description != null)
                        Text(service.description!, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${service.durationMinutes} dakika', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                    ],
                  ),
                ),
                Text('TZS ${_fmtPrice(service.price)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewItem(SalonReview review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  backgroundImage: review.userPhotoUrl != null ? NetworkImage(review.userPhotoUrl!) : null,
                  child: review.userPhotoUrl == null ? const Icon(Icons.person_rounded, size: 14, color: _kSecondary) : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(review.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ...List.generate(5, (i) => Icon(i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 12, color: Colors.amber)),
              ],
            ),
            if (review.comment != null) ...[
              const SizedBox(height: 6),
              Text(review.comment!, style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

// lib/service_garage/pages/garage_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/service_garage_models.dart';
import '../services/service_garage_service.dart';
import 'book_service_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GarageDetailPage extends StatefulWidget {
  final Garage garage;
  const GarageDetailPage({super.key, required this.garage});
  @override
  State<GarageDetailPage> createState() => _GarageDetailPageState();
}

class _GarageDetailPageState extends State<GarageDetailPage> {
  late Garage _garage;
  List<GarageReview> _reviews = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _garage = widget.garage;
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final r = await ServiceGarageService.getGarageReviews(_garage.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _reviews = r.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_garage.name,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _garage.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(_garage.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.build_rounded,
                                  size: 28,
                                  color: _kPrimary)))
                      : const Icon(Icons.build_rounded,
                          size: 28, color: _kPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(_garage.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (_garage.isVerified)
                            const Icon(Icons.verified_rounded,
                                size: 18, color: Color(0xFF4CAF50)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                              '${_garage.rating.toStringAsFixed(1)} (${_garage.reviewCount})',
                              style: const TextStyle(
                                  fontSize: 12, color: _kSecondary)),
                          if (_garage.distanceKm != null) ...[
                            const SizedBox(width: 8),
                            Text(
                                '${_garage.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary)),
                          ],
                        ]),
                      ]),
                ),
              ]),
              if (_garage.address != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_garage.address!,
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
              if (_garage.operatingHours != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(_garage.operatingHours!,
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // Badges
          Row(children: [
            if (_garage.acceptsInsurance)
              _badge(Icons.shield_rounded,
                  _isSwahili ? 'Bima' : 'Insurance'),
            if (_garage.hasMobileService)
              _badge(Icons.directions_car_rounded,
                  _isSwahili ? 'Huduma ya Simu' : 'Mobile'),
          ]),
          const SizedBox(height: 16),

          // Services
          if (_garage.services.isNotEmpty) ...[
            Text(_isSwahili ? 'Huduma' : 'Services',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _garage.services.map((s) => _tag(s)).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Specializations
          if (_garage.specializations.isNotEmpty) ...[
            Text(_isSwahili ? 'Utaalamu' : 'Specializations',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  _garage.specializations.map((s) => _tag(s)).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Book button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          BookServicePage(garage: _garage))),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(_isSwahili ? 'Weka Miadi' : 'Book Service'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Reviews
          Text(
              '${_isSwahili ? 'Maoni' : 'Reviews'} (${_reviews.length})',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
          else if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                    _isSwahili ? 'Hakuna maoni bado' : 'No reviews yet',
                    style: const TextStyle(
                        fontSize: 13, color: _kSecondary)),
              ),
            )
          else
            ..._reviews.take(10).map(_reviewTile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _reviewTile(GarageReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage: r.userPhotoUrl != null
                ? NetworkImage(r.userPhotoUrl!)
                : null,
            child: r.userPhotoUrl == null
                ? Text(r.userName.isNotEmpty ? r.userName[0] : '?',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(r.userName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Row(
            children: List.generate(
                5,
                (i) => Icon(
                    i < r.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: Colors.amber)),
          ),
        ]),
        if (r.comment != null) ...[
          const SizedBox(height: 6),
          Text(r.comment!,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}

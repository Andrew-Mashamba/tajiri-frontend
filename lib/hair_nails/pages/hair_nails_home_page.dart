// lib/hair_nails/pages/hair_nails_home_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';
import '../widgets/salon_card.dart';
import '../widgets/style_card.dart';
import '../widgets/booking_card.dart';
import 'hair_profile_page.dart';
import 'salon_browse_page.dart';
import 'salon_detail_page.dart';
import 'style_gallery_page.dart';
import 'growth_tracker_page.dart';
import 'my_bookings_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class HairNailsHomePage extends StatefulWidget {
  final int userId;
  const HairNailsHomePage({super.key, required this.userId});
  @override
  State<HairNailsHomePage> createState() => _HairNailsHomePageState();
}

class _HairNailsHomePageState extends State<HairNailsHomePage> {
  final HairNailsService _service = HairNailsService();

  HairProfile? _profile;
  List<Booking> _upcomingBookings = [];
  List<StyleInspiration> _trendingStyles = [];
  List<Salon> _nearbySalons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getHairProfile(widget.userId),
      _service.getMyBookings(widget.userId),
      _service.getStyleGallery(page: 1),
      _service.findSalons(page: 1),
    ]);
    if (mounted) {
      final profileResult = results[0] as HairNailsResult<HairProfile>;
      final bookingsResult = results[1] as HairNailsListResult<Booking>;
      final stylesResult = results[2] as HairNailsListResult<StyleInspiration>;
      final salonsResult = results[3] as HairNailsListResult<Salon>;
      setState(() {
        _isLoading = false;
        _profile = profileResult.success ? profileResult.data : null;
        if (bookingsResult.success) {
          _upcomingBookings = bookingsResult.items.where((b) => b.isUpcoming).take(3).toList();
        }
        if (stylesResult.success) _trendingStyles = stylesResult.items.take(6).toList();
        if (salonsResult.success) _nearbySalons = salonsResult.items.take(4).toList();
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Hair Profile Card
          _buildProfileCard(),
          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(child: _QuickAction(icon: Icons.content_cut_rounded, label: 'Find Salon', onTap: () => _nav(SalonBrowsePage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.auto_awesome_rounded, label: 'Styles', onTap: () => _nav(StyleGalleryPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.trending_up_rounded, label: 'Growth', onTap: () => _nav(GrowthTrackerPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.calendar_today_rounded, label: 'Bookings', onTap: () => _nav(MyBookingsPage(userId: widget.userId)))),
            ],
          ),
          const SizedBox(height: 20),

          // Upcoming Bookings
          if (_upcomingBookings.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => _nav(MyBookingsPage(userId: widget.userId)),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._upcomingBookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingCard(booking: b, onTap: () => _nav(MyBookingsPage(userId: widget.userId))),
                )),
            const SizedBox(height: 16),
          ],

          // Traction Alopecia Awareness
          _buildAlopeciaCard(),
          const SizedBox(height: 16),

          // Trending Styles
          if (_trendingStyles.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trending Styles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => _nav(StyleGalleryPage(userId: widget.userId)),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingStyles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final style = _trendingStyles[i];
                  return SizedBox(
                    width: 150,
                    child: StyleCard(
                      style: style,
                      onTap: () => _showStyleDetail(style),
                      onSave: () => _service.saveStyle(userId: widget.userId, styleId: style.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Nearby Salons
          if (_nearbySalons.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nearby Salons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => _nav(SalonBrowsePage(userId: widget.userId)),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._nearbySalons.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SalonCard(salon: s, onTap: () => _nav(SalonDetailPage(userId: widget.userId, salon: s))),
                )),
          ],

          // Link to Doctor
          const SizedBox(height: 8),
          Material(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/doctor'),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.medical_services_rounded, color: _kPrimary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scalp Problem?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                          Text('Contact a dermatologist', style: TextStyle(fontSize: 12, color: _kSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _kSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null) {
      return Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _nav(HairProfilePage(userId: widget.userId)),
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.face_rounded, size: 40, color: _kPrimary),
                SizedBox(height: 10),
                Text('Create Hair Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                SizedBox(height: 4),
                Text('Know your hair type and get tailored advice', style: TextStyle(fontSize: 12, color: _kSecondary), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _nav(HairProfilePage(userId: widget.userId, existingProfile: _profile)),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Icon(_profile!.hairType.icon, size: 24, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Hair: ${_profile!.hairType.displayName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        Text('${_profile!.currentState.displayName} \u00b7 ${_profile!.porosity.displayName}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_rounded, size: 18, color: _kSecondary),
                ],
              ),
              if (_profile!.goals.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _profile!.goals.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                        child: Text(g, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kPrimary)),
                      )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlopeciaCard() {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Traction Alopecia — Protect Your Hair', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Tight braids, heavy weaves, and overly pulled cornrows can cause hair breakage and permanent loss. '
              'Early signs: scalp pain, hair thinning along the hairline.',
              style: TextStyle(fontSize: 12, color: _kSecondary, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Advice:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              '\u2022 Avoid tight and heavy styles for long periods\n'
              '\u2022 Change your hairstyle every 2-3 weeks\n'
              '\u2022 Let your hair rest between styles\n'
              '\u2022 Use edge control sparingly\n'
              '\u2022 If your hairline is receding, please see a doctor',
              style: TextStyle(fontSize: 12, color: _kSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showStyleDetail(StyleInspiration style) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            if (style.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(style.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            const SizedBox(height: 12),
            Text(style.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 6),
            if (style.description != null)
              Text(style.description!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (style.estimatedPrice != null) ...[
                  const Icon(Icons.payments_outlined, size: 16, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text('TZS ${_fmtPrice(style.estimatedPrice!)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(width: 16),
                ],
                if (style.estimatedDurationMinutes != null) ...[
                  const Icon(Icons.access_time_rounded, size: 16, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(style.durationLabel, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                ],
              ],
            ),
            if (style.hairTypeRecommended.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: style.hairTypeRecommended.map((h) => Chip(
                      label: Text(h.shortLabel, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _kPrimary.withValues(alpha: 0.06),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _nav(SalonBrowsePage(userId: widget.userId));
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Find a Salon for This Style', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

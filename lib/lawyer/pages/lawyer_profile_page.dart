// lib/lawyer/pages/lawyer_profile_page.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/lawyer_models.dart';
import '../services/lawyer_service.dart';
import 'book_consultation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LawyerProfilePage extends StatefulWidget {
  final int userId;
  final Lawyer lawyer;
  const LawyerProfilePage({super.key, required this.userId, required this.lawyer});
  @override
  State<LawyerProfilePage> createState() => _LawyerProfilePageState();
}

class _LawyerProfilePageState extends State<LawyerProfilePage> {
  final LawyerService _service = LawyerService();
  List<LawyerReview> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final result = await _service.getLawyerReviews(widget.lawyer.id);
    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
        if (result.success) _reviews = result.items;
      });
    }
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final law = widget.lawyer;
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _kPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: _kPrimary),
                  Positioned(
                    left: 20, bottom: 20, right: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: law.profilePhotoUrl != null
                              ? CachedMediaImage(imageUrl: law.profilePhotoUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: Center(
                                    child: Text(law.initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Wkl. ${law.fullName}',
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (law.isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.verified_rounded, color: Color(0xFF4CAF50), size: 20),
                                    ),
                                ],
                              ),
                              Text(law.specialty.displayName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              if (law.firm != null)
                                Text(law.firm!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatCard(value: law.rating.toStringAsFixed(1), label: 'Ukadiriaji', icon: Icons.star_rounded),
                      const SizedBox(width: 10),
                      _StatCard(value: '${law.totalConsultations}', label: 'Mashauriano', icon: Icons.chat_rounded),
                      const SizedBox(width: 10),
                      _StatCard(value: '${law.experienceYears}', label: 'Miaka', icon: Icons.work_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bar Council badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 20, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amethibitishwa na Baraza la Mawakili', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                              Text('Nambari: ${law.barNumber}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  if (law.bio != null && law.bio!.isNotEmpty) ...[
                    const Text('Kuhusu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 8),
                    Text(law.bio!, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        if (law.location != null) _InfoRow(icon: Icons.location_on_outlined, text: law.location!),
                        if (law.firm != null) _InfoRow(icon: Icons.business_rounded, text: law.firm!),
                        _InfoRow(icon: Icons.translate_rounded, text: law.languages.join(', ')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Consultation types + fee
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Huduma', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (law.acceptsVideo) _ServiceBadge(icon: Icons.videocam_rounded, label: 'Video'),
                            if (law.acceptsAudio) _ServiceBadge(icon: Icons.phone_rounded, label: 'Simu'),
                            if (law.acceptsChat) _ServiceBadge(icon: Icons.chat_rounded, label: 'Ujumbe'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ada ya Mashauriano', style: TextStyle(fontSize: 14, color: _kSecondary)),
                            Text('TZS ${_fmt(law.consultationFee)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews
                  Text('Maoni (${_reviews.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 10),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                  else if (_reviews.isEmpty)
                    Text('Hakuna maoni bado', style: TextStyle(color: Colors.grey.shade500))
                  else
                    ..._reviews.take(5).map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: i < r.rating.round() ? Colors.amber : Colors.grey.shade300,
                                      )),
                                  const Spacer(),
                                  Text(
                                    '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                                  ),
                                ],
                              ),
                              if (r.comment != null) ...[
                                const SizedBox(height: 6),
                                Text(r.comment!, style: const TextStyle(fontSize: 13, color: _kPrimary)),
                              ],
                            ],
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookConsultationPage(userId: widget.userId, lawyer: law),
              ),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: Text('Weka Miadi — TZS ${_fmt(law.consultationFee)}'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: _kPrimary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _kPrimary))),
        ],
      ),
    );
  }
}

class _ServiceBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ServiceBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ],
      ),
    );
  }
}

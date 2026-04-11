// lib/fitness/pages/gym_detail_page.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';
import '../widgets/class_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class GymDetailPage extends StatefulWidget {
  final int userId;
  final Gym gym;
  const GymDetailPage({super.key, required this.userId, required this.gym});
  @override
  State<GymDetailPage> createState() => _GymDetailPageState();
}

class _GymDetailPageState extends State<GymDetailPage> {
  final FitnessService _service = FitnessService();
  List<FitnessClass> _classes = [];
  bool _isLoadingClasses = true;

  @override
  void initState() { super.initState(); _loadClasses(); }

  Future<void> _loadClasses() async {
    final result = await _service.getClasses(gymId: widget.gym.id);
    if (mounted) setState(() { _isLoadingClasses = false; if (result.success) _classes = result.items; });
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) { if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(','); buffer.write(parts[i]); }
    return buffer.toString();
  }

  void _subscribe(String frequency) async {
    final phoneController = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Jisajili ${frequency == 'monthly' ? 'kwa Mwezi' : 'kwa Mwaka'}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Bei: TZS ${_fmt(frequency == 'monthly' ? widget.gym.monthlyPrice : (widget.gym.yearlyPrice ?? widget.gym.monthlyPrice * 10))}'),
          const SizedBox(height: 12),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Nambari ya M-Pesa', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, phoneController.text.trim()), style: FilledButton.styleFrom(backgroundColor: _kPrimary), child: const Text('Lipa')),
        ],
      ),
    );
    if (phone != null && phone.isNotEmpty && mounted) {
      final result = await _service.subscribe(userId: widget.userId, gymId: widget.gym.id, frequency: frequency, paymentMethod: 'mobile_money', phoneNumber: phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.success ? 'Umejisajili! Thibitisha kwenye simu.' : (result.message ?? 'Imeshindwa'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gym;
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true, backgroundColor: _kPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: g.imageUrl != null
                  ? CachedMediaImage(imageUrl: g.imageUrl!, fit: BoxFit.cover)
                  : Container(color: _kPrimary.withValues(alpha: 0.8), child: const Center(child: Icon(Icons.fitness_center_rounded, size: 48, color: Colors.white54))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(children: [
                    Expanded(child: Text(g.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary))),
                    if (g.hasLiveStreaming)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.live_tv_rounded, size: 14, color: Colors.red), SizedBox(width: 4), Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red))]),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    if (g.rating > 0) ...[const Icon(Icons.star_rounded, size: 16, color: Colors.amber), Text(' ${g.rating.toStringAsFixed(1)} (${g.totalReviews})', style: const TextStyle(fontSize: 13, color: _kPrimary)), const SizedBox(width: 14)],
                    Icon(Icons.people_outline, size: 16, color: _kSecondary), Text(' ${g.memberCount} wanachama', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  ]),
                  if (g.address != null) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: _kSecondary), const SizedBox(width: 6), Expanded(child: Text(g.address!, style: const TextStyle(fontSize: 13, color: _kPrimary)))])],
                  if (g.openingHours != null) ...[const SizedBox(height: 6), Row(children: [const Icon(Icons.schedule_rounded, size: 16, color: _kSecondary), const SizedBox(width: 6), Text(g.openingHours!, style: const TextStyle(fontSize: 13, color: _kSecondary))])],
                  if (g.description != null) ...[const SizedBox(height: 12), Text(g.description!, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5))],
                  const SizedBox(height: 16),

                  // Facilities
                  if (g.facilities.isNotEmpty) ...[
                    const Text('Vifaa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: g.facilities.map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                          child: Text(f, style: const TextStyle(fontSize: 12, color: _kPrimary)),
                        )).toList()),
                    const SizedBox(height: 16),
                  ],

                  // Pricing + Subscribe
                  const Text('Bei', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _PriceOption(label: 'Kwa Mwezi', price: 'TZS ${_fmt(g.monthlyPrice)}', onTap: () => _subscribe('monthly')),
                    ),
                    if (g.yearlyPrice != null) ...[
                      const SizedBox(width: 10),
                      Expanded(child: _PriceOption(label: 'Kwa Mwaka', price: 'TZS ${_fmt(g.yearlyPrice!)}', badge: 'Okoa', onTap: () => _subscribe('yearly'))),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // Trainers
                  if (g.trainers.isNotEmpty) ...[
                    const Text('Makocha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView(scrollDirection: Axis.horizontal, children: g.trainers.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Column(children: [
                              CircleAvatar(radius: 24, backgroundImage: t.photoUrl != null ? NetworkImage(t.photoUrl!) : null, child: t.photoUrl == null ? Text(t.name[0], style: const TextStyle(fontWeight: FontWeight.w600)) : null),
                              const SizedBox(height: 4),
                              Text(t.name.split(' ').first, style: const TextStyle(fontSize: 11, color: _kPrimary), maxLines: 1),
                            ]),
                          )).toList()),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Classes
                  const Text('Madarasa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 8),
                  if (_isLoadingClasses)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
                  else if (_classes.isEmpty)
                    Text('Hakuna madarasa kwa sasa', style: TextStyle(color: Colors.grey.shade500))
                  else
                    ..._classes.take(10).map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ClassCard(fitnessClass: c))),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  final String label;
  final String price;
  final String? badge;
  final VoidCallback onTap;
  const _PriceOption({required this.label, required this.price, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPrimary, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(children: [
            if (badge != null) Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(6)),
              child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            Text(price, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
